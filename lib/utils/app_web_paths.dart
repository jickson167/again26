import 'package:flutter/foundation.dart';

/// GitHub Pages(`/again26/`)·로컬 Flutter web 모두에서 정적 HTML 경로를 맞춘다.
String playerGeneratorPageUrl() {
  return _toolPageUrl('player_row_generator_v3.html');
}

String coachGeneratorPageUrl() {
  return _toolPageUrl('coach_row_generator_v1.html');
}

String flagNationMapperPageUrl() {
  return _toolPageUrl('flag_nation_mapper.html');
}

String _toolPageUrl(String filename) {
  if (!kIsWeb) {
    return '/tools/$filename';
  }

  final uri = Uri.base;
  final path = uri.path;

  var cut = path.length;
  for (final marker in ['/admin', '/players']) {
    final index = path.indexOf(marker);
    if (index >= 0 && index < cut) {
      cut = index;
    }
  }

  final basePath = path.substring(0, cut);
  final normalizedBase = basePath.endsWith('/') ? basePath : '$basePath/';
  return '${uri.origin}${normalizedBase}tools/$filename';
}
