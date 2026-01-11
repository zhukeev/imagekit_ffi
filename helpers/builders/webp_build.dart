import 'dart:io';

import 'package:code_assets/code_assets.dart';
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

    final packageRootPath = p.fromUri(input.packageRoot);
    final ws = Directory(p.join(packageRootPath, '.dart_tool', 'native_build', 'webp'))..createSync(recursive: true);

    final srcDir = await _stageSources(ws);
    final version = defines.version;

    final Map<String, String> paths;
    final os = input.config.code.targetOS;

    final extraDefs = [
      '-DWEBP_BUILD_ANIM_UTILS=OFF',
      '-DWEBP_BUILD_CWEBP=OFF',
      '-DWEBP_BUILD_DWEBP=OFF',
      '-DWEBP_BUILD_GIF2WEBP=OFF',
      '-DWEBP_BUILD_IMG2WEBP=OFF',
      '-DWEBP_BUILD_VWEBP=OFF',
      '-DWEBP_BUILD_WEBPINFO=OFF',
      '-DWEBP_BUILD_WEBPMUX=OFF',
      '-DWEBP_BUILD_EXTRAS=OFF',
    ];

    if (os == OS.windows) {
      paths = await buildWindowsStatic(srcDir: srcDir, ws: ws, versionTag: version, extraDefs: extraDefs);
    } else if (os == OS.macOS) {
      paths = await buildMacStatic(srcDir: srcDir, ws: ws, versionTag: version, extraDefs: extraDefs);
    } else if (os == OS.linux) {
      paths = await buildLinuxStatic(srcDir: srcDir, ws: ws, versionTag: version, extraDefs: extraDefs);
    } else if (os == OS.iOS) {
      paths = await buildIOSStatic(srcDir: srcDir, ws: ws, versionTag: version, extraDefs: extraDefs);
    } else if (os == OS.android) {
      paths = await buildAndroidStatic(
        srcDir: srcDir,
        ws: ws,
        versionTag: version,
        androidSdkRoot: defines.androidSdkRoot,
        androidNdkRoot: defines.androidNdkRoot,
        extraDefs: extraDefs,
      );
    } else {
      throw UnsupportedError('Unsupported OS: $os');
    }

    final includeDir = paths['include']!;
    final libDir = paths['lib']!;
    final nativeSrc = p.join(packageRootPath, 'native', 'webp');

    if (Platform.isWindows) {
      await _buildGlueDllWindows(nativeSrc: nativeSrc, includeDir: includeDir, libDir: libDir);
    } else {
      await _buildGlueDllCBuilder(nativeSrc: nativeSrc, includeDir: includeDir, libDir: libDir);
    }
  }

  /// Build glue DLL on Windows using cl.exe directly with VS environment
  Future<void> _buildGlueDllWindows({
    required String nativeSrc,
    required String includeDir,
    required String libDir,
  }) async {
    final env = await getVsEnvironment();

    final packageRootPath = p.fromUri(input.packageRoot);
    final outDir = Directory(p.join(packageRootPath, '.dart_tool', 'native_build', 'webp', 'out'))
      ..createSync(recursive: true);

    final dllName = 'imagekit_ffi_webp.dll';
    final dllPath = p.join(outDir.path, dllName);
    final srcFile = p.join(nativeSrc, 'ik_webp.c');

    final args = [
      '/O2',
      '/DRELEASE',
      '/DNDEBUG',
      '/MD',  // Use dynamic CRT (matches how libwebp was built)
      '/I$includeDir',
      '/I$nativeSrc',
      '/LD',
      '/Fe:$dllPath',
      srcFile,
      '/link',
      '/MACHINE:X64',
      '/LIBPATH:$libDir',
      'libwebp.lib', // Changed from webp.lib
      'libsharpyuv.lib', // Changed from sharpyuv.lib
      // Add required Windows/CRT libraries
      'libcmt.lib', // C runtime (static)
      'libvcruntime.lib', // VC runtime
      'libucrt.lib', // Universal CRT
      '/NODEFAULTLIB:msvcrt.lib', // Avoid CRT conflicts
    ];

    logger.info('Building Windows DLL with cl.exe');
    logger.info('> cl.exe ${args.join(' ')}');

    final result = await Process.run('cl.exe', args, environment: env, workingDirectory: outDir.path);

    if (result.exitCode != 0) {
      logger.severe('cl.exe stdout: ${result.stdout}');
      logger.severe('cl.exe stderr: ${result.stderr}');
      throw Exception('Failed to compile webp glue DLL: exit code ${result.exitCode}');
    }

    logger.info('Built: $dllPath');

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'src/webp/webp.dart',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file(dllPath),
      ),
    );

    output.addDependency(Uri.file(srcFile));
  }

  /// Build glue DLL on non-Windows using CBuilder
  Future<void> _buildGlueDllCBuilder({
    required String nativeSrc,
    required String includeDir,
    required String libDir,
  }) async {
    final cbuilder = CBuilder.library(
      name: 'imagekit_ffi_webp',
      assetName: 'src/webp/webp.dart',
      sources: [p.join(nativeSrc, 'ik_webp.c')],
      includes: [includeDir, nativeSrc],
      flags: ['-O2', '-DRELEASE', '-DNDEBUG', '-L$libDir', '-lwebp', '-lsharpyuv'],
    );

    await cbuilder.run(input: input, output: output, logger: logger);
  }

  Future<String> _stageSources(Directory ws) async {
    final version = defines.version;
    final cacheDir = Directory(p.join(ws.path, 'cache'))..createSync(recursive: true);
    final tarball = File(p.join(cacheDir.path, 'libwebp-$version.tar.gz'));

    if (!tarball.existsSync()) {
      final url = defines.tarballUri ?? defines.downloadUrl;
      await downloadTo(tarball, Uri.parse(url));
    }

    final srcDir = Directory(p.join(ws.path, 'src'));
    final webpSrcDir = Directory(p.join(srcDir.path, 'libwebp-$version'));

    if (!webpSrcDir.existsSync()) {
      await extractTarGz(tarball, srcDir);
    }

    logger.info('Sources staged → ${webpSrcDir.path}');
    return webpSrcDir.path;
  }
}
