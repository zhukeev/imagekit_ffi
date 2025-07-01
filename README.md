# imagekit_ffi

A Flutter plugin leveraging Dart FFI for high-performance image format conversions (BGRA8888, YUV420, NV21) **to PNG byte buffers**, with built-in rotation capabilities. This plugin is ideal for scenarios requiring efficient pixel data processing, such as camera streams or image manipulation, where you need direct access to the encoded image data in memory.

---

## Features

- **BGRA8888 to PNG Buffer Conversion:** Convert raw BGRA8888 pixel buffers directly to PNG byte arrays in memory.
- **YUV420 Planar to PNG Buffer Conversion:** Support for converting separate Y, U, and V planes (common in camera previews) to PNG byte arrays.
- **NV21 (Y + Interleaved UV) to PNG Buffer Conversion:** Efficiently convert NV21 format images to PNG byte arrays.
- **Rotation Support:** All conversion methods support image rotation (0, 90, 180, 270 degrees) during the conversion process for RGB data.
- **Cross-Platform:** Designed to work across Android, iOS, macOS, Windows, and Linux.
- **High Performance:** Utilizes native code for optimal speed in image processing.

---

## Current Status and Limitations

- **PNG Decoding (`convertPngToRgba`):** The native implementation for PNG decoding (converting a PNG byte buffer to RGBA8888) is currently a **placeholder**. The underlying `fpng` library is primarily an encoder. To enable PNG decoding, a dedicated PNG decoding library (e.g., `libpng` or `stb_image.h`) or a custom pure C implementation would need to be integrated on the native side.
