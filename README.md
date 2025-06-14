# imagekit_ffi

A Flutter plugin leveraging Dart FFI for high-performance image format conversions (BGRA8888, YUV420, NV21) to JPEG, with built-in rotation capabilities. This plugin is ideal for scenarios requiring efficient pixel data processing, such as camera streams or image manipulation.

---

## Features

- **BGRA8888 to JPEG Conversion:** Convert raw BGRA8888 pixel buffers directly to JPEG.
- **YUV420 Planar to JPEG Conversion:** Support for converting separate Y, U, and V planes (common in camera previews) to JPEG.
- **NV21 (Y + Interleaved UV) to JPEG Conversion:** Efficiently convert NV21 format images to JPEG.
- **Rotation Support:** All conversion methods support image rotation (0, 90, 180, 270 degrees) during the conversion process.
- **Cross-Platform:** Designed to work across Android, iOS, macOS, Windows, and Linux.
- **High Performance:** Utilizes native code for optimal speed in image processing.

---
