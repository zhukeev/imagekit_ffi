import 'package:hooks/hooks.dart';
import 'defines.dart';

const _kDefaultPngVersion = '1.6.43';

class PngDefines extends LibDefines {
  PngDefines._({
    required super.version,
    required super.source,
    required super.defaultUrlBuilder,
    required super.enabled,
    required super.skipPlatforms,
    super.androidSdkRoot,
    super.androidNdkRoot,
    super.tarballUri,
  }) : super();

  factory PngDefines.fromHooks(BuildInput input) {
    final root = LibDefines.resolveCodecBlock(input, 'libpng');

    final verRaw = (root['version'] as String?)?.trim();
    final version = (verRaw != null && verRaw.isNotEmpty) ? verRaw : _kDefaultPngVersion;

    final tarballUriRaw = (root['tarball_uri'] as String?)?.trim();
    final tarballUri = (tarballUriRaw != null && tarballUriRaw.isNotEmpty) ? tarballUriRaw : null;

    final srcMap = LibDefines.stringKeyMap(root['source']);
    LibSource source = srcMap.isNotEmpty
        ? LibDefines.parseSource(srcMap, ctxKey: 'libpng')
        : LibSource.download(url: 'https://download.sourceforge.net/libpng/libpng-$version.tar.gz');

    final android = LibDefines.stringKeyMap(root['android']);
    final sdkRoot = (android['sdk_root'] as String?)?.trim();
    final ndkRoot = (android['ndk_root'] as String?)?.trim();
    final enabled = (root['enabled'] as bool?) ?? true;

    final skipPlatforms = LibDefines.parseSkipPlatforms(root);

    return PngDefines._(
      version: version,
      source: source,
      defaultUrlBuilder: (v) => 'https://download.sourceforge.net/libpng/libpng-$v.tar.gz',
      androidSdkRoot: (sdkRoot?.isEmpty ?? true) ? null : sdkRoot,
      androidNdkRoot: (ndkRoot?.isEmpty ?? true) ? null : ndkRoot,
      tarballUri: tarballUri,
      enabled: enabled,
      skipPlatforms: skipPlatforms,
    );
  }
}
