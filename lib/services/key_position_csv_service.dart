import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/key_position.dart';
import '../models/player_position.dart';
import '../utils/file_download.dart';

class KeyPositionCsvService {
  static final _csv = Csv(lineDelimiter: '\n');

  static const headers = [
    'key_position_id',
    'name',
    'simple_position',
    'main_stat',
    'sub_stat',
    'mental_pref',
    'team_pref',
    'description',
  ];

  String exportKeyPositions(List<KeyPosition> items) {
    return _csv.encode([
      headers,
      ...items.map(_toRow),
    ]);
  }

  List<KeyPosition> parseCsv(String content) {
    final rows = _csv.decode(content);
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first.map((cell) => '$cell'.trim()).toList();
    final headerIndex = {
      for (var i = 0; i < headerRow.length; i++) headerRow[i]: i,
    };

    final items = <KeyPosition>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => '$cell'.trim().isEmpty)) {
        continue;
      }
      final item = _rowToKeyPosition(row, headerIndex);
      if (item.id.isNotEmpty || item.name.isNotEmpty) {
        items.add(item);
      }
    }
    return items;
  }

  Future<List<KeyPosition>> importFromPicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return [];
    }
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return [];
    }
    return parseCsv(utf8.decode(bytes));
  }

  void downloadCsv(String content, {String filename = 'key_positions.csv'}) {
    if (kIsWeb) {
      downloadTextFile(content, filename);
    }
  }

  List<dynamic> _toRow(KeyPosition k) {
    return [
      k.id,
      k.name,
      k.simplePosition.code,
      k.mainStat,
      k.subStat,
      k.mentalPref,
      k.teamPref,
      k.description ?? '',
    ];
  }

  KeyPosition _rowToKeyPosition(List<dynamic> row, Map<String, int> headerIndex) {
    String read(String key, {String alt = ''}) {
      final index = headerIndex[key] ?? (alt.isEmpty ? null : headerIndex[alt]);
      if (index == null || index >= row.length) {
        return '';
      }
      return '$row[index]'.trim();
    }

    final id = read('key_position_id', alt: 'id');
    return KeyPosition(
      id: id,
      name: read('name'),
      simplePosition: PlayerPosition.fromCode(read('simple_position')),
      mainStat: read('main_stat'),
      subStat: read('sub_stat'),
      mentalPref: read('mental_pref', alt: 'mental').isEmpty
          ? 'intelligence'
          : read('mental_pref', alt: 'mental'),
      teamPref: read('team_pref', alt: 'team').isEmpty
          ? 'organization'
          : read('team_pref', alt: 'team'),
      description: read('description').isEmpty ? null : read('description'),
    );
  }
}
