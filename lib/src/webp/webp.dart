// High-level Dart wrapper around the WebP C glue (see `part 'bindings.dart';`).
// Only uses symbols exported as `ik_webp_*`.
//
// Exposed API (parity with other codecs):
//   - class WebpKit implements ImageCodec with:
//       * versionString() -> String
//       * getHeader(bytes) -> Header(width,height,subsampling,colorspace)
//       * decode(bytes, pixelFormat, flags) -> Uint8List (tight buffer)
//       * encode(pixels, w, h, pixelFormat, subsampling, quality, flags, pitchBytes)
//       * transform(webpBytes, op, options, cropX/Y/W/H, flags) -> Uint8List
//
// Notes:
//   - Lossy WebP only supports chroma subsampling 4:2:0. We coerce s422 to s420.
//   - To emulate 4:4:4 (no subsampling), we switch to lossless/near-lossless.
//   - `flags` currently unused but kept for API symmetry.
//   - Returned buffers are copied into Dart and freed via `ik_webp_free()`.
//
// Errors throw `ImageKitException(code, message)`.

import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as cstr;
import 'package:imagekit_ffi/src/core/ffi_utils.dart';
import 'package:imagekit_ffi/src/core/imagekit_core.dart';

part 'bindings.dart';

final class WebpKit extends ImageCodec with FfiHelpers {
  @override
  int get errCap => 256;

  @override
  String versionString() {
    final buf = allocBuf();
    try {
      final rc = _ik_webp_version_str(buf, errCap);
      if (rc != 0) return 'unknown';
      return readCString(buf);
    } finally {
      freeAll([buf]);
    }
  }

  @override
  Header getHeader(Uint8List bytes) {
    final p = copyToNative(bytes);
    final w = cstr.calloc<ffi.Int32>(), h = cstr.calloc<ffi.Int32>();
    final err = allocBuf();
    try {
      final rc = _ik_webp_get_info(p, bytes.length, w, h, err, errCap);
      if (rc != 0) throw ImageKitException(rc, readCString(err));
      // subsampling/colorspace are not exposed by WebP header API;
      // we keep placeholders for API parity.
      return Header(
        width: w.value,
        height: h.value,
        subsampling: Subsampling.s422, // best guess for lossy
        colorspace: 0,
      );
    } finally {
      freeAll([p, w, h, err]);
    }
  }

  @override
  Uint8List decode(Uint8List bytes, {PixelFormat pixelFormat = PixelFormat.rgba, int flags = 0}) {
    final hdr = getHeader(bytes);
    final outLen = hdr.width * hdr.height * pixelFormat.bytesPerPixel;

    final inp = copyToNative(bytes);
    final out = cstr.calloc<ffi.Uint8>(outLen);
    final err = allocBuf();

    try {
      final rc = _ik_webp_decode_to_pixels(
        inp,
        bytes.length,
        out,
        0, // tight pitch
        hdr.width,
        hdr.height,
        pixelFormat.value,
        err,
        errCap,
      );
      if (rc != 0) throw ImageKitException(rc, readCString(err));
      return Uint8List.fromList(out.asTypedList(outLen));
    } finally {
      freeAll([inp, out, err]);
    }
  }

  @override
  Uint8List encode(
    Uint8List pixels,
    int width,
    int height, {
    PixelFormat pixelFormat = PixelFormat.rgba,
    Subsampling subsampling = Subsampling.y420,
    int quality = 90, // 0..100
    int flags = 0,
    int? pitchBytes,
  }) {
    if (quality < 0 || quality > 100) {
      throw ArgumentError.value(quality, 'quality', 'Expected 0..100');
    }

    // lossy WebP supports only 4:2:0 — coerce s422 -> s420.
    if (subsampling == Subsampling.s422) {
      subsampling = Subsampling.y420;
    }

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
      final rc = _ik_webp_encode_from_pixels_ex(
        inPtr,
        width,
        pitch,
        height,
        pixelFormat.value,
        subsampling.value, // s444 => lossless/near-lossless in C-shim
        quality,
        outPtr,
        outLen,
        err,
        errCap,
      );
      if (rc != 0) throw ImageKitException(rc, readCString(err));

      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw ImageKitException(-999, 'Native encoder returned null buffer');
      }
      final bytes = nativeBuf.asTypedList(outLen.value);
      final copy = Uint8List.fromList(bytes);
      _ik_webp_free(nativeBuf);
      return copy;
    } finally {
      freeAll([inPtr, outPtr, outLen, err]);
    }
  }

  @override
  Uint8List transform(
    Uint8List webpBytes, {
    TransformOp op = TransformOp.none,
    int options = XformOptions.none,
    int cropX = 0,
    int cropY = 0,
    int cropW = 0,
    int cropH = 0,
    int flags = 0,
  }) {
    final inPtr = copyToNative(webpBytes);
    final outPtr = cstr.calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = cstr.calloc<ffi.Int64>();
    final err = allocBuf();

    try {
      final rc = _ik_webp_transform_simple(
        inPtr,
        webpBytes.length,
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
      if (rc != 0) throw ImageKitException(rc, readCString(err));

      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw ImageKitException(-999, 'Transform returned null buffer');
      }
      final out = Uint8List.fromList(nativeBuf.asTypedList(outLen.value));
      _ik_webp_free(nativeBuf);
      return out;
    } finally {
      freeAll([inPtr, outPtr, outLen, err]);
    }
  }
}
