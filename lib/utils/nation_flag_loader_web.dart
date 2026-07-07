import 'dart:js_interop';

import 'package:web/web.dart';

Future<String> loadNationFlagMapJson(String url) async {
  final response = await window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('Failed to load nation flag map: $url');
  }
  return (await response.text().toDart).toDart;
}
