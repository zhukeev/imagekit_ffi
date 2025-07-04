import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:ffi/ffi.dart';

import 'imagekit_ffi_bindings_generated.dart';

const String _libName = 'imagekit_ffi';

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

final ImagekitFfiBindings _bindings = ImagekitFfiBindings(_dylib);

class ImageKitFfi {
  /// Освобождение выделенного нативного буфера
  void freeBuffer(Pointer<Uint8> buffer) {
    if (buffer != nullptr) {
      _bindings.free_buffer(buffer);
    }
  }

  Uint8List convertYuv420ToJpegBuffer({
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
    int rotationDegrees = 0,
    int quality = 90,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uPtr = malloc<Uint8>(uPlane.length);
    final vPtr = malloc<Uint8>(vPlane.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> jpegPtr = nullptr;

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uPtr.asTypedList(uPlane.length).setAll(0, uPlane);
      vPtr.asTypedList(vPlane.length).setAll(0, vPlane);

      jpegPtr = _bindings.convert_yuv420_to_jpeg(
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
        rotationDegrees,
        quality,
        outSizePtr,
      );

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('YUV420 -> JPEG conversion failed');
      }

      return Uint8List.fromList(jpegPtr.asTypedList(jpegSize));
    } finally {
      malloc.free(yPtr);
      malloc.free(uPtr);
      malloc.free(vPtr);
      malloc.free(outSizePtr);
      if (jpegPtr != nullptr) {
        _bindings.free_buffer(jpegPtr);
      }
    }
  }

  Uint8List convertNv21ToJpegBuffer({
    required Uint8List yPlane,
    required Uint8List uvPlane,
    required int width,
    required int height,
    required int yStride,
    required int uvStride,
    int uvPixStride = 2,
    int rotationDegrees = 0,
    int quality = 90,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uvPtr = malloc<Uint8>(uvPlane.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> jpegPtr = nullptr;

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uvPtr.asTypedList(uvPlane.length).setAll(0, uvPlane);

      jpegPtr = _bindings.convert_nv21_to_jpeg(
        yPtr,
        uvPtr,
        width,
        height,
        yStride,
        uvStride,
        uvPixStride,
        rotationDegrees,
        quality,
        outSizePtr,
      );

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('NV21 -> JPEG conversion failed');
      }

      return Uint8List.fromList(jpegPtr.asTypedList(jpegSize));
    } finally {
      malloc.free(yPtr);
      malloc.free(uvPtr);
      malloc.free(outSizePtr);
      if (jpegPtr != nullptr) {
        _bindings.free_buffer(jpegPtr);
      }
    }
  }

  Uint8List encodeRgbaToJpegBuffer({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    int quality = 90,
  }) {
    final rgbaPtr = malloc<Uint8>(rgbaBytes.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> jpegPtr = nullptr;

    try {
      rgbaPtr.asTypedList(rgbaBytes.length).setAll(0, rgbaBytes);

      jpegPtr = _bindings.encode_rgba_to_jpeg_buffer(
        rgbaPtr,
        width,
        height,
        quality,
        outSizePtr,
      );

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('RGBA -> JPEG conversion failed');
      }

      return Uint8List.fromList(jpegPtr.asTypedList(jpegSize));
    } finally {
      malloc.free(rgbaPtr);
      malloc.free(outSizePtr);
      if (jpegPtr != nullptr) {
        _bindings.free_buffer(jpegPtr);
      }
    }
  }

  /// Поворот RGBA изображения
  Uint8List rotateRgbaImage({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required int rotationDegrees,
  }) {
    final rgbaPtr = malloc<Uint8>(rgbaBytes.length);
    Pointer<Uint8> rotatedPtr = nullptr;

    try {
      rgbaPtr.asTypedList(rgbaBytes.length).setAll(0, rgbaBytes);

      rotatedPtr = _bindings.rotate_rgba_image(
        rgbaPtr,
        width,
        height,
        rotationDegrees,
      );

      if (rotatedPtr == nullptr) {
        throw Exception('RGBA rotation failed');
      }

      final rotatedWidth = (rotationDegrees % 180 == 0) ? width : height;
      final rotatedHeight = (rotationDegrees % 180 == 0) ? height : width;
      final outputLength = rotatedWidth * rotatedHeight * 4;

      return Uint8List.fromList(rotatedPtr.asTypedList(outputLength));
    } finally {
      malloc.free(rgbaPtr);
      if (rotatedPtr != nullptr) {
        _bindings.free_buffer(rotatedPtr);
      }
    }
  }

  Uint8List encodeBgraToJpegBuffer({
    required Uint8List bgraBytes,
    required int width,
    required int height,
    int quality = 90,
  }) {
    final bgraPtr = malloc<Uint8>(bgraBytes.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> jpegPtr = nullptr;

    try {
      bgraPtr.asTypedList(bgraBytes.length).setAll(0, bgraBytes);

      jpegPtr = _bindings.encode_bgra_to_jpeg_buffer(
        bgraPtr,
        width,
        height,
        quality,
        outSizePtr,
      );

      final jpegSize = outSizePtr.value;
      if (jpegPtr == nullptr || jpegSize <= 0) {
        throw Exception('BGRA -> JPEG conversion failed');
      }

      return Uint8List.fromList(jpegPtr.asTypedList(jpegSize));
    } finally {
      malloc.free(bgraPtr);
      malloc.free(outSizePtr);
      if (jpegPtr != nullptr) {
        _bindings.free_buffer(jpegPtr);
      }
    }
  }

  Uint8List rotateJpegBuffer({
    required Uint8List jpegBytes,
    required int rotationDegrees,
  }) {
    final jpegPtr = malloc<Uint8>(jpegBytes.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> rotatedPtr = nullptr;

    try {
      jpegPtr.asTypedList(jpegBytes.length).setAll(0, jpegBytes);

      rotatedPtr = _bindings.rotate_jpeg_buffer(
        jpegPtr,
        jpegBytes.length,
        rotationDegrees,
        outSizePtr,
      );

      final outSize = outSizePtr.value;
      if (rotatedPtr == nullptr || outSize <= 0) {
        throw Exception('JPEG rotation failed');
      }

      return Uint8List.fromList(rotatedPtr.asTypedList(outSize));
    } finally {
      malloc.free(jpegPtr);
      malloc.free(outSizePtr);
      if (rotatedPtr != nullptr) {
        _bindings.free_buffer(rotatedPtr);
      }
    }
  }
}
