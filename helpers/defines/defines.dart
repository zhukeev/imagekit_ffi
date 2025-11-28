import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Generic source descriptor shared by all libraries.
sealed class LibSource {
  const LibSource();
  factory LibSource.download({required String url}) = _LibDownload;
  factory LibSource.vendored({required String path}) = _LibVendored;
  const factory LibSource.system() = _LibSystem;
}

class _LibDownload extends LibSource {
  final String url;
  const _LibDownload({required this.url});
}

class _LibVendored extends LibSource {
  final String path;
  const _LibVendored({required this.path});
}

class _LibSystem extends LibSource {
  const _LibSystem();
}

/// Common defines holder for native libs. Concrete libs (TJ/libpng/etc.)
/// should extend this class and provide their codecKey + defaultUrlBuilder.
class LibDefines {
  LibDefines({
    required this.version,
    required this.source,
    required this.defaultUrlBuilder,
    required this.enabled,
    Set<String>? skipPlatforms,
    this.androidSdkRoot,
    this.androidNdkRoot,
    this.tarballUri,
  }) : skipPlatforms = skipPlatforms ?? const {};

  /// Library version string (e.g. "3.1.2").
  final String version;

  /// Where to obtain sources (download / vendored / system).
  final LibSource source;

  /// Optional Android SDK/NDK roots for cross builds.
  final String? androidSdkRoot;
  final String? androidNdkRoot;

  /// Optional explicit tarball URI override from user_defines.
  final String? tarballUri;

  /// Optional explicit enable/disable override from user_defines.
  final bool enabled;

  /// Platforms where this lib should be skipped (android/ios/macos/linux/windows).
  final Set<String> skipPlatforms;

  /// Default URL builder used when no explicit url is provided.
  /// Signature: (version) => url
  final String Function(String version) defaultUrlBuilder;

  /// Vendored path (if any).
  String? get vendoredPath => source is _LibVendored ? (source as _LibVendored).path : null;

  /// Whether to use system-provided library.
  bool get useSystem => source is _LibSystem;

  /// Final effective URL to download (resolves source/tarball/default).
  String get downloadUrl => switch (source) {
    _LibDownload d => d.url,
    _ => tarballUri ?? defaultUrlBuilder(version),
  };

  bool isEnabledForOs(OS targetOs) {
    print('LibDefines.isEnabledForOs($targetOs)');
    print('LibDefines.isEnabledForOs: enabled = $enabled');
    print('LibDefines.isEnabledForOs: skipPlatforms = $skipPlatforms');
    if (!enabled) return false;
    final key = _targetOsKey(targetOs);
    if (skipPlatforms.contains(key)) return false;
    return true;
  }

  static String _targetOsKey(OS os) {
    switch (os) {
      case OS.android:
        return 'android';
      case OS.iOS:
        return 'ios';
      case OS.macOS:
        return 'macos';
      case OS.linux:
        return 'linux';
      case OS.windows:
        return 'windows';
      default:
        return 'other';
    }
  }

  // ======== user_defines helpers (kept private to this module) ========

  static Map<String, dynamic> stringKeyMap(Object? v) {
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  static Map<String, dynamic>? _tryWorkspaceDefines(BuildInput input) {
    final ju = input.json['user_defines'];

    if (ju is Map) {
      final wsp = ju['workspace_pubspec'];

      if (wsp is Map) {
        final defs = wsp['defines'];

        if (defs is Map) return stringKeyMap(defs);
      }
    }
    return null;
  }

  static Map<String, dynamic> _unwrapHookUserDefines(Object? ud) {
    if (ud is Map) return stringKeyMap(ud);
    try {
      final dyn = ud as dynamic;
      final j = dyn.json;
      if (j is Map) return stringKeyMap(j);
    } catch (_) {}
    try {
      final dyn = ud as dynamic;
      final j = dyn.toJson();
      if (j is Map) return stringKeyMap(j);
    } catch (_) {}
    return const {};
  }

  /// Resolve the root user_defines map we should read fields from.
  static Map<String, dynamic> resolveDefinesRoot(BuildInput input) {
    final ws = _tryWorkspaceDefines(input);
    if (ws != null) return ws;

    final raw = _unwrapHookUserDefines(input.userDefines);

    for (final key in [input.packageName, 'turbo_jpeg', 'turbo_jpeg_native_assets', 'imagekit_ffi']) {
      final v = raw[key];
      if (v is Map) return stringKeyMap(v);
    }
    return stringKeyMap(raw);
  }

  /// Return codec-scoped block: user_defines.<codecKey.
  /// codecKey is the Key under `user_defines` (e.g. "turbo_jpeg", "libpng").
  static Map<String, dynamic> resolveCodecBlock(BuildInput input, String codecKey) {
    final root = resolveDefinesRoot(input);
    final v = root[codecKey];
    if (v is Map) return stringKeyMap(v);
    // Support flat maps for backward compatibility.
    return root;
  }

  /// Parse a LibSource from a `source` map (download/vendored/system).
  static LibSource parseSource(Map<String, dynamic> srcMap, {String? ctxKey}) {
    if (srcMap.isEmpty) return const LibSource.system();
    if (srcMap['system'] == true) return const LibSource.system();

    if (srcMap.containsKey('vendored')) {
      final vend = stringKeyMap(srcMap['vendored']);
      final path = (vend['path'] as String?)?.trim();
      if (path == null || path.isEmpty) {
        throw StateError('user_defines.$ctxKey.source.vendored.path must be a directory.');
      }
      return LibSource.vendored(path: path);
    }

    if (srcMap.containsKey('download')) {
      final dl = stringKeyMap(srcMap['download']);
      final url = (dl['url'] as String?)?.trim();
      if (url == null || url.isEmpty) {
        throw StateError('user_defines.$ctxKey.source.download.url is required.');
      }
      return LibSource.download(url: url);
    }

    // Default to system if structure is unknown.
    return const LibSource.system();
  }

  static Set<String> parseSkipPlatforms(Map<String, dynamic> codecBlock) {
    final result = <String>{};
    final raw = codecBlock['skip_platform'];

    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v.isNotEmpty) result.add(v);
    } else if (raw is List) {
      for (final item in raw) {
        final v = item.toString().trim().toLowerCase();
        if (v.isNotEmpty) result.add(v);
      }
    }

    return result;
  }
}
