import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import '../defines/webp_defines.dart';
import 'lib_builder.dart';

const _logTag = 'webp';

final class WebpBuild extends LibBuilder {
  WebpBuild(super.input, super.output) : defines = WebpDefines.fromHooks(input), super(logTag: _logTag);

  final WebpDefines defines;

  @override
  Future<void> runBuild() async {
    logger.info('$_logTag: build start → ${input.config.code.targetOS}');
    logger.info('$_logTag: version ${defines.version}');
    logger.info('$_logTag: tarballUri ${defines.tarballUri}');
    logger.info('$_logTag: downloadUrl ${defines.downloadUrl}');

    final ws = Directory(p.join(input.packageRoot.path, '.dart_tool', 'native_build', 'webp'))
      ..createSync(recursive: true);

    final srcDir = await _stageSources(ws);

    Map<String, String> built = {};
    final extraDefs = <String>[
      '-DBUILD_SHARED_LIBS=OFF',
      '-DWEBP_BUILD_CWEBP=OFF',
      '-DWEBP_BUILD_DWEBP=OFF',
      '-DWEBP_BUILD_GIF2WEBP=OFF',
      '-DWEBP_BUILD_IMG2WEBP=OFF',
      '-DWEBP_BUILD_VWEBP=OFF',
      '-DWEBP_BUILD_WEBPINFO=OFF',
      '-DWEBP_BUILD_WEBPMUX=OFF',
      '-DWEBP_BUILD_ANIM_UTILS=OFF',
    ];

    switch (input.config.code.targetOS) {
      case OS.macOS:
        built = await buildMacStatic(srcDir: srcDir, ws: ws, versionTag: defines.version, extraDefs: extraDefs);
        break;
      case OS.iOS:
        built = await buildIOSStatic(srcDir: srcDir, ws: ws, versionTag: defines.version, extraDefs: extraDefs);
        break;
      case OS.linux:
        built = await buildLinuxStatic(srcDir: srcDir, ws: ws, versionTag: defines.version);
        break;
      case OS.windows:
        built = await buildWindowsStatic(srcDir: srcDir, ws: ws, versionTag: defines.version);
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
    final localIncDir = Directory(p.join(input.packageRoot.path, 'native', 'webp'));
    if (localIncDir.existsSync()) includePaths.add(localIncDir.path);

    final libraryDirs = <String>[built['lib']!];

    // Build our shim that links to static libwebp.
    // On some platforms libsharpyuv is separate; add it if present.
    final libs = <String>['webp', 'sharpyuv'];

    if (input.config.code.targetOS == OS.android || input.config.code.targetOS == OS.linux) {
      // pow() живёт в libm
      libs.add('m');
    }

    final cb = CBuilder.library(
      name: '${input.packageName}_webp',
      assetName: 'src/webp/webp.dart',
      sources: [p.join('native', 'webp', 'ik_webp.c')],
      includes: includePaths,
      libraries: libs,
      libraryDirectories: libraryDirs,
      linkModePreference: LinkModePreference.dynamic,
    );

    await cb.run(input: input, output: output, logger: Logger(_logTag));
    logger.info('$_logTag: native build DONE → ${input.config.code.targetOS}');
  }

  Future<String> _stageSources(Directory ws) async {
    final srcRoot = Directory(p.join(ws.path, 'src'))..createSync(recursive: true);
    final dst = Directory(p.join(srcRoot.path, 'libwebp-${defines.version}'));
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
    final cache = Directory(p.join(ws.path, 'cache'))..createSync(recursive: true);
    final tar = File(p.join(cache.path, 'libwebp-${defines.version}.tar.gz'));
    await downloadTo(tar, url);
    await extractTarGz(tar, srcRoot);

    final extractedTop = Directory(
      srcRoot.path,
    ).listSync().whereType<Directory>().firstWhere((d) => p.basename(d.path).startsWith('libwebp-'));
    if (extractedTop.path != dst.path) {
      await extractedTop.rename(dst.path);
    }
    logger.info('Sources staged → ${dst.path}');
    return dst.path;
  }
}
