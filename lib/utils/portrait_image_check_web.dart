import 'dart:js_interop';

import 'package:web/web.dart';

Future<bool> portraitImageExists(String url) async {
  try {
    final response = await window
        .fetch(
          url.toJS,
          RequestInit(method: 'HEAD'),
        )
        .toDart;
    return response.ok;
  } catch (_) {
    return false;
  }
}
