import 'package:hooks/hooks.dart';
import 'defines.dart';

const _kDefaultWebpVersion = '1.4.0';

final class WebpDefines extends LibDefines {
  WebpDefines._({
    required super.version,
    required super.source,
    required super.defaultUrlBuilder,
    required super.enabled,
    super.androidSdkRoot,
    super.androidNdkRoot,
    super.tarballUri,
  }) : super();

  factory WebpDefines.fromHooks(BuildInput input) {
    final root = LibDefines.resolveCodecBlock(input, 'webp');

    final verRaw = (root['version'] as String?)?.trim();
    final version = (verRaw == null || verRaw.isEmpty) ? _kDefaultWebpVersion : verRaw;

    final tarballUriRaw = (root['tarball_uri'] as String?)?.trim();
    final tarballUri = (tarballUriRaw != null && tarballUriRaw.isNotEmpty) ? tarballUriRaw : null;

    LibSource source = LibSource.download(
      url:
          tarballUri ??
          'https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$version.tar.gz',
    );

    final srcMap = LibDefines.stringKeyMap(root['source']);
    if (srcMap.isNotEmpty) {
      if (srcMap['system'] == true) {
        source = const LibSource.system();
      } else if (srcMap.containsKey('vendored')) {
        final vend = LibDefines.stringKeyMap(srcMap['vendored']);
        final path = (vend['path'] as String?)?.trim();
        if (path == null || path.isEmpty) {
          throw StateError('user_defines.webp.source.vendored.path must be a directory.');
        }
        source = LibSource.vendored(path: path);
      } else if (srcMap.containsKey('download')) {
        final dl = LibDefines.stringKeyMap(srcMap['download']);
        final url = (dl['url'] as String?)?.trim();
        if (url == null || url.isEmpty) {
          throw StateError('user_defines.webp.source.download.url is required.');
        }
        source = LibSource.download(url: url);
      }
    }

    final android = LibDefines.stringKeyMap(root['android']);
    final sdkRoot = (android['sdk_root'] as String?)?.trim();
    final ndkRoot = (android['ndk_root'] as String?)?.trim();
    final enabled = (root['enabled'] as bool?) ?? true;

    return WebpDefines._(
      version: version,
      source: source,
      androidSdkRoot: (sdkRoot?.isEmpty ?? true) ? null : sdkRoot,
      androidNdkRoot: (ndkRoot?.isEmpty ?? true) ? null : ndkRoot,
      tarballUri: tarballUri,
      defaultUrlBuilder: (input) =>
          'https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$version.tar.gz',

      enabled: enabled,
    );
  }
}
