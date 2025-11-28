import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as cstr;
import 'package:imagekit_ffi/src/core/imagekit_core.dart' show ImageCodec;

import 'dart:io' as io;
import 'package:path/path.dart' as p;

/// Load native module built by hooks, e.g. module='webp' => libimagekit_ffi_webp.{dylib|so|dll}
ffi.DynamicLibrary loadImageKitLib(String module, {String package = 'imagekit_ffi'}) {
  final base = '${package}_$module';

  final file = _platName(base);

  // 0) explicit override for local dev: export IMAGEKIT_LIB_DIR=/abs/path/to/dir
  final envDir = io.Platform.environment['IMAGEKIT_LIB_DIR'];
  if (envDir != null && envDir.isNotEmpty) {
    final cand = p.join(envDir, file);
    try {
      return ffi.DynamicLibrary.open(cand);
    } catch (_) {}
  }

  // 1) plain name (works if dir on loader path)
  try {
    return ffi.DynamicLibrary.open(file);
  } catch (_) {}

  // 2) search common hooks output locations
  final roots = _probeRoots();
  final candidates = <String>[];

  // .dart_tool/hooks_runner/shared/<pkg>/build/**/<file>
  for (final r in roots) {
    final shared = p.join(r, '.dart_tool', 'hooks_runner', 'shared', package, 'build');
    final d = io.Directory(shared);
    if (d.existsSync()) {
      for (final ent in d.listSync(recursive: true, followLinks: false)) {
        if (ent is io.File && p.basename(ent.path) == file) {
          candidates.add(ent.path);
        }
      }
    }
  }

  // also check per-run (non-shared) build dirs, and native_build fallbacks
  for (final r in roots) {
    final hr = p.join(r, '.dart_tool', 'hooks_runner');
    final nb = p.join(r, '.dart_tool', 'native_build');
    for (final ent in [hr, nb]) {
      final dir = io.Directory(ent);
      if (!dir.existsSync()) continue;
      for (final f in dir.listSync(recursive: true, followLinks: false)) {
        if (f is io.File && p.basename(f.path) == file) {
          candidates.add(f.path);
        }
      }
    }
  }

  for (final c in candidates) {
    try {
      return ffi.DynamicLibrary.open(c);
    } catch (_) {}
  }

  // 3) iOS can be linked into the process image
  if (io.Platform.isIOS) {
    return ffi.DynamicLibrary.process();
  }

  throw ArgumentError(
    'Failed to load $file. Checked: '
    '${[if (envDir != null) p.join(envDir, file), ...candidates].join(' | ')}',
  );
}

String _platName(String base) {
  if (io.Platform.isWindows) return '$base.dll';
  if (io.Platform.isLinux || io.Platform.isAndroid) return 'lib$base.so';
  // macOS/iOS:
  return 'lib$base.dylib';
}

Iterable<String> _probeRoots() sync* {
  // CWD
  yield io.Directory.current.path;

  // Walk up a few levels from the running script location
  try {
    var dir = io.Directory.fromUri(Uri.base).absolute;
    for (var i = 0; i < 8; i++) {
      yield dir.path;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  } catch (_) {}
}

mixin FfiHelpers on ImageCodec {
  ffi.Pointer<ffi.Uint8> allocBuf([int? cap]) => cstr.calloc<ffi.Uint8>(cap ?? errCap);

  ffi.Pointer<ffi.Uint8> copyToNative(Uint8List data, {int? len}) {
    final n = len ?? data.length;
    if (n > data.length) {
      throw ArgumentError('Requested length $n exceeds source length ${data.length}');
    }
    final p = cstr.calloc<ffi.Uint8>(n);
    p.asTypedList(n).setRange(0, n, data);
    return p;
  }

  String readCString(ffi.Pointer<ffi.Uint8> p) => p.cast<cstr.Utf8>().toDartString();

  void freeAll(Iterable<ffi.Pointer<ffi.NativeType>> ptrs) {
    for (final p in ptrs) {
      if (p != ffi.nullptr) cstr.calloc.free(p);
    }
  }
}
