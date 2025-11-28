import 'dart:io';

import 'package:imagekit_ffi/imagekit_ffi.dart';

void main() {
  _testCodec(TurboJpeg(), 'example/sample.jpg');
  _testCodec(PngKit(), 'example/image.png');
  _testCodec(WebpKit(), 'example/1.webp');

  convertCodec(PngKit(), TurboJpeg(), 'example/image.png');
}

void _testCodec(ImageCodec codec, String path) {
  final pngBytes = File(path).readAsBytesSync();

  print('version: ${codec.versionString()}');
  final s = codec.getHeader(pngBytes);

  print('size: ${s.width}x${s.height}');

  final rgb = codec.decode(pngBytes);
  print('rgb bytes: ${rgb.length}');

  final file2 = codec.encode(rgb, s.width, s.height);
  final filename = path.split('/').last;
  final ext = filename.split('.').last;
  final newPath = path.replaceAll(filename, 'roundtrip.$ext');
  File(newPath).writeAsBytesSync(file2);
  print('wrote: $newPath (${file2.length} bytes)');
}

void convertCodec(
  ImageCodec fromCodec,
  ImageCodec toCodec,
  String path, {
  PixelFormat pf = PixelFormat.rgba,
  Subsampling subsampling = Subsampling.s422,
  int quality = 90,
}) {
  final src = File(path).readAsBytesSync();

  // 1) Читаем заголовок только ради размеров
  final header = fromCodec.getHeader(src);

  // 2) Декодируем в заданный формат (единый для обоих шагов!)
  final pixels = fromCodec.decode(src, pixelFormat: pf);

  // 3) Кодируем, явно указывая тот же pixelFormat
  final out = toCodec.encode(
    pixels,
    header.width,
    header.height,
    pixelFormat: pf,
    subsampling: subsampling, // для PNG игнорируется, для WebP/JPEG работает
    quality: quality,
  );

  // 4) Имя файла: меняем расширение на целевое
  final filename = path.split('/').last;
  final stem = filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename;
  final targetExt = _extForCodec(toCodec); // ".jpg" / ".png" / ".webp"
  final newPath = path.replaceAll(filename, '$stem.converted$targetExt');

  File(newPath).writeAsBytesSync(out);
  print('wrote: $newPath (${out.length} bytes)');
}

String _extForCodec(ImageCodec c) {
  final name = c.runtimeType.toString().toLowerCase();
  if (name.contains('jpeg') || name.contains('turbojpeg')) return '.jpg';
  if (name.contains('png')) return '.png';
  if (name.contains('webp')) return '.webp';
  return '.bin';
}
