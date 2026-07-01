import 'dart:js_interop';

import 'package:web/web.dart';

void downloadTextFile(String content, String filename) {
  final blob = Blob([content.toJS].toJS);
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
