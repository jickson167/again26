import 'package:flutter/foundation.dart';

/// GitHub Pages(`/again26/`)·로컬 Flutter web 모두에서 국기·매핑 JSON 경로를 맞춘다.
String nationFlagMapDataUrl() {
  return _assetUrl('data/nation_flag_map.json');
}

String nationFlagImageUrl(String filename) {
  return _assetUrl('flags/$filename');
}

String _assetUrl(String relativePath) {
  if (!kIsWeb) {
    return '/$relativePath';
  }

  final uri = Uri.base;
  final path = uri.path;

  var cut = path.length;
  for (final marker in ['/admin', '/players', '/game', '/tools']) {
    final index = path.indexOf(marker);
    if (index >= 0 && index < cut) {
      cut = index;
    }
  }

  final basePath = path.substring(0, cut);
  final normalizedBase = basePath.endsWith('/') ? basePath : '$basePath/';
  return '${uri.origin}$normalizedBase$relativePath';
}
