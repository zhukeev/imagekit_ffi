# imagekit_ffi

A Flutter plugin leveraging Dart FFI for high-performance image format conversions (BGRA8888, YUV420, NV21) **to JPEG byte buffers**, with built-in rotation capabilities. This plugin is ideal for scenarios requiring efficient pixel data processing, such as camera streams or image manipulation, where you need direct access to the encoded image data in memory.

---

## Features

- **BGRA8888 to JPEG Buffer Conversion:** Convert raw BGRA8888 pixel buffers directly to JPEG byte arrays in memory.
- **YUV420 Planar to JPEG Buffer Conversion:** Support for converting separate Y, U, and V planes (common in camera previews) to JPEG byte arrays.
- **NV21 (Y + Interleaved UV) to JPEG Buffer Conversion:** Efficiently convert NV21 format images to JPEG byte arrays.
- **Rotation Support:** All conversion methods support image rotation (0, 90, 180, 270 degrees) during the conversion process for RGB data.
- **Cross-Platform:** Designed to work across Android, iOS, macOS, Windows, and Linux.
- **High Performance:** Utilizes native code for optimal speed in image processing.

---

## Current Status and Limitations

- **JPEG Decoding (`convertJPEGToRgba`):** The native implementation for JPEG decoding (converting a JPEG byte buffer to RGBA8888) is currently a **placeholder**. The underlying `fJPEG` library is primarily an encoder. To enable JPEG decoding, a dedicated JPEG decoding library (e.g., `libJPEG` or `stb_image.h`) or a custom pure C implementation would need to be integrated on the native side.
