import 'dart:async';
import 'dart:html';

Future<bool> portraitImageExists(String url) async {
  final image = ImageElement();
  final loadFuture = image.onLoad.first.then((_) => true);
  final errorFuture = image.onError.first.then((_) => false);
  image.src = url;

  try {
    return await Future.any([loadFuture, errorFuture])
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
  } catch (_) {
    return false;
  }
}
