import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../models/key_position.dart';
import '../models/player_position.dart';
import '../services/csv_file_loader.dart';
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

  static const _generatorHeaders = [
    'id',
    'name',
    'simple',
    'main',
    'sub',
    'mental',
    'team',
    'desc',
  ];

  String exportKeyPositions(List<KeyPosition> items) {
    return _csv.encode([
      headers,
      ...items.map(_toRow),
    ]);
  }

  List<KeyPosition> parseCsv(String content) {
    final normalized = CsvFileLoader.normalizeCsvContent(content);
    final rows = _csv.decode(normalized);
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first.map((cell) => _cleanHeader('$cell')).toList();
    final headerIndex = {
      for (var i = 0; i < headerRow.length; i++) headerRow[i]: i,
    };

    final useGeneratorHeader = _looksLikeGeneratorHeader(headerRow);
    final dataStartIndex = _looksLikeDataRow(headerRow) ? 0 : 1;

    final items = <KeyPosition>[];
    for (var i = dataStartIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => '$cell'.trim().isEmpty)) {
        continue;
      }
      final item = _rowToKeyPosition(
        row,
        headerIndex: headerIndex,
        useGeneratorHeader: useGeneratorHeader,
        treatAsDataRow: dataStartIndex == 0,
        rowIndex: i,
      );
      if (item.id.isNotEmpty || item.name.isNotEmpty) {
        items.add(item);
      }
    }
    return items;
  }

  /// upsert 전 DB check constraint 통과 여부 검사
  static void validateForDatabase(List<KeyPosition> items) {
    const allowedMental = {'intelligence', 'sense'};
    const allowedTeam = {'organization', 'individual'};

    for (final item in items) {
      if (!allowedMental.contains(item.mentalPref)) {
        throw FormatException(
          '${item.id} (${item.name}): mental_pref="${item.mentalPref}" — '
          '허용값은 intelligence, sense 입니다. CSV 열(mental/mental_pref)을 확인하세요.',
        );
      }
      if (!allowedTeam.contains(item.teamPref)) {
        throw FormatException(
          '${item.id} (${item.name}): team_pref="${item.teamPref}" — '
          '허용값은 organization, individual 입니다.',
        );
      }
    }
  }

  Future<List<KeyPosition>> importFromPicker() async {
    final content = await CsvFileLoader.pickCsvText();
    if (content == null) {
      return [];
    }
    return parseCsv(content);
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

  bool _looksLikeGeneratorHeader(List<String> headerRow) {
    return headerRow.contains('mental') || headerRow.contains('simple');
  }

  bool _looksLikeDataRow(List<String> row) {
    final first = row.isEmpty ? '' : row.first.trim();
    return first.startsWith('kp_');
  }

  String _cleanHeader(String value) {
    return value.replaceAll('\uFEFF', '').trim().toLowerCase();
  }

  KeyPosition _rowToKeyPosition(
    List<dynamic> row, {
    required Map<String, int> headerIndex,
    required bool useGeneratorHeader,
    required bool treatAsDataRow,
    required int rowIndex,
  }) {
    String readByNames(List<String> keys) {
      for (final key in keys) {
        final index = headerIndex[key];
        if (index != null && index < row.length) {
          return '$row[index]'.trim();
        }
      }
      return '';
    }

    String readPositional(int index) {
      if (index >= 0 && index < row.length) {
        return '$row[index]'.trim();
      }
      return '';
    }

    if (treatAsDataRow) {
      return KeyPosition(
        id: readPositional(0),
        name: readPositional(1),
        simplePosition: PlayerPosition.fromCode(readPositional(2)),
        mainStat: readPositional(3),
        subStat: readPositional(4),
        mentalPref: _normalizeMental(readPositional(5)),
        teamPref: _normalizeTeam(readPositional(6)),
        description: readPositional(7).isEmpty ? null : readPositional(7),
      );
    }

    final mentalRaw = useGeneratorHeader
        ? readByNames(['mental', 'mental_pref'])
        : readByNames(['mental_pref', 'mental']);
    final teamRaw = useGeneratorHeader
        ? readByNames(['team', 'team_pref'])
        : readByNames(['team_pref', 'team']);

    final id = readByNames(['key_position_id', 'id']);
    if (id.isEmpty && rowIndex == 1) {
      throw FormatException(
        'CSV 헤더를 인식하지 못했습니다. '
        'key_positions_launch.csv 또는 헤더 포함 CSV를 사용하세요.',
      );
    }

    return KeyPosition(
      id: id,
      name: readByNames(['name']),
      simplePosition: PlayerPosition.fromCode(
        readByNames(['simple_position', 'simple']),
      ),
      mainStat: readByNames(['main_stat', 'main']),
      subStat: readByNames(['sub_stat', 'sub']),
      mentalPref: _normalizeMental(mentalRaw),
      teamPref: _normalizeTeam(teamRaw),
      description: readByNames(['description', 'desc']).isEmpty
          ? null
          : readByNames(['description', 'desc']),
    );
  }

  String _normalizeMental(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) {
      return 'intelligence';
    }
    switch (v) {
      case 'sense':
      case 'emotion':
      case '감각':
        return 'sense';
      case 'intelligence':
      case 'intel':
      case '지성':
        return 'intelligence';
      default:
        return v;
    }
  }

  String _normalizeTeam(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) {
      return 'organization';
    }
    switch (v) {
      case 'individual':
      case '개인':
        return 'individual';
      case 'organization':
      case '조직':
        return 'organization';
      default:
        return v;
    }
  }
}
