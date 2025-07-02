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

  /// Конвертация YUV420 -> PNG с поворотом
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
    int rotationDegrees = 0,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uPtr = malloc<Uint8>(uPlane.length);
    final vPtr = malloc<Uint8>(vPlane.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> pngPtr = nullptr;

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uPtr.asTypedList(uPlane.length).setAll(0, uPlane);
      vPtr.asTypedList(vPlane.length).setAll(0, vPlane);

      pngPtr = _bindings.convert_yuv420_to_png(
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
        outSizePtr,
      );

      final pngSize = outSizePtr.value;
      if (pngPtr == nullptr || pngSize <= 0) {
        throw Exception('YUV420 -> PNG conversion failed');
      }

      return Uint8List.fromList(pngPtr.asTypedList(pngSize));
    } finally {
      malloc.free(yPtr);
      malloc.free(uPtr);
      malloc.free(vPtr);
      malloc.free(outSizePtr);
      if (pngPtr != nullptr) {
        _bindings.free_buffer(pngPtr);
      }
    }
  }

  /// Конвертация NV21 -> PNG с поворотом
  Uint8List convertNv21ToPngBuffer({
    required Uint8List yPlane,
    required Uint8List uvPlane,
    required int width,
    required int height,
    required int yStride,
    required int uvStride,
    int uvPixStride = 2,
    int rotationDegrees = 0,
  }) {
    final yPtr = malloc<Uint8>(yPlane.length);
    final uvPtr = malloc<Uint8>(uvPlane.length);
    final outSizePtr = malloc<Size>();
    Pointer<Uint8> pngPtr = nullptr;

    try {
      yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
      uvPtr.asTypedList(uvPlane.length).setAll(0, uvPlane);

      pngPtr = _bindings.convert_nv21_to_png(
        yPtr,
        uvPtr,
        width,
        height,
        yStride,
        uvStride,
        uvPixStride,
        rotationDegrees,
        outSizePtr,
      );

      final pngSize = outSizePtr.value;
      if (pngPtr == nullptr || pngSize <= 0) {
        throw Exception('NV21 -> PNG conversion failed');
      }

      return Uint8List.fromList(pngPtr.asTypedList(pngSize));
    } finally {
      malloc.free(yPtr);
      malloc.free(uvPtr);
      malloc.free(outSizePtr);
      if (pngPtr != nullptr) {
        _bindings.free_buffer(pngPtr);
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
}
