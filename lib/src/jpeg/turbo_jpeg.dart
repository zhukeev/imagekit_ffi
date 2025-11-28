import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as cstr;
import 'package:imagekit_ffi/src/core/ffi_utils.dart';
import 'package:imagekit_ffi/src/core/imagekit_core.dart';

part 'bindings.dart';

/* ========================== High-level API ========================== */

/// @override, stateless API for JPEG ⇄ pixels and lossless transforms.
///
/// The methods create/destroy native handles per call, which is simple and
/// usually fast enough. If you need to process thousands of images per second,
/// we can later add a “session” API that reuses handles.
final class TurboJpeg extends ImageCodec with FfiHelpers {
  @override
  int get errCap => 512;

  /// Returns the human-readable libjpeg-turbo version (e.g. `"2.1.5"`).
  @override
  String versionString() {
    final buf = allocBuf();
    try {
      final rc = _tjx_version_str(buf, errCap);
      if (rc != 0) return 'unknown';
      return readCString(buf);
    } finally {
      freeAll([buf]);
    }
  }

  /// Returns numeric libjpeg-turbo version (e.g. `2000000 == 2.0.0`).
  int versionInt() => _tjx_version_int();

  /// Parses width/height/subsampling/colorspace using a short-lived decoder.
  ///
  /// This does **not** decode pixel data.
  @override
  Header getHeader(Uint8List jpegBytes) {
    final jpg = copyToNative(jpegBytes);
    final w = cstr.calloc<ffi.Int32>();
    final h = cstr.calloc<ffi.Int32>();
    final ss = cstr.calloc<ffi.Int32>();
    final cs = cstr.calloc<ffi.Int32>();
    final err = allocBuf();
    final dec = _tjx_init_decompress(err, errCap);
    if (dec == ffi.nullptr) {
      final msg = readCString(err);
      freeAll([jpg, w, h, ss, cs, err]);
      throw TurboJpegException(-100, 'tjx_init_decompress failed: $msg');
    }
    try {
      final rc = _tjx_decompress_header3(dec, jpg, jpegBytes.length, w, h, ss, cs, err, errCap);
      if (rc != 0) {
        throw TurboJpegException(rc, readCString(err));
      }
      return Header(width: w.value, height: h.value, subsampling: Subsampling.values[ss.value], colorspace: cs.value);
    } finally {
      _tjx_destroy(dec);
      freeAll([jpg, w, h, ss, cs, err]);
    }
  }

  /// Decodes a JPEG into a tightly-packed buffer in the requested [pixelFormat].
  ///
  /// The returned `Uint8List` length is `width * height * pixelFormat.bytesPerPixel`.
  /// If you need a custom row stride, pass [Flags.bottomUp] and post-process as needed.
  @override
  Uint8List decode(Uint8List jpegBytes, {PixelFormat pixelFormat = PixelFormat.rgb, int flags = Flags.fastDct}) {
    final header = getHeader(jpegBytes);
    final outLen = header.width * header.height * pixelFormat.bytesPerPixel;

    final jpg = copyToNative(jpegBytes);
    final out = cstr.calloc<ffi.Uint8>(outLen);
    final err = allocBuf();

    final dec = _tjx_init_decompress(err, errCap);
    if (dec == ffi.nullptr) {
      final msg = readCString(err);
      freeAll([jpg, out, err]);
      throw TurboJpegException(-100, 'tjx_init_decompress failed: $msg');
    }

    try {
      final rc = _tjx_decompress_to_rgb(
        dec,
        jpg,
        jpegBytes.length,
        out,
        0, // tight pitch
        header.width,
        header.height,
        pixelFormat.value,
        flags,
        err,
        errCap,
      );
      if (rc != 0) {
        throw TurboJpegException(rc, readCString(err));
      }
      return Uint8List.fromList(out.asTypedList(outLen));
    } finally {
      _tjx_destroy(dec);
      freeAll([jpg, out, err]);
    }
  }

  /// Encodes a raw pixel buffer into a JPEG.
  ///
  /// - [pixels] must contain at least `height * pitchBytes` bytes, where
  ///   `pitchBytes = (pitchBytes ?? width * pixelFormat.bytesPerPixel)`.
  /// - [quality] is clamped to 1..100.
  /// - Use [subsampling] to select output chroma format (e.g. 4:2:0 for smaller files).
  @override
  Uint8List encode(
    Uint8List pixels,
    int width,
    int height, {
    PixelFormat pixelFormat = PixelFormat.rgb,
    Subsampling subsampling = Subsampling.y420,
    int quality = 90,
    int flags = Flags.fastDct,
    int? pitchBytes,
  }) {
    if (quality < 1 || quality > 100) {
      throw ArgumentError.value(quality, 'quality', 'Expected 1..100');
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

    final enc = _tjx_init_compress(err, errCap);
    if (enc == ffi.nullptr) {
      final msg = readCString(err);
      freeAll([inPtr, outPtr, outLen, err]);
      throw TurboJpegException(-100, 'tjx_init_compress failed: $msg');
    }

    try {
      final rc = _tjx_compress_from_rgb(
        enc,
        inPtr,
        width,
        pitch,
        height,
        pixelFormat.value,
        outPtr,
        outLen,
        subsampling.value,
        quality,
        flags,
        err,
        errCap,
      );
      if (rc != 0) {
        throw TurboJpegException(rc, readCString(err));
      }
      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw TurboJpegException(-999, 'Native encoder returned null buffer');
      }
      final bytes = nativeBuf.cast<ffi.Uint8>().asTypedList(outLen.value);
      final copy = Uint8List.fromList(bytes);
      _tjx_free(nativeBuf);
      return copy;
    } finally {
      _tjx_destroy(enc);
      freeAll([inPtr, outPtr, outLen, err]);
    }
  }

  /// Lossless transform (rotate/flip/transpose/transverse and/or crop) in the JPEG domain.
  ///
  /// **MCU alignment:** Lossless ops operate on MCU blocks. Use:
  /// - `options |= XformOptions.perfect` to **fail** if not perfectly aligned (no trimming).
  /// - `options |= XformOptions.trim` to allow trimming of partial MCUs at edges.
  ///
  /// For cropping, add `options |= XformOptions.crop` and set [cropX]/[cropY]/[cropW]/[cropH].
  @override
  Uint8List transform(
    Uint8List jpegBytes, {
    TransformOp op = TransformOp.none,
    int options = XformOptions.none,
    int cropX = 0,
    int cropY = 0,
    int cropW = 0,
    int cropH = 0,
    int flags = Flags.accurateDct, // typical default for transforms
  }) {
    final inPtr = copyToNative(jpegBytes);
    final outPtr = cstr.calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = cstr.calloc<ffi.Int64>();
    final err = allocBuf();

    try {
      final rc = _tjx_transform_simple(
        inPtr,
        jpegBytes.length,
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
      if (rc != 0) {
        throw TurboJpegException(rc, readCString(err));
      }

      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw TurboJpegException(-999, 'Transform returned null buffer');
      }

      final bytes = nativeBuf.asTypedList(outLen.value);
      final copy = Uint8List.fromList(bytes);
      _tjx_free(nativeBuf);
      return copy;
    } finally {
      freeAll([inPtr, outPtr, outLen, err]);
    }
  }

  /// Shortcut for 90° rotation. Set [perfect] to require MCU-perfect rotation (no trimming).
  Uint8List rotate90(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.rot90, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Shortcut for 180° rotation.
  Uint8List rotate180(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.rot180, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Shortcut for 270° rotation.
  Uint8List rotate270(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.rot270, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Horizontal flip (lossless).
  Uint8List flipH(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.hflip, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Vertical flip (lossless).
  Uint8List flipV(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.vflip, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Matrix transpose (swap X and Y), lossless.
  Uint8List transpose(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.transpose, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Matrix transverse (reverse across secondary diagonal), lossless.
  Uint8List transverse(Uint8List jpg, {bool perfect = false, int flags = 0}) =>
      transform(jpg, op: TransformOp.transverse, options: perfect ? XformOptions.perfect : 0, flags: flags);

  /// Lossless crop (optionally MCU-safe).
  ///
  /// - Set [trim] to allow boundary trimming.
  /// - Set [perfect] to require perfect MCU alignment (will throw otherwise).
  /// - Set [gray] to force grayscale during transform.
  Uint8List crop(
    Uint8List jpg, {
    required int x,
    required int y,
    required int w,
    required int h,
    bool trim = true,
    bool perfect = false,
    bool gray = false,
    int flags = 0,
  }) {
    var opts = XformOptions.crop;
    if (trim) opts |= XformOptions.trim;
    if (perfect) opts |= XformOptions.perfect;
    if (gray) opts |= XformOptions.gray;

    return transform(jpg, op: TransformOp.none, options: opts, cropX: x, cropY: y, cropW: w, cropH: h, flags: flags);
  }

  /// JPEG → planar **YUV420** (Y, U, V planes).
  ///
  /// The returned planes are tightly packed with strides computed by [yuv420Strides].
  ({Uint8List y, Uint8List u, Uint8List v}) decodeToYuv420(Uint8List jpegBytes, {int flags = Flags.fastDct}) {
    final h = getHeader(jpegBytes);
    final (yStride, uStride, vStride) = yuv420Strides(h.width);
    final (ySize, uSize, vSize) = yuv420PlaneSizes(h.width, h.height);

    final jpg = copyToNative(jpegBytes);
    final y = cstr.calloc<ffi.Uint8>(ySize);
    final u = cstr.calloc<ffi.Uint8>(uSize);
    final v = cstr.calloc<ffi.Uint8>(vSize);
    final err = allocBuf();

    final dec = _tjx_init_decompress(err, errCap);
    if (dec == ffi.nullptr) {
      final msg = readCString(err);
      freeAll([jpg, y, u, v, err]);
      throw TurboJpegException(-100, 'tjx_init_decompress failed: $msg');
    }

    try {
      final rc = _tjx_decompress_to_yuv_planes(
        dec,
        jpg,
        jpegBytes.length,
        y,
        yStride,
        u,
        uStride,
        v,
        vStride,
        h.width,
        h.height,
        flags,
        err,
        errCap,
      );
      if (rc != 0) throw TurboJpegException(rc, readCString(err));

      return (
        y: Uint8List.fromList(y.asTypedList(ySize)),
        u: Uint8List.fromList(u.asTypedList(uSize)),
        v: Uint8List.fromList(v.asTypedList(vSize)),
      );
    } finally {
      _tjx_destroy(dec);
      freeAll([jpg, y, u, v, err]);
    }
  }

  /// Planar **YUV420** → JPEG.
  ///
  /// Supply tightly packed planes as returned by [decodeToYuv420] or created using
  /// [yuv420PlaneSizes] and [yuv420Strides].
  Uint8List compressFromYuv420Planes(
    Uint8List y,
    Uint8List u,
    Uint8List v,
    int width,
    int height, {
    int quality = 90,
    int flags = Flags.fastDct,
  }) {
    final (yStride, uStride, vStride) = yuv420Strides(width);
    final (ySize, uSize, vSize) = yuv420PlaneSizes(width, height);
    if (y.length < ySize || u.length < uSize || v.length < vSize) {
      throw ArgumentError('Invalid plane sizes for $width×$height (YUV420).');
    }

    final yP = copyToNative(y, len: ySize);
    final uP = copyToNative(u, len: uSize);
    final vP = copyToNative(v, len: vSize);
    final outPtr = cstr.calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = cstr.calloc<ffi.Int64>();
    final err = allocBuf();

    final enc = _tjx_init_compress(err, errCap);
    if (enc == ffi.nullptr) {
      final msg = readCString(err);
      freeAll([yP, uP, vP, outPtr, outLen, err]);
      throw TurboJpegException(-100, 'tjx_init_compress failed: $msg');
    }

    try {
      final rc = _tjx_compress_from_yuv_planes(
        enc,
        yP,
        yStride,
        uP,
        uStride,
        vP,
        vStride,
        width,
        height,
        Subsampling.y420.value,
        outPtr,
        outLen,
        quality,
        flags,
        err,
        errCap,
      );
      if (rc != 0) throw TurboJpegException(rc, readCString(err));

      final nativeBuf = outPtr.value;
      if (nativeBuf == ffi.nullptr) {
        throw TurboJpegException(-999, 'Native compressor returned null buffer');
      }
      final bytes = nativeBuf.cast<ffi.Uint8>().asTypedList(outLen.value);
      final copy = Uint8List.fromList(bytes);
      _tjx_free(nativeBuf);
      return copy;
    } finally {
      _tjx_destroy(enc);
      freeAll([yP, uP, vP, outPtr, outLen, err]);
    }
  }

  /* ---------- YUV 4:2:0 helpers ---------- */

  /// Returns `(yStride, uStride, vStride)` for **YUV420** given an image [width].
  (int yStride, int uStride, int vStride) yuv420Strides(int width) => (width, (width + 1) >> 1, (width + 1) >> 1);

  /// Returns `(ySize, uSize, vSize)` for **YUV420** given [width] and [height].
  ///
  /// Useful for pre-allocating planes for camera/video pipelines.
  (int ySize, int uSize, int vSize) yuv420PlaneSizes(int width, int height) {
    final y = width * height;
    final cw = (width + 1) >> 1;
    final ch = (height + 1) >> 1;
    final u = cw * ch;
    final v = cw * ch;
    return (y, u, v);
  }
}
