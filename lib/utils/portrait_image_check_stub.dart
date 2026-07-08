Future<bool> portraitImageExists(String url) async =>
    url.trim().startsWith('data:image/');
