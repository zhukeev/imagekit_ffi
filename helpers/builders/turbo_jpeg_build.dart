import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import 'lib_builder.dart';
import '../defines/tj_defines.dart';

const _logTag = 'turbo_jpeg';

final class TurboJpegBuild extends LibBuilder {
  TurboJpegBuild(super.input, super.output) : defines = TJDefines.fromHooks(input), super(logTag: _logTag);

  final TJDefines defines;

  @override
  Future<void> runBuild() async {
    logger.info('$_logTag: build start → ${input.config.code.targetOS}');
    logger.info('$_logTag: version ${defines.version}');
    logger.info('$_logTag: downloadUrl ${defines.downloadUrl}');

    final ws = Directory(p.join(input.packageRoot.path, '.dart_tool', 'native_build', 'turbo_jpeg'))
      ..createSync(recursive: true);

    final srcDir = await _stageSources(ws);

    Map<String, String> built = {};
    switch (input.config.code.targetOS) {
      case OS.macOS:
        built = await buildMacStatic(srcDir: srcDir, ws: ws, versionTag: defines.version);
        break;
      case OS.linux:
        built = await buildLinuxStatic(srcDir: srcDir, ws: ws, versionTag: defines.version);
        break;
      case OS.windows:
        built = await buildWindowsStatic(srcDir: srcDir, ws: ws, versionTag: defines.version);
        break;
      case OS.iOS:
        built = await buildIOSStatic(srcDir: srcDir, ws: ws, versionTag: defines.version);
        break;
      case OS.android:
        built = await buildAndroidStatic(
          srcDir: srcDir,
          ws: ws,
          versionTag: defines.version,
          androidSdkRoot: defines.androidSdkRoot,
          androidNdkRoot: defines.androidNdkRoot,
        );
        break;
      default:
        throw UnsupportedError('Unsupported OS: ${input.config.code.targetOS}');
    }

    final includePaths = <String>[built['include']!];
    final localIncDir = Directory(p.join(input.packageRoot.path, 'native', 'jpeg'));
    if (localIncDir.existsSync()) includePaths.add(localIncDir.path);

    final libraryDirs = <String>[built['lib']!];

    final cb = CBuilder.library(
      name: '${input.packageName}_turbo_jpeg',
      assetName: 'src/jpeg/turbo_jpeg.dart',
      sources: [p.join('native', 'jpeg', 'turbo_jpeg.c')],
      includes: includePaths,
      libraries: const ['turbojpeg'],
      libraryDirectories: libraryDirs,
      linkModePreference: LinkModePreference.dynamic,
    );

    await cb.run(input: input, output: output, logger: Logger(_logTag));
    logger.info('$_logTag: native build DONE → ${input.config.code.targetOS}');
  }

  Future<String> _stageSources(Directory ws) async {
    final srcRoot = Directory(p.join(ws.path, 'src'))..createSync(recursive: true);
    final dst = Directory(p.join(srcRoot.path, 'libjpeg-turbo-${defines.version}'));
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
    final tmpTar = File(p.join(ws.path, 'cache', 'libjpeg-turbo-${defines.version}.tar.gz'));
    await downloadTo(tmpTar, url);
    await extractTarGz(tmpTar, Directory(p.join(ws.path, 'src')));

    // Normalize extracted dirname
    final extractedTop = Directory(
      srcRoot.path,
    ).listSync().whereType<Directory>().firstWhere((d) => p.basename(d.path).startsWith('libjpeg-turbo-'));
    if (extractedTop.path != dst.path) {
      await extractedTop.rename(dst.path);
    }
    logger.info('Sources staged → ${dst.path}');
    return dst.path;
  }
}
