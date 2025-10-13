# imagekit_ffi

High-performance image codecs for Flutter/Dart via Native Assets + FFI.  
Currently ships fast, production-grade **JPEG**, **PNG**, and **WebP** encode/decode APIs, plus lossless/lossy transforms where supported. Works on Android, iOS, macOS, Windows, and Linux.

> SDK constraint: `>=3.9.0 <4.0.0`

---

## Highlights

- **JPEG (libjpeg-turbo):**
  - Read header (size, subsampling, colorspace)
  - Decode → RGB/BGR/RGBA/BGRA/ARGB/ABGR/GRAY
  - Encode from interleaved RGB(A) with quality + subsampling control
  - YUV420 planar helpers (decode to planes / encode from planes)
  - **Lossless transforms** (rotate/flip/transpose/transverse, crop) in JPEG domain

- **PNG (libpng):**
  - Read header
  - Decode/encode interleaved RGB(A), BGR(A), GRAY

- **WebP (libwebp + sharpyuv):**
  - Read header
  - Decode → RGB(A)/BGR(A)/GRAY
  - Encode lossy/lossless; optional “near-lossless” when approximating 4:4:4
  - Pixel-domain transforms (rotate/flip/crop) with re-encode

- **Fast & small:** Native C bindings with minimal glue.  
- **Native Assets:** Artifacts are auto-packaged by Flutter; no manual CMake in your app.

---

## Installation

```yaml
dependencies:
  imagekit_ffi: ^<latest>
```

Nothing else is required for typical apps. The plugin builds and bundles the native libraries for your targets using Flutter’s Native Assets.

---

## Quick Start

```dart
import 'dart:typed_data';
import 'package:imagekit_ffi/imagekit_ffi.dart';

// JPEG header only:
final tj = TurboJpeg();
final header = tj.getHeader(jpegBytes);
print('${header.width}×${header.height}, subsampling=${header.subsampling}');

// JPEG → RGBA:
final rgba = tj.decode(jpegBytes, pixelFormat: PixelFormat.rgba);

// RGBA → JPEG (quality 90, 4:2:0):
final jpg = tj.encode(
  rgba, header.width, header.height,
  pixelFormat: PixelFormat.rgba,
  subsampling: Subsampling.y420,
  quality: 90,
);

// Lossless rotate 90° (JPEG domain):
final jpgRot = tj.rotate90(jpg, perfect: false);

// PNG round-trip:
final png = PngKit();
final pngRgba = png.decode(pngBytes, pixelFormat: PixelFormat.rgba);
final pngOut = png.encode(pngRgba, width, height, pixelFormat: PixelFormat.rgba);

// WebP header + encode:
final webp = WebpKit();
final wHeader = webp.getHeader(webpBytes);
final webpOut = webp.encode(
  rgba, width, height,
  pixelFormat: PixelFormat.rgba,
  subsampling: Subsampling.y420, // treated as 4:2:0 (lossy) or 4:4:4 via lossless/near-lossless
  quality: 90,
);
```

### Convert file format (codec → codec)

```dart
void convert(ImageCodec fromCodec, ImageCodec toCodec, List<int> bytes, String outPath) {
  final header = fromCodec.getHeader(bytes as Uint8List);
  final rgb = fromCodec.decode(bytes as Uint8List, pixelFormat: PixelFormat.rgba);
  final out = toCodec.encode(rgb, header.width, header.height, pixelFormat: PixelFormat.rgba);
  File(outPath).writeAsBytesSync(out);
}
```

---

## Pixel Formats

- `rgb`, `bgr` (3 bytes/pixel)  
- `rgba`, `bgra`, `argb`, `abgr` (4 bytes/pixel)  
- `gray` (1 byte/pixel; WebP decodes via Y-plane)

Pitch/stride defaults to “tight”; pass custom pitch to encoders if needed.

---

## JPEG YUV420 Helpers

```dart
// Decode JPEG → planar Y, U, V
final planes = tj.decodeToYuv420(jpegBytes);

// Encode JPEG from YUV420 planes
final jpg = tj.compressFromYuv420Planes(
  planes.y, planes.u, planes.v, width, height, quality: 90,
);
```

---

## Configure Native Builds (Enable/Disable & Sources)

You can fully control **which codecs are included** and **where their third-party libraries come from** using **Native Assets hook user-defines** in your app’s `pubspec.yaml`.

### Enable/disable codecs (slim builds)

```yaml
hooks:
  user_defines:
    imagekit_ffi:
      # JPEG (libjpeg-turbo)
      turbo_jpeg:
        enable: true
        version: "3.1.2"
        # Shortcut for pinned download:
        tarball_uri: "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.2/libjpeg-turbo-3.1.2.tar.gz"

      # PNG (libpng)
      png:
        enable: true
        # Or pick a source map (see below)

      # WebP (libwebp + sharpyuv)
      webp:
        enable: true
        # Or pick a source map (see below)
```

- Setting `enable: false` **excludes** that codec’s native binary from the build → smaller app.
- Turn off PNG/WebP if you only need JPEG, etc.

### Choosing library source: **download** / **vendored** / **system**

Each library (`turbo_jpeg`, `png`, `webp`, and optional `sharpyuv`) accepts a `source` map:

- **Download (recommended for reproducible builds)**
  ```yaml
  hooks:
    user_defines:
      imagekit_ffi:
        webp:
          enable: true
          source:
            download:
              url: "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.4.0.tar.gz"
  ```

- **Vendored (use a local checkout in your repo)**
  ```yaml
  hooks:
    user_defines:
      imagekit_ffi:
        png:
          enable: true
          source:
            vendored:
              path: third_party/libpng-1.6.43
  ```

- **System (use headers/libs preinstalled on the build machine)**
  ```yaml
  hooks:
    user_defines:
      imagekit_ffi:
        png:
          enable: true
          source:
            system: true
  ```

Internally, the plugin parses the `source` map as follows:

- empty or `system: true` → **System**
- `vendored.path` (required) → **Vendored**
- `download.url` (required) → **Download**

If you only need to bump **libjpeg-turbo** via fixed version + tarball (shortcut), the `version` + `tarball_uri` keys (shown above) are supported.

#### Minimal JPEG-only example

```yaml
hooks:
  user_defines:
    imagekit_ffi:
      turbo_jpeg:
        enable: true
        version: "3.1.2"
        tarball_uri: "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.2/libjpeg-turbo-3.1.2.tar.gz"
      png:
        enable: false
      webp:
        enable: false
```

> **Note:** On some platforms `libsharpyuv` is separately linked; when building WebP, the plugin links it automatically if needed.

---

## Platform Notes

- **Android:** Native Assets place `.so` files automatically per ABI.  
  **Do not** also copy your own duplicates into `android/app/src/main/jniLibs`, or you’ll hit
  “Duplicate resources” at `:app:mergeDebugJniLibFolders`.

- **“cannot locate symbol: pow” on Android:**  
  If you vendor/build your own libwebp and see a runtime `pow` resolution error, ensure it’s linked with the C math library (`-lm`). The plugin’s default build wires this in for Android/Linux when needed.

- **iOS/macOS:** Native Assets bundle the libraries; no extra steps. If you ever see a `*.dylib not found` error, clean the build and reinstall the app to refresh the Native Assets bundle.

---

## Troubleshooting

- **`dlopen failed: library "<name>.so" not found`**
  - Ensure you’re running a device/ABI you built for.
  - Clean/rebuild the app to refresh Native Assets.
  - Don’t manually strip `.so` files from the final APK/AAB.

- **`Duplicate resources` during `:app:mergeDebugJniLibFolders`**
  - Remove any manual copies of `.so` under `android/app/src/main/jniLibs`. Native Assets already places them there.

---

## Performance Tips

- Reuse pixel buffers across frames to reduce GC pressure.
- Prefer JPEG YUV420 planar APIs for camera pipelines.
- Tune JPEG `flags` (`fastDct`/`accurateDct`) to match your quality/speed needs.
- For WebP, `use_sharp_yuv` is enabled in the plugin for better chroma quality.

---

## Roadmap

Planned additional formats (subject to licensing & portability review):

- **AVIF** (libavif + aom/dav1d)
- **HEIF/HEIC** (libheif)
- **TIFF** (libtiff)
- **GIF** (giflib)
- **BMP** and simple PPM/PGM paths for utilities

---

## License

MIT License — see [LICENSE](https://github.com/zhukeev/imagekit_ffi/blob/main/LICENSE)

---

## Acknowledgements

- [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo)
- [libpng](http://www.libpng.org/)
- [libwebp & sharpyuv](https://chromium.googlesource.com/webm/libwebp/)
