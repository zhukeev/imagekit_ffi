import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:ffi/ffi.dart';

import 'imagekit_ffi_bindings_generated.dart';

/// Name of the native library without extension
const String _libName = 'imagekit_ffi';

/// Loads the dynamic library depending on the platform
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// Generated bindings for native library functions
final ImagekitFfiBindings _bindings = ImagekitFfiBindings(_dylib);

/// Wrapper class for image conversion functions
class ImageKitFfi {
  /// Converts a JPEG image to RGBA8888 format.
  ///
  /// Returns a tuple (Uint8List rgbaBytes, int width, int height).
  /// Throws [Exception] if decoding fails.
  ({Uint8List rgbaBytes, int width, int height}) convertJpegToRgba(
      Uint8List jpegBytes) {
    final jpegPtr = malloc<Uint8>(jpegBytes.length);
    final widthPtr = malloc<Int>();
    final heightPtr = malloc<Int>();

    try {
      jpegPtr.asTypedList(jpegBytes.length).setAll(0, jpegBytes);

      final rgbaPtr = _bindings.convert_jpeg_to_rgba(
        jpegPtr,
        jpegBytes.length,
        widthPtr,
        heightPtr,
      );

      if (rgbaPtr == nullptr) {
        throw Exception('JPEG → RGBA conversion failed (null pointer)');
      }

      final width = widthPtr.value;
      final height = heightPtr.value;
      final rgbaSize = width * height * 4;

      final rgbaBytes = rgbaPtr.asTypedList(rgbaSize);

      _bindings.free_buffer(jpegPtr);
      _bindings.free_buffer(rgbaPtr);

      return (
        rgbaBytes: Uint8List.fromList(rgbaBytes),
        width: width,
        height: height,
      );
    } finally {
      malloc.free(jpegPtr);
      malloc.free(widthPtr);
      malloc.free(heightPtr);
    }
  }

  /// Converts an image from BGRA8888 format to JPEG with optional rotation
  ///
  /// [bgra] — bytes of the source image in BGRA8888 format
  /// [width] — image width in pixels
  /// [height] — image height in pixels
  /// [rowStride] — number of bytes in a single row (usually width * 4)
  /// [rotation] — rotation angle in degrees (0, 90, 180, 270)
  ///
  /// Returns JPEG bytes as Uint8List
  Uint8List convertBgra8888ToJpeg(
    Uint8List bgra,
    int width,
    int height,
    int rowStride,
    int rotation,
  ) {
    final bgraPtr = malloc<Uint8>(bgra.length);
    final outSizePtr = malloc<Int>();

    try {
      final nativeBgra = bgraPtr.asTypedList(bgra.length);
      nativeBgra.setAll(0, bgra);

      final jpegPtr = _bindings
          .convert_bgra8888_to_jpeg_rotate(
            bgraPtr,
            width,
            height,
            rowStride,
            rotation,
            outSizePtr,
          )
          .cast<Uint8>();

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('JPEG conversion failed');
      }

      final jpegBytes = jpegPtr.asTypedList(jpegSize);
      _bindings.free_buffer(jpegPtr);
      return Uint8List.fromList(jpegBytes);
    } finally {
      malloc.free(bgraPtr);
      malloc.free(outSizePtr);
    }
  }

  /// Converts an image from YUV420 format (separate planes) to JPEG with rotation
  ///
  /// [yPlane], [uPlane], [vPlane] — Y, U, and V planes respectively
  /// [width], [height] — image dimensions
  /// [yStride], [uStride], [vStride] — stride (bytes per row) for each plane
  /// [uPixStride], [vPixStride] — pixel stride for U and V planes (default 1)
  /// [rotation] — rotation angle in degrees (0, 90, 180, 270)
  ///
  /// Returns JPEG bytes as Uint8List
  Uint8List convertYuv420ToJpeg({
    required Uint8List yPlane,
    required Uint8List uPlane,
    required Uint8List vPlane,
    required int width,
    required int height,
    required int yStride,
    required int uStride,
    required int vStride,
    int uPixStride = 1,
    int vPixStride = 1,
    int rotation = 0,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uPtr = malloc<Uint8>(uPlane.length);
    final vPtr = malloc<Uint8>(vPlane.length);
    final outSizePtr = malloc<Int>();

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uPtr.asTypedList(uPlane.length).setAll(0, uPlane);
      vPtr.asTypedList(vPlane.length).setAll(0, vPlane);

      final jpegPtr = _bindings
          .convert_yuv420_to_jpeg_rotate(
            yPtr,
            uPtr,
            vPtr,
            width,
            height,
            yStride,
            uStride,
            vStride,
            uPixStride,
            vPixStride,
            rotation,
            outSizePtr,
          )
          .cast<Uint8>();

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('JPEG conversion failed');
      }

      final jpegBytes = jpegPtr.asTypedList(jpegSize);
      _bindings.free_buffer(jpegPtr);
      return Uint8List.fromList(jpegBytes);
    } finally {
      malloc.free(yPtr);
      malloc.free(uPtr);
      malloc.free(vPtr);
      malloc.free(outSizePtr);
    }
  }

  /// Converts an image from NV21 format (Y + interleaved UV) to JPEG with rotation
  ///
  /// [yPlane] — Y plane bytes
  /// [uvPlane] — interleaved UV plane bytes
  /// [width], [height] — image dimensions
  /// [yStride], [uvStride] — stride for Y and UV planes
  /// [uvPixStride] — pixel stride in UV plane (default 2 for NV21)
  /// [rotation] — rotation angle in degrees (0, 90, 180, 270)
  ///
  /// Returns JPEG bytes as Uint8List
  Uint8List convertNv21ToJpeg({
    required Uint8List yPlane,
    required Uint8List uvPlane,
    required int width,
    required int height,
    required int yStride,
    required int uvStride,
    int uvPixStride = 2,
    int rotation = 0,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uvPtr = malloc<Uint8>(uvPlane.length);
    final outSizePtr = malloc<Int>();

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uvPtr.asTypedList(uvPlane.length).setAll(0, uvPlane);

      final jpegPtr = _bindings
          .convert_nv21_to_jpeg_rotate(
            yPtr,
            uvPtr,
            width,
            height,
            yStride,
            uvStride,
            uvPixStride,
            rotation,
            outSizePtr,
          )
          .cast<Uint8>();

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('JPEG conversion failed');
      }

      final jpegBytes = jpegPtr.asTypedList(jpegSize);
      _bindings.free_buffer(jpegPtr);
      return Uint8List.fromList(jpegBytes);
    } finally {
      malloc.free(yPtr);
      malloc.free(uvPtr);
      malloc.free(outSizePtr);
    }
  }
}
