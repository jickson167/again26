import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../models/formation.dart';
import '../services/csv_file_loader.dart';
import '../utils/file_download.dart';
import '../utils/formation_display.dart';

class FormationCsvService {
  static final _csv = Csv(lineDelimiter: '\n');

  static const headers = [
    'formation_id',
    'name',
    'formation_type',
    'possession',
    'attack',
    'stability',
    'key_pos_1',
    'key_pos_1_slot',
    'key_pos_2',
    'key_pos_2_slot',
    'key_pos_3',
    'key_pos_3_slot',
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

    final headerRow = rows.first.map((cell) => _cleanHeader('$cell')).toList();
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
      f.formationType ?? '',
      f.possession,
      f.attack,
      f.stability,
      f.keyPos1 ?? '',
      f.keyPos1Slot ?? '',
      f.keyPos2 ?? '',
      f.keyPos2Slot ?? '',
      f.keyPos3 ?? '',
      f.keyPos3Slot ?? '',
      f.comment ?? '',
    ];
  }

  static void validateForDatabase(List<Formation> items) {
    const allowedTypes = {'S', 'T', 'P'};
    for (final item in items) {
      if (FormationDisplay.isCorruptRecord(item)) {
        throw FormatException(
          '${item.id}: CSV 행이 잘못 파싱되었습니다. 파일을 다시 저장·가져오세요.',
        );
      }
      if (item.id.isEmpty) {
        throw FormatException('formation_id가 비어 있는 행이 있습니다.');
      }
      final type = item.formationType?.toUpperCase();
      if (type == null || !allowedTypes.contains(type)) {
        throw FormatException(
          '${item.id}: formation_type은 S, T, P 중 하나여야 합니다.',
        );
      }
      _validateStat(item.id, 'possession', item.possession);
      _validateStat(item.id, 'attack', item.attack);
      _validateStat(item.id, 'stability', item.stability);
      _validateKeySlot(item.id, 'key_pos_1', item.keyPos1, item.keyPos1Slot);
      _validateKeySlot(item.id, 'key_pos_2', item.keyPos2, item.keyPos2Slot);
      _validateKeySlot(item.id, 'key_pos_3', item.keyPos3, item.keyPos3Slot);
    }
  }

  static void _validateStat(String id, String field, int value) {
    if (value < 0 || value > 10) {
      throw FormatException('$id: $field는 0~10 정수여야 합니다.');
    }
  }

  static void _validateKeySlot(String id, String field, String? kpId, int? slot) {
    if (kpId == null || kpId.isEmpty) {
      throw FormatException('$id: $field가 비어 있습니다.');
    }
    if (!kpId.startsWith('kp_')) {
      throw FormatException('$id: $field="$kpId" — kp_ 로 시작해야 합니다.');
    }
    if (slot == null || slot < 1 || slot > 13) {
      throw FormatException('$id: ${field}_slot은 1~13이어야 합니다.');
    }
  }

  static String _cleanHeader(String value) {
    return value
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');
  }

  Formation _rowToFormation(List<dynamic> row, Map<String, int> headerIndex) {
    String read(String key, {String alt = ''}) {
      final index = headerIndex[key] ?? (alt.isEmpty ? null : headerIndex[alt]);
      if (index == null || index >= row.length) {
        return '';
      }
      return '${row[index]}'.trim();
    }

    int readStat(String key) {
      final raw = read(key);
      if (raw.isEmpty) {
        return 5;
      }
      return int.tryParse(raw)?.clamp(0, 10) ?? 5;
    }

    int? readSlot(String key) {
      final raw = read(key);
      if (raw.isEmpty) {
        return null;
      }
      final slot = int.tryParse(raw);
      if (slot == null || slot < 1 || slot > 13) {
        return null;
      }
      return slot;
    }

    final id = read('formation_id', alt: 'id');
    final formationType = read('formation_type');
    return Formation(
      id: id,
      name: read('name'),
      formationType: formationType.isEmpty ? null : formationType.toUpperCase(),
      possession: readStat('possession'),
      attack: readStat('attack'),
      stability: readStat('stability'),
      keyPos1: read('key_pos_1').isEmpty ? null : read('key_pos_1'),
      keyPos1Slot: readSlot('key_pos_1_slot'),
      keyPos2: read('key_pos_2').isEmpty ? null : read('key_pos_2'),
      keyPos2Slot: readSlot('key_pos_2_slot'),
      keyPos3: read('key_pos_3').isEmpty ? null : read('key_pos_3'),
      keyPos3Slot: readSlot('key_pos_3_slot'),
      comment: read('comment').isEmpty ? null : read('comment'),
    );
  }
}
