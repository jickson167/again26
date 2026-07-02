import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class CsvFileLoader {
  static Future<String?> pickCsvText() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return null;
    }

    return utf8.decode(bytes);
  }

  static bool isCsvFileName(String name) {
    return name.toLowerCase().endsWith('.csv');
  }

  static String decodeBytes(List<int> bytes) {
    return utf8.decode(bytes);
  }

  /// UTF-8 BOM 제거 및 CSV 헤더/내용 정리
  static String normalizeCsvContent(String content) {
    var text = content;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
}
