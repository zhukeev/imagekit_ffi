import 'package:hooks/hooks.dart';
import 'defines.dart';

const _kDefaultTJVersion = '3.1.2';

class TJDefines extends LibDefines {
  TJDefines._({
    required super.version,
    required super.source,
    required super.defaultUrlBuilder,
    required super.enabled,
    required super.skipPlatforms,
    super.androidSdkRoot,
    super.androidNdkRoot,
    super.tarballUri,
  }) : super();

  factory TJDefines.fromHooks(BuildInput input) {
    final root = LibDefines.resolveCodecBlock(input, 'turbo_jpeg');

    final verRaw = (root['version'] as String?)?.trim();
    final version = (verRaw != null && verRaw.isNotEmpty) ? verRaw : _kDefaultTJVersion;

    final tarballUriRaw = (root['tarball_uri'] as String?)?.trim();
    final tarballUri = (tarballUriRaw != null && tarballUriRaw.isNotEmpty) ? tarballUriRaw : null;

    final srcMap = LibDefines.stringKeyMap(root['source']);
    final source = srcMap.isNotEmpty
        ? LibDefines.parseSource(srcMap, ctxKey: 'turbo_jpeg')
        : LibSource.download(
            url:
                'https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$version/libjpeg-turbo-$version.tar.gz',
          );

    final android = LibDefines.stringKeyMap(root['android']);
    final sdkRoot = (android['sdk_root'] as String?)?.trim();
    final ndkRoot = (android['ndk_root'] as String?)?.trim();

    final enabled = (root['enabled'] as bool?) ?? true;

    final skipPlatforms = LibDefines.parseSkipPlatforms(root);

    return TJDefines._(
      version: version,
      source: source,
      defaultUrlBuilder: (v) =>
          'https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$v/libjpeg-turbo-$v.tar.gz',
      androidSdkRoot: (sdkRoot?.isEmpty ?? true) ? null : sdkRoot,
      androidNdkRoot: (ndkRoot?.isEmpty ?? true) ? null : ndkRoot,
      tarballUri: tarballUri,
      enabled: enabled,
      skipPlatforms: skipPlatforms,
    );
  }
}
