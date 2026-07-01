import 'dart:js_interop';

@JS('AGAIN26_CONFIG')
external JSAny? get _again26Config;

String? readRuntimeConfig(String key) {
  final raw = _again26Config?.dartify();
  if (raw is! Map) {
    return null;
  }

  final value = raw[key];
  if (value == null) {
    return null;
  }

  return '$value';
}
