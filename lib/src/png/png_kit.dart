// High-level Dart wrapper around the PNG C glue (see `part 'bindings.dart';`).
// Only uses symbols exported as `ik_png_*`.
//
// What’s exposed (API parity with TurboJpeg):
//   - class PngKit implements ImageCodec with:
//       * versionString() -> String
//       * getHeader(pngBytes) -> Header(width,height,subsampling,colorspace)
//       * decode(pngBytes, pixelFormat, flags) -> Uint8List (tight buffer)
//       * encode(pixels, w, h, pixelFormat, subsampling, quality, flags, pitchBytes)
//       * transform(pngBytes, op, options, cropX/Y/W/H, flags) -> Uint8List
//
// Notes specific to PNG:
//   - `subsampling` is ignored (PNG is lossless RGB(A)/Gray). We keep the param for API parity.
//   - `quality` maps to zlib compression level 0..9 (0=store/fast, 9=smallest/slow).
//   - `flags` are currently a no-op for PNG but kept for symmetry with JPEG.
//   - All C `char*` error buffers are passed/owned by Dart; we read them as UTF-8.
//   - Returned PNG buffers are copied into Dart and freed via `ik_png_free()`.
//
// Supported PixelFormat here: rgb, bgr, rgbx, bgrx, xbgr, xrgb, gray, rgba, bgra, abgr, argb.
// CMYK is not supported and will yield an error from the native glue.
//
// Errors throw `PngException(code, message)`.
//
// Thread-safety:
//   - The wrapper is stateless; calls allocate temporary buffers per request.
//   - Safe to call concurrently from multiple isolates as long as the underlying libpng is
//     linked/used in a thread-safe manner (our glue uses per-call state).

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as cstr;
import 'package:imagekit_ffi/src/core/ffi_utils.dart';
import 'package:imagekit_ffi/src/core/imagekit_core.dart';

part 'bindings.dart';

/// Static, stateless PNG codec.
///
/// Responsibilities:
/// - Report libpng version via [versionString].
/// - Read width/height from the PNG header via [getHeader].
/// - Decode PNG bytes to a tightly-packed pixel buffer via [decode].
/// - Encode a pixel buffer to PNG bytes via [encode].
/// - Apply simple pixel-domain transforms (rotate/flip/crop) via [transform].
final class PngKit extends ImageCodec with FfiHelpers {
  /// Size (bytes) of temporary native error buffers (includes trailing NUL).
  /// Increase if you see truncated messages.
  @override
  int get errCap => 256;

  /// Returns the human-readable libpng version (e.g. `"1.6.43"`), or `"unknown"` if the call fails.
  @override
  String versionString() {
    final buf = allocBuf();
    try {
      final rc = _ik_png_version_str(buf, errCap);
      if (rc != 0) return 'unknown';
      return readCString(buf);
    } finally {
      freeAll([buf]);
    }
  }

  /// Parses the PNG header and returns basic metadata.
  ///
  /// This does **not** decode pixel data. For PNG we return:
  /// - [Header.width], [Header.height] from IHDR
  /// - [Header.subsampling] forced to `Subsampling.s444` (API parity)
  /// - [Header.colorspace] set to `0` (placeholder)
  @override
  Header getHeader(Uint8List pngBytes) {
    final png = copyToNative(pngBytes);
    final w = cstr.calloc<ffi.Int32>(), h = cstr.calloc<ffi.Int32>();
    final err = allocBuf();
    try {
      final rc = _ik_png_get_info(png, pngBytes.length, w, h, err, errCap);
      if (rc != 0) throw PngException(rc, readCString(err));
      return Header(
        width: w.value,
        height: h.value,
        subsampling: Subsampling.s444, // PNG has no chroma subsampling
        colorspace: 0,
      );
    } finally {
      freeAll([png, w, h, err]);
    }
  }

  /// Decodes a PNG into a tightly-packed buffer in the requested [pixelFormat].
  ///
  /// The result length is `width * height * pixelFormat.bytesPerPixel`.
  /// [flags] is currently ignored (kept for interface parity with JPEG).
  @override
  Uint8List decode(
    Uint8List pngBytes, {
    PixelFormat pixelFormat = PixelFormat.rgba,
    int flags = Flags.none, // kept for symmetry, ignored
  }) {
    final header = getHeader(pngBytes);
    final outLen = header.width * header.height * pixelFormat.bytesPerPixel;

    final png = copyToNative(pngBytes);
    final out = cstr.calloc<ffi.Uint8>(outLen);
    final err = allocBuf();

    try {
      final rc = _ik_png_decode_to_pixels(
        png,
        pngBytes.length,
        out,
        0, // tight pitch
        header.width,
        header.height,
        pixelFormat.value,
        err,
        errCap,
      );
      if (rc != 0) throw PngException(rc, readCString(err));
      return Uint8List.fromList(out.asTypedList(outLen));
    } finally {
      freeAll([png, out, err]);
    }
  }

  /// Encodes a raw pixel buffer to PNG bytes.
  ///
  /// Parameters:
  /// - [pixelFormat]: one of the supported formats (e.g. RGBA, RGB).
  /// - [subsampling]: ignored (PNG does not subsample chroma).
  /// - [quality] (1..100): mapped to zlib compression level 0..9
  ///   (0=fastest/larger, 9=slowest/smaller).
  /// - [pitchBytes]: row stride in bytes; defaults to `width * bpp`.
  /// - [flags]: reserved for future use.
  ///
  /// Throws [ArgumentError] if the input pixel buffer is too small.
  @override
  Uint8List encode(
    Uint8List pixels,
    int width,
    int height, {
    PixelFormat pixelFormat = PixelFormat.rgba,
    // keep parity with JPEG, even if PNG ignores some:
    Subsampling subsampling = Subsampling.s444, // NO-OP for PNG
    int quality = 90, // maps to zlib level (0..9)
    int flags = Flags.none,
    int? pitchBytes,
  }) {
    // Map JPEG-like quality (1..100) to zlib compression level (0..9).
    // Intuition: higher quality => spend more effort => smaller file => higher level.
    int compressionLevel;
    if (quality <= 0) {
      compressionLevel = 0;
    } else if (quality >= 100) {
      compressionLevel = 9;
    } else {
      compressionLevel = ((quality * 9) / 100).round();
    }

    // Reasonable defaults; can be exposed later if needed.
    const int pngAllFilters = 0x1F; // PNG_ALL_FILTERS
    const int interlaceNone = 0; // non-interlaced

    final pitch = pitchBytes ?? width * pixelFormat.bytesPerPixel;
    final required = pitch * height;
    if (pixels.length < required) {
      throw ArgumentError(
        'Pixel buffer too small: have=${pixels.length}, need=$required '
        'for $width×$height, pitch=$pitch, bpp=${pixelFormat.bytesPerPixel}',
      );
    }

    final inPtr = copyToNative(pixels, len: required);
    final outPtr = cstr.calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = cstr.calloc<ffi.Int64>();
    final err = allocBuf();

    try {
      final rc = _ik_png_encode_from_pixels_ex(
        inPtr,
        width,
        pitch,
        height,
        pixelFormat.value,
        compressionLevel,
        pngAllFilters,
        interlaceNone,
        outPtr,
        outLen,
        err,
        errCap,
      );
      if (rc != 0) throw PngException(rc, readCString(err));

      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw PngException(-999, 'Native encoder returned null buffer');
      }
      final copy = Uint8List.fromList(nativeBuf.asTypedList(outLen.value));
      _ik_png_free(nativeBuf);
      return copy;
    } finally {
      freeAll([inPtr, outPtr, outLen, err]);
    }
  }

  /// Applies simple pixel-domain transforms to a PNG and returns a new PNG.
  ///
  /// Supported operations: rotate, flip (H/V), transpose, transverse, crop.
  /// [options] accepts the same bitmask as other codecs for API uniformity;
  /// only semantically relevant bits (e.g. `XformOptions.crop`) affect behavior.
  /// [flags] is reserved for future use.
  @override
  Uint8List transform(
    Uint8List pngBytes, {
    TransformOp op = TransformOp.none,
    int options = XformOptions.none,
    int cropX = 0,
    int cropY = 0,
    int cropW = 0,
    int cropH = 0,
    int flags = Flags.none, // ignored
  }) {
    final inPtr = copyToNative(pngBytes);
    final outPtr = cstr.calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = cstr.calloc<ffi.Int64>();
    final err = allocBuf();

    try {
      final rc = _ik_png_transform_simple(
        inPtr,
        pngBytes.length,
        op.value,
        options,
        cropX,
        cropY,
        cropW,
        cropH,
        outPtr,
        outLen,
        flags,
        err,
        errCap,
      );
      if (rc != 0) throw PngException(rc, readCString(err));
      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw PngException(-999, 'Transform returned null buffer');
      }
      final bytes = nativeBuf.asTypedList(outLen.value);
      final copy = Uint8List.fromList(bytes);
      _ik_png_free(nativeBuf);
      return copy;
    } finally {
      freeAll([inPtr, outPtr, outLen, err]);
    }
  }
}
