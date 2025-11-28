// Core types shared by all codecs (JPEG/PNG/WebP, etc).
// Keep this file dependency-free (just dart:typed_data) to avoid cycles.

import 'dart:typed_data';

/// Stable pixel formats shared across codecs.
/// Values are chosen to match libjpeg-turbo TJPF_* for easier interop.
/// PNG/WebP glue converts internally as needed.
enum PixelFormat {
  rgb(0, 3),
  bgr(1, 3),
  rgbx(2, 4),
  bgrx(3, 4),
  xbgr(4, 4),
  xrgb(5, 4),
  gray(6, 1),
  rgba(7, 4),
  bgra(8, 4),
  abgr(9, 4),
  argb(10, 4),
  cmyk(11, 4); // may be unsupported by some codecs

  const PixelFormat(this.value, this.bytesPerPixel);
  final int value;
  final int bytesPerPixel;
}

/// Subsampling modes
enum Subsampling {
  s444(0),
  s422(1),
  y420(2),
  gray(3),
  s440(4),
  s411(5);

  const Subsampling(this.value);
  final int value;
}

/// Common flags bitmask; individual codecs may ignore some of them.
abstract final class Flags {
  static const int none = 0;
  static const int bottomUp = 2; // memory layout hint
  static const int fastUpsample = 256; // JPEG
  static const int fastDct = 2048; // JPEG
  static const int accurateDct = 4096; // JPEG
  static const int progressive = 16384; // JPEG encode
}

/// Lossless transform ops (JPEG is truly lossless; others simulate in RGBA).
enum TransformOp {
  none(0),
  hflip(1),
  vflip(2),
  transpose(3),
  transverse(4),
  rot90(5),
  rot180(6),
  rot270(7);

  const TransformOp(this.value);
  final int value;
}

/// Transform options. JPEG uses all; PNG/WebP ignore `perfect/trim`.
abstract final class XformOptions {
  static const int none = 0;
  static const int perfect = 1 << 0;
  static const int trim = 1 << 1;
  static const int crop = 1 << 2;
  static const int gray = 1 << 3;
  static const int noOutput = 1 << 4;
}

/// Minimal, codec-agnostic header.
final class Header {
  final int width;
  final int height;
  final Subsampling subsampling; // PNG returns s444
  final int colorspace; // codec specific (JPEG: TJCS_*, PNG/WebP: 0)
  const Header({required this.width, required this.height, required this.subsampling, required this.colorspace});
  @override
  String toString() => 'Header($width×$height, subsampling=$subsampling, colorspace=$colorspace)';
}

/// Base exception for all codecs.
class ImageKitException implements Exception {
  final int code;
  final String message;
  const ImageKitException(this.code, this.message);
  @override
  String toString() => 'ImageKitException($code, $message)';
}

/// JPEG-specific (subclasses are optional; helps catching precisely).
class TurboJpegException extends ImageKitException {
  const TurboJpegException(super.code, super.message);
}

/// PNG-specific.
class PngException extends ImageKitException {
  const PngException(super.code, super.message);
}

/// WebP-specific.
class WebpException extends ImageKitException {
  const WebpException(super.code, super.message);
}

/// A unified codec contract implemented by JPEG/PNG/WebP.
abstract class ImageCodec {
  /// Size of the temporary native error buffer (bytes, incl. trailing 0).
  /// Override per codec/instance if needed.
  int get errCap => 256;

  /// Human-readable library version.
  String versionString();

  /// Lightweight header parse (no pixel decode).
  Header getHeader(Uint8List data);

  /// Decode into tightly packed [pixelFormat]. Returns `width*height*bpp` bytes.
  Uint8List decode(Uint8List data, {PixelFormat pixelFormat = PixelFormat.rgba, int flags = Flags.none});

  /// Encode pixels → compressed bytes. If [pitchBytes] is null, assumes tight rows.
  Uint8List encode(
    Uint8List pixels,
    int width,
    int height, {
    PixelFormat pixelFormat = PixelFormat.rgba,
    Subsampling subsampling = Subsampling.s444, // ignored by PNG
    int quality = 90, // ignored by PNG
    int flags = Flags.none,
    int? pitchBytes,
  });

  /// Transform (rotate/flip/transpose/transverse/crop). Lossless for JPEG; simulated for others.
  Uint8List transform(
    Uint8List data, {
    TransformOp op = TransformOp.none,
    int options = XformOptions.none,
    int cropX = 0,
    int cropY = 0,
    int cropW = 0,
    int cropH = 0,
    int flags = Flags.none,
  });
}

/// Simple factory to pick a codec by signature or file extension.
class ImageCodecs {
  static bool _isPng(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;

  static bool _isJpeg(Uint8List bytes) => bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

  /// Provide concrete implementations via lazy imports in your project wires.
  static ImageCodec forBytes(Uint8List bytes, {required ImageCodec jpeg, required ImageCodec png}) {
    if (_isJpeg(bytes)) return jpeg;
    if (_isPng(bytes)) return png;
    // Fallback: try JPEG first (common) then PNG.
    return _isJpeg(bytes) ? jpeg : png;
  }
}
