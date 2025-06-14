// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:imagekit_ffi/imagekit_ffi.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const CameraApp());
}

/// CameraApp is the Main Application.
class CameraApp extends StatefulWidget {
  /// Default Constructor
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;

  Uint8List? memoryImage;

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _processRawCameraImage(CameraImage image) {
    try {
      // Плоскости:
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      // Размеры:
      final width = image.width;
      final height = image.height;

      // Stride (смещение в байтах между строками)
      final yStride = image.planes[0].bytesPerRow;
      final uStride = image.planes[1].bytesPerRow;
      final vStride = image.planes[2].bytesPerRow;

      // Pix stride (шаг между соседними пикселями)
      final uPixStride = image.planes[1].bytesPerPixel ?? 1;
      final vPixStride = image.planes[2].bytesPerPixel ?? 1;
      Stopwatch stopwatch = Stopwatch()..start();
      memoryImage = ImageKitFfi().convertYuv420ToJpeg(
        yPlane: yPlane,
        uPlane: uPlane,
        vPlane: vPlane,
        width: width,
        height: height,
        yStride: yStride,
        uStride: uStride,
        vStride: vStride,
        uPixStride: uPixStride,
        vPixStride: vPixStride,
        rotation: 90,
      );

      stopwatch.stop();
      print('Time jpeg: ${stopwatch.elapsedMilliseconds}');

      print('JPEG length: ${memoryImage?.length}');

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Column(
        children: [
          Expanded(child: CameraPreview(controller)),
          ElevatedButton(
            onPressed: controller.value.isInitialized
                ? () async {
                    // Take the Picture in a try / catch block. If anything goes wrong,
                    // catch the error.
                    try {
                      final completer = Completer<CameraImage>();
                      final stopwatch = Stopwatch()..start();

                      await controller.startImageStream(completer.complete);
                      final image = await completer.future;
                      print('Time image: ${stopwatch.elapsedMilliseconds}');

                      await controller.stopImageStream();

                      _processRawCameraImage(image);
                    } catch (e) {
                      print(e);
                    }
                  }
                : null,
            child: const Text('Take a picture'),
          ),
          if (memoryImage != null) Expanded(child: Image.memory(memoryImage!))
        ],
      ),
    );
  }
}
