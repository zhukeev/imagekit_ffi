// import 'dart:io';
// import 'package:code_assets/code_assets.dart';
// import 'package:hooks/hooks.dart';
// import 'package:logging/logging.dart';
// import 'package:path/path.dart' as p;
// import 'package:archive/archive.dart';
// import 'package:archive/archive_io.dart';

// /// Base class for native library builders.
// /// Shares: download, tar.gz extraction, CMake build for macOS/iOS/Android,
// /// NDK/SKD auto-detection, process execution, simple fs helpers.
// abstract class LibBuilder {
//   LibBuilder(this.input, this.output, {required String logTag})
//     : logger = Logger(logTag)
//         ..onRecord.listen((r) {
//           print(r.message);
//           stdout.writeln(r.message);
//         });

//   final BuildInput input;
//   final BuildOutputBuilder output;
//   final Logger logger;

//   /// Entry point to perform the build. Subclasses implement details.
//   Future<void> runBuild();

//   /* ------------------------------ FS helpers ------------------------------ */

//   Future<void> copyTree(Directory from, Directory to) async {
//     for (final ent in from.listSync(recursive: true)) {
//       final rel = p.relative(ent.path, from: from.path);
//       final dst = p.join(to.path, rel);
//       if (ent is Directory) {
//         Directory(dst).createSync(recursive: true);
//       } else if (ent is File) {
//         File(dst).parent.createSync(recursive: true);
//         await ent.copy(dst);
//       }
//     }
//   }

//   /* ---------------------------- Networking/IO ----------------------------- */

//   Future<File> downloadTo(File dst, Uri url) async {
//     logger.info('Downloading $url → ${dst.path}');
//     dst.parent.createSync(recursive: true);
//     final client = HttpClient();
//     final req = await client.getUrl(url);
//     final res = await req.close();
//     if (res.statusCode != 200) {
//       throw StateError('Failed to download $url (HTTP ${res.statusCode}).');
//     }
//     final sink = dst.openWrite();
//     await res.pipe(sink);
//     await sink.close();
//     return dst;
//   }

//   /// Extracts a `.tar.gz` file into [outDir].
//   Future<void> extractTarGz(File tarGz, Directory outDir) async {
//     logger.info('Extracting ${tarGz.path} → ${outDir.path}');
//     final gzBytes = await tarGz.readAsBytes();
//     final tarBytes = GZipDecoder().decodeBytes(gzBytes);
//     final archive = TarDecoder().decodeBytes(tarBytes);
//     for (final file in archive) {
//       final outPath = p.join(outDir.path, file.name);
//       if (file.isFile) {
//         final f = File(outPath)..parent.createSync(recursive: true);
//         await f.writeAsBytes(file.content as List<int>);
//       } else {
//         Directory(outPath).createSync(recursive: true);
//       }
//     }
//   }

//   /* --------------------------------- CMake -------------------------------- */

//   Future<void> cmake(List<String> args) async {
//     logger.info('> cmake ${args.join(' ')}');
//     final r = await Process.run('cmake', args);
//     if (r.exitCode != 0) {
//       stderr.write(r.stdout);
//       stderr.write(r.stderr);
//       throw ProcessException(
//         'cmake',
//         args,
//         "Exit code: '${r.exitCode}'. See logs above.",
//         r.exitCode,
//       );
//     }
//     final out = (r.stdout ?? '').toString().trim();
//     if (out.isNotEmpty) logger.info(out);
//     final err = (r.stderr ?? '').toString().trim();
//     if (err.isNotEmpty) logger.info(err);
//   }

//   Future<String> runAndRead(
//     String exe,
//     List<String> args, {
//     String? cwd,
//     Map<String, String>? env,
//   }) async {
//     logger.info('> $exe ${args.join(' ')}');
//     final r = await Process.run(
//       exe,
//       args,
//       workingDirectory: cwd,
//       environment: env,
//     );
//     if (r.exitCode != 0) {
//       final msg = StringBuffer()
//         ..writeln('Process failed: $exe ${args.join(' ')}')
//         ..writeln('Exit code: ${r.exitCode}')
//         ..writeln('stdout:\n${r.stdout}')
//         ..writeln('stderr:\n${r.stderr}');
//       throw StateError(msg.toString());
//     }
//     final out = (r.stdout as String?)?.trim() ?? '';
//     final err = (r.stderr as String?)?.trim() ?? '';
//     if (out.isNotEmpty) return out;
//     if (err.isNotEmpty) return err;
//     return '';
//   }

//   /* --------------------------- Apple toolchains --------------------------- */

//   Future<Map<String, String>> buildMacStatic({
//     required String srcDir,
//     required Directory ws,
//     required String versionTag,
//     List<String> extraDefs = const [],
//   }) async {
//     final build = Directory(p.join(ws.path, 'build', 'macos-$versionTag'))
//       ..createSync(recursive: true);
//     final install = Directory(p.join(ws.path, 'install', 'macos-$versionTag'))
//       ..createSync(recursive: true);
//     final arch = input.config.code.targetArchitecture == Architecture.x64
//         ? 'x86_64'
//         : 'arm64';

//     await cmake([
//       '-S',
//       srcDir,
//       '-B',
//       build.path,
//       '-G',
//       'Ninja',
//       '-DCMAKE_BUILD_TYPE=Release',
//       '-DENABLE_SHARED=OFF',
//       '-DENABLE_STATIC=ON',
//       '-DCMAKE_POSITION_INDEPENDENT_CODE=ON',
//       '-DCMAKE_OSX_ARCHITECTURES=$arch',
//       '-DCMAKE_INSTALL_PREFIX=${install.path}',
//       ...extraDefs,
//     ]);
//     await cmake(['--build', build.path, '--target', 'install', '-j']);
//     return {
//       'include': p.join(install.path, 'include'),
//       'lib': p.join(install.path, 'lib'),
//     };
//     // (Note: some projects also install frameworks; link static .a for simplicity.)
//   }

//   Future<Map<String, String>> buildIOSStatic({
//     required String srcDir,
//     required Directory ws,
//     required String versionTag,
//     List<String> extraDefs = const [],
//   }) async {
//     final iosCfg = input.config.code.iOS;
//     final sdkType = iosCfg.targetSdk.type; // iphoneos | iphonesimulator
//     final arch = switch (input.config.code.targetArchitecture) {
//       Architecture.arm64 => 'arm64',
//       Architecture.x64 => 'x86_64',
//       _ => 'arm64',
//     };
//     final sdkPath = await runAndRead('xcrun', [
//       '--sdk',
//       sdkType,
//       '--show-sdk-path',
//     ]);
//     final minOs = '${iosCfg.targetVersion}.0';
//     final tag = '$sdkType-$arch-$versionTag';

//     final build = Directory(p.join(ws.path, 'build', 'ios-$tag'))
//       ..createSync(recursive: true);
//     final install = Directory(p.join(ws.path, 'install', 'ios-$tag'))
//       ..createSync(recursive: true);

//     await cmake([
//       '-S',
//       srcDir,
//       '-B',
//       build.path,
//       '-G',
//       'Ninja',
//       '-DCMAKE_SYSTEM_NAME=iOS',
//       '-DCMAKE_OSX_SYSROOT=$sdkPath',
//       '-DCMAKE_OSX_ARCHITECTURES=$arch',
//       '-DCMAKE_SYSTEM_PROCESSOR=$arch',
//       '-DCMAKE_OSX_DEPLOYMENT_TARGET=$minOs',
//       '-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY',
//       '-DENABLE_SHARED=OFF',
//       '-DENABLE_STATIC=ON',
//       '-DCMAKE_POSITION_INDEPENDENT_CODE=ON',
//       '-DCMAKE_BUILD_TYPE=Release',
//       '-DCMAKE_INSTALL_PREFIX=${install.path}',
//       ...extraDefs,
//     ]);
//     await cmake([
//       '--build',
//       build.path,
//       '--target',
//       'install',
//       '--config',
//       'Release',
//     ]);
//     return {
//       'include': p.join(install.path, 'include'),
//       'lib': p.join(install.path, 'lib'),
//     };
//   }

//   /* ---------------------------- Android toolchain --------------------------- */

//   String? autoFindAndroidNdk(String? sdkRoot) {
//     final env = Platform.environment;
//     final byEnv = env['ANDROID_NDK_HOME'] ?? env['ANDROID_NDK_ROOT'];
//     if (byEnv != null && Directory(byEnv).existsSync()) return byEnv;

//     final sdk = sdkRoot ?? env['ANDROID_SDK_ROOT'] ?? env['ANDROID_HOME'];
//     if (sdk != null) {
//       final sideBySide = Directory(p.join(sdk, 'ndk'));
//       if (sideBySide.existsSync()) {
//         final versions =
//             sideBySide
//                 .listSync()
//                 .whereType<Directory>()
//                 .map((d) => d.path)
//                 .toList()
//               ..sort();
//         if (versions.isNotEmpty) return versions.last;
//       }
//     }
//     return null;
//   }

//   String abiForAndroid(Architecture arch) {
//     return switch (arch) {
//       Architecture.arm64 => 'arm64-v8a',
//       Architecture.arm => 'armeabi-v7a',
//       Architecture.x64 => 'x86_64',
//       _ => throw UnsupportedError('Unsupported Android arch: $arch'),
//     };
//   }

//   Future<Map<String, String>> buildAndroidStatic({
//     required String srcDir,
//     required Directory ws,
//     required String versionTag,
//     required String? androidSdkRoot,
//     required String? androidNdkRoot,
//     List<String> extraDefs = const [],
//   }) async {
//     print('buildAndroidStatic: input.config  ${input.config.json}');

//     final cc =
//         (input.json['config']
//             as Map?)?['extensions']?['code_assets']?['c_compiler'];

//     final ccPath = (cc is Map) ? (cc['cc'] as String?) : null;
//     final arPath = (cc is Map) ? (cc['ar'] as String?) : null;
//     final ldPath = (cc is Map) ? (cc['ld'] as String?) : null;

//     final android = resolveAndroidPaths(
//       definesSdkRoot: androidSdkRoot,
//       definesNdkRoot: androidNdkRoot,
//       androidProjectDir: Directory('${input.packageRoot.path}/android'),
//       ccPath: ccPath,
//       arPath: arPath,
//       ldPath: ldPath,
//     );

//     if (android.ndkRoot == null) {
//       throw StateError(
//         'Android NDK not found. Set hooks.user_defines.<lib>.android.ndk_root '
//         'or export ANDROID_NDK_HOME / ANDROID_NDK_ROOT, or install side-by-side '
//         'NDK under ANDROID_SDK_ROOT/ndk/.',
//       );
//     }

//     final ndk = android.ndkRoot!;

//     final abi = abiForAndroid(input.config.code.targetArchitecture);
//     final api = 21;
//     final tag = '$abi-$versionTag';
//     final build = Directory(p.join(ws.path, 'build', 'android-$tag'))
//       ..createSync(recursive: true);
//     final install = Directory(p.join(ws.path, 'install', 'android-$tag'))
//       ..createSync(recursive: true);

//     await cmake([
//       '-S',
//       srcDir,
//       '-B',
//       build.path,
//       '-G',
//       'Ninja',
//       '-DCMAKE_TOOLCHAIN_FILE=${p.join(ndk, 'build', 'cmake', 'android.toolchain.cmake')}',
//       '-DANDROID_ABI=$abi',
//       '-DANDROID_PLATFORM=android-$api',
//       '-DANDROID_STL=c++_static',
//       '-DENABLE_SHARED=OFF',
//       '-DENABLE_STATIC=ON',
//       '-DCMAKE_POSITION_INDEPENDENT_CODE=ON',
//       '-DCMAKE_BUILD_TYPE=Release',
//       '-DCMAKE_INSTALL_PREFIX=${install.path}',
//       ...extraDefs,
//     ]);

//     await cmake(['--build', build.path, '--target', 'install', '-j']);
//     return {
//       'include': p.join(install.path, 'include'),
//       'lib': p.join(install.path, 'lib'),
//     };
//   }
// }

// class AndroidPaths {
//   final String? sdkRoot;
//   final String? ndkRoot;
//   AndroidPaths({this.sdkRoot, this.ndkRoot});
// }

// String? _ndkRootFromCompiler(String? compilerPath) {
//   if (compilerPath == null || compilerPath.isEmpty) return null;
//   final p = compilerPath.replaceAll('\\', '/');
//   final idx = p.indexOf('/toolchains/llvm/prebuilt/');
//   if (idx <= 0) return null;
//   return p.substring(0, idx);
// }

// String? _sdkRootFromNdk(String? ndkRoot) {
//   if (ndkRoot == null) return null;
//   final norm = ndkRoot.replaceAll('\\', '/');
//   final idx = norm.lastIndexOf('/ndk/');
//   if (idx <= 0) return null;
//   return norm.substring(0, idx);
// }

// /// Minimal .properties reader (key=value)
// Map<String, String> _readProperties(File file) {
//   final result = <String, String>{};
//   for (final raw in file.readAsLinesSync()) {
//     final line = raw.trim();
//     if (line.isEmpty || line.startsWith('#')) continue;
//     final eq = line.indexOf('=');
//     if (eq <= 0) continue;
//     result[line.substring(0, eq).trim()] = line.substring(eq + 1).trim();
//   }
//   return result;
// }

// String? _firstNonEmpty(List<String?> vals) {
//   for (final v in vals) {
//     if (v != null && v.trim().isNotEmpty) return v.trim();
//   }
//   return null;
// }

// String? _normDir(String? p) {
//   if (p == null) return null;
//   final s = p.trim();
//   if (s.isEmpty) return null;
//   return s.replaceAll(r'\\', '/');
// }

// String _versionKey(String v) =>
//     v.split('.').map((p) => p.padLeft(10, '0')).join('.');

// String? _pickHighestNdkUnderSdk(String sdkRoot) {
//   final ndkParent = Directory('$sdkRoot/ndk');
//   if (!ndkParent.existsSync()) return null;
//   final dirs = ndkParent
//       .listSync()
//       .whereType<Directory>()
//       .map((d) => d.path.replaceAll('\\', '/'))
//       .toList();
//   if (dirs.isEmpty) return null;
//   dirs.sort((a, b) {
//     final va = a.split('/').last;
//     final vb = b.split('/').last;
//     return _versionKey(vb).compareTo(_versionKey(va));
//   });
//   return dirs.first;
// }

// /// Unified resolver with extra fallback from compiler tool paths.
// AndroidPaths resolveAndroidPaths({
//   // user_defines.<lib>.android.*
//   String? definesSdkRoot,
//   String? definesNdkRoot,

//   // read android/local.properties
//   Directory? androidProjectDir,

//   // NEW: tool paths from hooks input.config.extensions.code_assets.c_compiler
//   String? ccPath,
//   String? arPath,
//   String? ldPath,
// }) {
//   String? sdkRoot = _normDir(definesSdkRoot);
//   String? ndkRoot = _normDir(definesNdkRoot);

//   // 1) env
//   final env = Platform.environment;
//   ndkRoot ??= _normDir(
//     _firstNonEmpty([
//       env['ANDROID_NDK_HOME'],
//       env['ANDROID_NDK_ROOT'],
//       env['NDK_HOME'],
//     ]),
//   );
//   sdkRoot ??= _normDir(
//     _firstNonEmpty([env['ANDROID_SDK_ROOT'], env['ANDROID_HOME']]),
//   );

//   // 2) local.properties
//   if (androidProjectDir != null && androidProjectDir.existsSync()) {
//     final lp = File('${androidProjectDir.path}/local.properties');
//     if (lp.existsSync()) {
//       final props = _readProperties(lp);
//       sdkRoot ??= _normDir(props['sdk.dir']);
//       ndkRoot ??= _normDir(props['ndk.dir']);
//       final ndkVersion = _firstNonEmpty([
//         props['ndkVersion'],
//         props['ndk.version'],
//       ]);
//       if ((ndkRoot == null || ndkRoot.isEmpty) &&
//           sdkRoot != null &&
//           ndkVersion != null) {
//         final candidate = Directory('$sdkRoot/ndk/$ndkVersion');
//         if (candidate.existsSync()) ndkRoot = candidate.path;
//       }
//     }
//   }

//   // 3) NEW: derive from compiler paths (provided by hooks toolchain)
//   ndkRoot ??=
//       _ndkRootFromCompiler(ccPath) ??
//       _ndkRootFromCompiler(arPath) ??
//       _ndkRootFromCompiler(ldPath);

//   // If we got NDK, derive SDK (if missing)
//   sdkRoot ??= _sdkRootFromNdk(ndkRoot);

//   // 4) Side-by-side fallback under <sdk>/ndk (pick highest)
//   if ((ndkRoot == null || ndkRoot.isEmpty) && sdkRoot != null) {
//     ndkRoot = _pickHighestNdkUnderSdk(sdkRoot);
//   }

//   return AndroidPaths(sdkRoot: sdkRoot, ndkRoot: ndkRoot);
// }
