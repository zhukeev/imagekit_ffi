## 0.0.3

* added rotation

## 0.0.2

* **Feature:** Switched all image output formats from JPEG to **PNG**.
  * `convertBgra8888ToJpeg` is replaced by `convertBgraToPngBuffer`.
  * `convertYuv420ToJpeg` is replaced by `convertYuv420ToPngBuffer`.
  * `convertNv21ToJpeg` is replaced by `convertNv21ToPngBuffer`.
* **Feature:** All image conversion methods now return the encoded image data as a `Uint8List` (byte buffer) directly to Dart, instead of writing to a file.
* **Improvement:** Added native C implementations for YUV420 and NV21 to RGBA conversion, facilitating direct PNG encoding from camera stream formats.
* **Documentation:** Updated `README.md` to accurately reflect the new PNG focus, buffer output, and current feature set.
* **Clarification:** Explicitly noted that PNG decoding (`convertPngToRgba`) remains a placeholder and requires a dedicated decoding library.

## 0.0.1

* TODO: Describe initial release.
