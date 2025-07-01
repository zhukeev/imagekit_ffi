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
 
  /// Decodes a PNG image to RGBA8888 format.
  ///
  /// **NOTE:** This function's native implementation is a PLACEHOLDER.
  /// Your current C library (`fpng`) is for PNG *encoding* (writing), not *decoding* (reading).
  /// You will need to implement a PNG decoder in pure C or integrate a PNG decoding library
  /// (e.g., `libpng` or `stb_image.h`) on the C side for this to work.
  ///
  /// [pngBytes] — The raw PNG image data.
  ///
  /// Returns a record ({Uint8List rgbaBytes, int width, int height})
  /// containing the RGBA bytes, width, and height.
  /// Throws [Exception] if decoding fails.
  ({Uint8List rgbaBytes, int width, int height}) convertPngToRgba(Uint8List pngBytes) {
    final pngPtr = malloc<Uint8>(pngBytes.length);
    final widthPtr = malloc<Int>();
    final heightPtr = malloc<Int>();
    Pointer<Uint8> rgbaPtr = nullptr;

    try {
      pngPtr.asTypedList(pngBytes.length).setAll(0, pngBytes);

      rgbaPtr = _bindings.convert_png_to_rgba(
        pngPtr,
        pngBytes.length,
        widthPtr,
        heightPtr,
      );

      if (rgbaPtr == nullptr) {
        throw Exception(
            'PNG -> RGBA conversion failed: null pointer returned from native code. (Decoder not implemented)');
      }

      final width = widthPtr.value;
      final height = heightPtr.value;
      final rgbaSize = width * height * 4;

      final rgbaBytes = Uint8List.fromList(rgbaPtr.asTypedList(rgbaSize));
      return (
        rgbaBytes: rgbaBytes,
        width: width,
        height: height,
      );
    } finally {
      malloc.free(pngPtr);
      malloc.free(widthPtr);
      malloc.free(heightPtr);
      if (rgbaPtr != nullptr) {
        _bindings.free_buffer(rgbaPtr);
      }
    }
  }

  /// Converts a BGRA8888 image to a PNG byte buffer.
  ///
  /// [bgraBytes] — The raw BGRA8888 image data (4 bytes per pixel, B G R A).
  /// [width] — The width of the image in pixels.
  /// [height] — The height of the image in pixels.
  ///
  /// Returns a [Uint8List] containing the encoded PNG data.
  /// Throws [Exception] if the conversion fails.
  Uint8List convertBgraToPngBuffer(Uint8List bgraBytes, int width, int height) {
    final bgraPtr = malloc<Uint8>(bgraBytes.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> pngDataPtr = nullptr;

    try {
      bgraPtr.asTypedList(bgraBytes.length).setAll(0, bgraBytes);

      pngDataPtr = _bindings.convert_bgra_to_png_buffer(
        bgraPtr,
        width,
        height,
        outSizePtr,
      );

      final pngSize = outSizePtr.value;
      if (pngDataPtr == nullptr || pngSize <= 0) {
        throw Exception('BGRA -> PNG buffer conversion failed: null pointer or invalid size returned.');
      }

      final pngBytes = Uint8List.fromList(pngDataPtr.asTypedList(pngSize));
      return pngBytes;
    } finally {
      malloc.free(bgraPtr);
      malloc.free(outSizePtr);
      if (pngDataPtr != nullptr) {
        _bindings.free_buffer(pngDataPtr);
      }
    }
  }

  /// Converts YUV420 image data (separate planes) to a PNG byte buffer.
  ///
  /// [yPlane], [uPlane], [vPlane] — Y, U, and V planes respectively.
  /// [width], [height] — image dimensions.
  /// [yStride], [uStride], [vStride] — stride (bytes per row) for each plane.
  /// [uPixStride], [vPixStride] — pixel stride for U and V planes (default 1).
  ///
  /// Returns a [Uint8List] containing the encoded PNG data.
  /// Throws [Exception] if the conversion fails.
  Uint8List convertYuv420ToPngBuffer({
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
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uPtr = malloc<Uint8>(uPlane.length);
    final vPtr = malloc<Uint8>(vPlane.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> pngDataPtr = nullptr;

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uPtr.asTypedList(uPlane.length).setAll(0, uPlane);
      vPtr.asTypedList(vPlane.length).setAll(0, vPlane);

      pngDataPtr = _bindings.convert_yuv420_to_png_buffer(
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
        outSizePtr,
      );

      final pngSize = outSizePtr.value;
      if (pngDataPtr == nullptr || pngSize <= 0) {
        throw Exception('YUV420 -> PNG buffer conversion failed: null pointer or invalid size returned.');
      }

      final pngBytes = Uint8List.fromList(pngDataPtr.asTypedList(pngSize));
      return pngBytes;
    } finally {
      malloc.free(yPtr);
      malloc.free(uPtr);
      malloc.free(vPtr);
      malloc.free(outSizePtr);
      if (pngDataPtr != nullptr) {
        _bindings.free_buffer(pngDataPtr);
      }
    }
  }

  /// Converts NV21 image data (Y + interleaved UV) to a PNG byte buffer.
  ///
  /// [yPlane] — Y plane bytes.
  /// [uvPlane] — interleaved UV plane bytes.
  /// [width], [height] — image dimensions.
  /// [yStride], [uvStride] — stride for Y and UV planes.
  /// [uvPixStride] — pixel stride in UV plane (default 2 for NV21).
  ///
  /// Returns a [Uint8List] containing the encoded PNG data.
  /// Throws [Exception] if the conversion fails.
  Uint8List convertNv21ToPngBuffer({
    required Uint8List yPlane,
    required Uint8List uvPlane,
    required int width,
    required int height,
    required int yStride,
    required int uvStride,
    int uvPixStride = 2,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uvPtr = malloc<Uint8>(uvPlane.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> pngDataPtr = nullptr;

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uvPtr.asTypedList(uvPlane.length).setAll(0, uvPlane);

      pngDataPtr = _bindings.convert_nv21_to_png_buffer(
        yPtr,
        uvPtr,
        width,
        height,
        yStride,
        uvStride,
        uvPixStride,
        outSizePtr,
      );

      final pngSize = outSizePtr.value;
      if (pngDataPtr == nullptr || pngSize <= 0) {
        throw Exception('NV21 -> PNG buffer conversion failed: null pointer or invalid size returned.');
      }

      final pngBytes = Uint8List.fromList(pngDataPtr.asTypedList(pngSize));
      return pngBytes;
    } finally {
      malloc.free(yPtr);
      malloc.free(uvPtr);
      malloc.free(outSizePtr);
      if (pngDataPtr != nullptr) {
        _bindings.free_buffer(pngDataPtr);
      }
    }
  }

  /// Rotates an RGB image buffer by 0, 90, 180, or 270 degrees.
  ///
  /// [rgbBytes] — The raw RGB byte data (3 bytes per pixel, tightly packed).
  /// [width] — The width of the original image (in pixels).
  /// [height] — The height of the original image (in pixels).
  /// [rotation] — The rotation angle in degrees (must be 0, 90, 180, or 270).
  ///
  /// Returns a new [Uint8List] containing the rotated image data.
  /// Throws an [Exception] if the rotation fails (null pointer or invalid output).
  Uint8List rotateRgbImage({
    required Uint8List rgbBytes,
    required int width,
    required int height,
    required int rotation,
  }) {
    final rgbPtr = malloc<Uint8>(rgbBytes.length);
    Pointer<Uint8> rotatedPtr = nullptr;

    try {
      rgbPtr.asTypedList(rgbBytes.length).setAll(0, rgbBytes);

      rotatedPtr = _bindings.rotate_rgb_image(
        rgbPtr,
        width,
        height,
        rotation,
      );

      if (rotatedPtr == nullptr) {
        throw Exception('RGB rotation failed: null pointer returned.');
      }

      final rotatedWidth = (rotation % 180 == 0) ? width : height;
      final rotatedHeight = (rotation % 180 == 0) ? height : width;
      final outputLength = rotatedWidth * rotatedHeight * 3;

      final rotatedBytes = Uint8List.fromList(rotatedPtr.asTypedList(outputLength));
      return rotatedBytes;
    } finally {
      malloc.free(rgbPtr);
      if (rotatedPtr != nullptr) {
        _bindings.free_buffer(rotatedPtr);
      }
    }
  }
}
