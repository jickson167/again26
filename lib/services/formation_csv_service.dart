import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../models/formation.dart';
import '../services/csv_file_loader.dart';
import '../utils/file_download.dart';

class FormationCsvService {
  static final _csv = Csv(lineDelimiter: '\n');

  static const headers = [
    'formation_id',
    'name',
    'tactical_type',
    'key_pos_1',
    'key_pos_2',
    'key_pos_3',
    'comment',
  ];

  String exportFormations(List<Formation> items) {
    return _csv.encode([
      headers,
      ...items.map(_toRow),
    ]);
  }

  List<Formation> parseCsv(String content) {
    final rows = _csv.decode(CsvFileLoader.normalizeCsvContent(content));
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first.map((cell) => '$cell'.trim()).toList();
    final headerIndex = {
      for (var i = 0; i < headerRow.length; i++) headerRow[i]: i,
    };

    final items = <Formation>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => '$cell'.trim().isEmpty)) {
        continue;
      }
      final item = _rowToFormation(row, headerIndex);
      if (item.id.isNotEmpty || item.name.isNotEmpty) {
        items.add(item);
      }
    }
    return items;
  }

  Future<List<Formation>> importFromPicker() async {
    final content = await CsvFileLoader.pickCsvText();
    if (content == null) {
      return [];
    }
    return parseCsv(content);
  }

  void downloadCsv(String content, {String filename = 'formations.csv'}) {
    if (kIsWeb) {
      downloadTextFile(content, filename);
    }
  }

  List<dynamic> _toRow(Formation f) {
    return [
      f.id,
      f.name,
      f.tacticalType ?? '',
      f.keyPos1 ?? '',
      f.keyPos2 ?? '',
      f.keyPos3 ?? '',
      f.comment ?? '',
    ];
  }

  Formation _rowToFormation(List<dynamic> row, Map<String, int> headerIndex) {
    String read(String key, {String alt = ''}) {
      final index = headerIndex[key] ?? (alt.isEmpty ? null : headerIndex[alt]);
      if (index == null || index >= row.length) {
        return '';
      }
      return '$row[index]'.trim();
    }

    final id = read('formation_id', alt: 'id');
    return Formation(
      id: id,
      name: read('name'),
      tacticalType: read('tactical_type').isEmpty ? null : read('tactical_type'),
      keyPos1: read('key_pos_1').isEmpty ? null : read('key_pos_1'),
      keyPos2: read('key_pos_2').isEmpty ? null : read('key_pos_2'),
      keyPos3: read('key_pos_3').isEmpty ? null : read('key_pos_3'),
      comment: read('comment').isEmpty ? null : read('comment'),
    );
  }
}
