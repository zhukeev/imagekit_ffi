import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import '../defines/png_defines.dart';
import 'lib_builder.dart';

const _logTag = 'libpng';
const _zlibVersion = '1.3.1';
const _zlibUrl = 'https://zlib.net/zlib-$_zlibVersion.tar.gz';

final class PngBuild extends LibBuilder {
  PngBuild(super.input, super.output) : defines = PngDefines.fromHooks(input), super(logTag: _logTag);

  final PngDefines defines;

  @override
  Future<void> runBuild() async {
    logger.info('$_logTag: build start → ${input.config.code.targetOS}');
    logger.info('$_logTag: version ${defines.version}');
    logger.info('$_logTag: tarballUri ${defines.tarballUri}');
    logger.info('$_logTag: downloadUrl ${defines.downloadUrl}');

    final packageRootPath = p.fromUri(input.packageRoot);
    final ws = Directory(p.join(packageRootPath, '.dart_tool', 'native_build', 'libpng'))..createSync(recursive: true);

    // Build zlib first (required dependency for libpng)
    final zlibPaths = await _buildZlib(ws);

    final srcDir = await _stageSources(ws);

    Map<String, String> built = {};
    // Base CMake options for libpng (no PNG_BUILD_ZLIB - deprecated)
    final extraDefs = <String>[
      '-DPNG_SHARED=OFF',
      '-DPNG_STATIC=ON',
      '-DPNG_TESTS=OFF',
      // Point to our built zlib
      '-DZLIB_ROOT=${zlibPaths['root']}',
      '-DZLIB_INCLUDE_DIR=${zlibPaths['include']}',
      '-DZLIB_LIBRARY=${zlibPaths['lib']}',
    ];

    switch (input.config.code.targetOS) {
      case OS.macOS:
        built = await buildMacStatic(srcDir: srcDir, ws: ws, versionTag: defines.version, extraDefs: extraDefs);
        break;
      case OS.linux:
        built = await buildLinuxStatic(srcDir: srcDir, ws: ws, versionTag: defines.version, extraDefs: extraDefs);
        break;
      case OS.windows:
        built = await buildWindowsStatic(srcDir: srcDir, ws: ws, versionTag: defines.version, extraDefs: extraDefs);
        break;
      case OS.iOS:
        built = await buildIOSStatic(srcDir: srcDir, ws: ws, versionTag: defines.version, extraDefs: extraDefs);
        break;
      case OS.android:
        built = await buildAndroidStatic(
          srcDir: srcDir,
          ws: ws,
          versionTag: defines.version,
          androidSdkRoot: defines.androidSdkRoot,
          androidNdkRoot: defines.androidNdkRoot,
          extraDefs: extraDefs,
        );
        break;
      default:
        throw UnsupportedError('Unsupported OS: ${input.config.code.targetOS}');
    }

    final includePaths = <String>[built['include']!];
    final localIncDir = Directory(p.join(packageRootPath, 'native', 'png'));
    if (localIncDir.existsSync()) includePaths.add(localIncDir.path);

    // Add zlib include/lib directories for linking
    final libraryDirs = <String>[built['lib']!, zlibPaths['libDir']!];
    includePaths.add(zlibPaths['include']!);

    // On Windows with MSVC, the library is named 'zlibstatic', on other platforms it's 'z'
    final zlibName = input.config.code.targetOS == OS.windows ? 'zlibstatic' : 'z';
    // On Windows with MSVC, libpng static is named 'libpng16_static', on other platforms it's 'png16' or 'png'
    final pngName = input.config.code.targetOS == OS.windows ? 'libpng16_static' : 'png';

    // On Windows, we need to use static CRT (/MT) to match the static libs
    // and link against libucrt.lib and libvcruntime.lib for CRT functions
    final windowsFlags = <String>['/MT'];
    final windowsLibs = <String>[pngName, zlibName, 'libucrt', 'libvcruntime'];

    // Build our shim that links to static libpng (and zlib).
    final cb = CBuilder.library(
      name: '${input.packageName}_png',
      assetName: 'src/png/png_kit.dart',
      sources: [p.join('native', 'png', 'ik_png.c')],
      includes: includePaths,
      libraries: input.config.code.targetOS == OS.windows ? windowsLibs : [pngName, zlibName],
      libraryDirectories: libraryDirs,
      linkModePreference: LinkModePreference.dynamic,
      flags: input.config.code.targetOS == OS.windows ? windowsFlags : [],
    );

    await cb.run(input: input, output: output, logger: Logger(_logTag));
    logger.info('$_logTag: native build DONE → ${input.config.code.targetOS}');
  }

  Future<String> _stageSources(Directory ws) async {
    final srcRoot = Directory(p.join(ws.path, 'src'))..createSync(recursive: true);
    final dst = Directory(p.join(srcRoot.path, 'libpng-${defines.version}'));
    if (dst.existsSync()) return dst.path;

    if (defines.vendoredPath != null) {
      final from = Directory(defines.vendoredPath!);
      if (!from.existsSync()) {
        throw StateError('Vendored path not found: ${from.path}');
      }
      logger.info('Using vendored sources at ${from.path}');
      await copyTree(from, dst);
      return dst.path;
    }

    final url = Uri.parse(defines.downloadUrl);
    final tmpTar = File(p.join(ws.path, 'cache', 'libpng-${defines.version}.tar.gz'));
    await downloadTo(tmpTar, url);
    await extractTarGz(tmpTar, Directory(p.join(ws.path, 'src')));

    // Normalize extracted dirname
    final extractedTop = Directory(
      srcRoot.path,
    ).listSync().whereType<Directory>().firstWhere((d) => p.basename(d.path).startsWith('libpng-'));
    if (extractedTop.path != dst.path) {
      await extractedTop.rename(dst.path);
    }
    logger.info('Sources staged → ${dst.path}');
    return dst.path;
  }

  /// Build zlib as a dependency for libpng
  Future<Map<String, String>> _buildZlib(Directory ws) async {
    logger.info('$_logTag: building zlib $_zlibVersion');

    final zlibWs = Directory(p.join(ws.path, 'zlib'))..createSync(recursive: true);

    // Download zlib sources if not already present
    final zlibSrcDir = await _stageZlibSources(zlibWs);

    final os = input.config.code.targetOS;
    final arch = input.config.code.targetArchitecture;

    // Determine platform tag
    final platformTag = switch (os) {
      OS.windows => 'windows-${arch == Architecture.x64 ? 'x64' : arch.toString()}',
      OS.macOS => 'macos-${arch == Architecture.arm64 ? 'arm64' : 'x86_64'}',
      OS.linux => 'linux-${arch == Architecture.x64 ? 'x86_64' : arch.toString()}',
      OS.iOS => 'ios-${arch == Architecture.arm64 ? 'arm64' : 'x86_64'}',
      OS.android => 'android-${abiForAndroid(arch)}',
      _ => 'unknown',
    };

    final installDir = Directory(p.join(zlibWs.path, 'install', '$platformTag-$_zlibVersion'));

    // Check if already built
    final libDir = Directory(p.join(installDir.path, 'lib'));
    if (libDir.existsSync()) {
      logger.info('$_logTag: zlib already built at ${installDir.path}');
      return _zlibPaths(installDir.path, os);
    }

    installDir.createSync(recursive: true);

    // Build zlib with same approach as other libraries
    final extraDefs = <String>[
      '-DZLIB_BUILD_EXAMPLES=OFF',
    ];

    switch (os) {
      case OS.windows:
        await buildWindowsStatic(srcDir: zlibSrcDir, ws: zlibWs, versionTag: _zlibVersion, extraDefs: extraDefs);
        break;
      case OS.macOS:
        await buildMacStatic(srcDir: zlibSrcDir, ws: zlibWs, versionTag: _zlibVersion, extraDefs: extraDefs);
        break;
      case OS.linux:
        await buildLinuxStatic(srcDir: zlibSrcDir, ws: zlibWs, versionTag: _zlibVersion, extraDefs: extraDefs);
        break;
      case OS.iOS:
        await buildIOSStatic(srcDir: zlibSrcDir, ws: zlibWs, versionTag: _zlibVersion, extraDefs: extraDefs);
        break;
      case OS.android:
        await buildAndroidStatic(
          srcDir: zlibSrcDir,
          ws: zlibWs,
          versionTag: _zlibVersion,
          androidSdkRoot: defines.androidSdkRoot,
          androidNdkRoot: defines.androidNdkRoot,
          extraDefs: extraDefs,
        );
        break;
      default:
        throw UnsupportedError('Unsupported OS: $os');
    }

    // Find the actual install directory created by buildXXXStatic
    final actualInstallDir = Directory(p.join(zlibWs.path, 'install'))
        .listSync()
        .whereType<Directory>()
        .firstWhere((d) => p.basename(d.path).contains(_zlibVersion));

    logger.info('$_logTag: zlib built at ${actualInstallDir.path}');
    return _zlibPaths(actualInstallDir.path, os);
  }

  Map<String, String> _zlibPaths(String installPath, OS os) {
    final libDir = p.join(installPath, 'lib');
    final includeDir = p.join(installPath, 'include');

    // Find the actual library file
    String libPath;
    if (os == OS.windows) {
      // On Windows with MSVC, zlib creates 'zlibstatic.lib'
      libPath = p.join(libDir, 'zlibstatic.lib');
      if (!File(libPath).existsSync()) {
        // Try alternative names
        libPath = p.join(libDir, 'zlib.lib');
      }
    } else {
      libPath = p.join(libDir, 'libz.a');
    }

    return {
      'root': installPath,
      'include': includeDir,
      'lib': libPath,
      'libDir': libDir,
    };
  }

  Future<String> _stageZlibSources(Directory ws) async {
    final srcRoot = Directory(p.join(ws.path, 'src'))..createSync(recursive: true);
    final dst = Directory(p.join(srcRoot.path, 'zlib-$_zlibVersion'));
    if (dst.existsSync()) return dst.path;

    final url = Uri.parse(_zlibUrl);
    final cacheDir = Directory(p.join(ws.path, 'cache'))..createSync(recursive: true);
    final tmpTar = File(p.join(cacheDir.path, 'zlib-$_zlibVersion.tar.gz'));

    if (!tmpTar.existsSync()) {
      await downloadTo(tmpTar, url);
    }
    await extractTarGz(tmpTar, srcRoot);

    logger.info('$_logTag: zlib sources staged → ${dst.path}');
    return dst.path;
  }
}
