import 'dart:convert';
import 'dart:typed_data';

bool isPortraitImageFileName(String name) {
  final lower = name.trim().toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.avif');
}

String portraitMimeTypeFor(String extensionOrName) {
  final lower = extensionOrName.trim().toLowerCase();
  if (lower.endsWith('.png') || lower == 'png') {
    return 'image/png';
  }
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower == 'jpg' ||
      lower == 'jpeg') {
    return 'image/jpeg';
  }
  if (lower.endsWith('.webp') || lower == 'webp') {
    return 'image/webp';
  }
  if (lower.endsWith('.gif') || lower == 'gif') {
    return 'image/gif';
  }
  if (lower.endsWith('.bmp') || lower == 'bmp') {
    return 'image/bmp';
  }
  if (lower.endsWith('.avif') || lower == 'avif') {
    return 'image/avif';
  }
  return 'image/png';
}

String portraitDataUrlFromBytes(List<int> bytes, String extensionOrName) {
  final mime = portraitMimeTypeFor(extensionOrName);
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

String portraitDataUrlFromUint8List(Uint8List bytes, String extensionOrName) {
  return portraitDataUrlFromBytes(bytes, extensionOrName);
}
