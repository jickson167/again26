import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../models/coach.dart';
import '../services/csv_file_loader.dart';
import '../utils/file_download.dart';

class CoachCsvService {
  static final _csv = Csv(lineDelimiter: '\n');

  static const headers = [
    'coach_id',
    'name',
    'fake_name',
    'nationality',
    'age',
    'rank',
    'coach_type',
    'base_leadership',
    'ability_id',
    'ability_name',
    'ability_effect',
    'fit_good',
    'fit_normal',
    'fit_bad',
    'leadership_curve',
    'comment',
  ];

  String exportCoaches(List<Coach> coaches) {
    return _csv.encode([
      headers,
      ...coaches.map(_toRow),
    ]);
  }

  List<Coach> parseCsv(String content) {
    final rows = _csv.decode(CsvFileLoader.normalizeCsvContent(content));
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first.map((cell) => _cleanHeader('$cell')).toList();
    final headerIndex = {
      for (var i = 0; i < headerRow.length; i++) headerRow[i]: i,
    };

    final coaches = <Coach>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.isEmpty || row.every((cell) => '$cell'.trim().isEmpty)) {
        continue;
      }
      final coach = _rowToCoach(row, headerIndex);
      if (coach.id.isNotEmpty && coach.name.isNotEmpty) {
        coaches.add(coach);
      }
    }
    return coaches;
  }

  Future<List<Coach>> importFromPicker() async {
    final content = await CsvFileLoader.pickCsvText();
    if (content == null) {
      return [];
    }
    return parseCsv(content);
  }

  void downloadCsv(String content, {String filename = 'coaches.csv'}) {
    if (kIsWeb) {
      downloadTextFile(content, filename);
    }
  }

  static void validateForDatabase(List<Coach> coaches) {
    for (final coach in coaches) {
      if (coach.id.isEmpty) {
        throw const FormatException('coach_id가 비어 있는 행이 있습니다.');
      }
      if (!coach.id.startsWith('ch_')) {
        throw FormatException('${coach.id}: coach_id는 ch_ 로 시작해야 합니다.');
      }
      if (coach.baseLeadership < 0 || coach.baseLeadership > 100) {
        throw FormatException('${coach.id}: base_leadership은 0~100이어야 합니다.');
      }
      if (coach.leadershipCurve.length != Coach.leadershipPeriodCount) {
        throw FormatException('${coach.id}: leadership_curve는 18개 값이어야 합니다.');
      }
      if (coach.leadershipCurve.last != 0) {
        throw FormatException('${coach.id}: 18기 통솔력은 0으로 마감해야 합니다.');
      }
    }
  }

  List<dynamic> _toRow(Coach coach) {
    return [
      coach.id,
      coach.name,
      coach.fakeName ?? '',
      coach.nationality ?? '',
      coach.age ?? '',
      coach.rank ?? '',
      coach.coachType,
      coach.baseLeadership,
      coach.abilityId,
      coach.abilityName,
      coach.abilityEffect,
      coach.fitGood.join('|'),
      coach.fitNormal.join('|'),
      coach.fitBad.join('|'),
      coach.leadershipCurve.join('|'),
      coach.comment ?? '',
    ];
  }

  Coach _rowToCoach(List<dynamic> row, Map<String, int> headerIndex) {
    String read(String key, {String alt = ''}) {
      final index = headerIndex[key] ?? (alt.isEmpty ? null : headerIndex[alt]);
      if (index == null || index >= row.length) {
        return '';
      }
      return '${row[index]}'.trim();
    }

    int? readInt(String key) {
      final raw = read(key);
      if (raw.isEmpty) {
        return null;
      }
      return int.tryParse(raw);
    }

    List<String> readList(String key) {
      return read(key)
          .split(RegExp(r'[|;；,]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    List<int> readCurve(String key) {
      final values = read(key)
          .split(RegExp(r'[|;；,]'))
          .map((item) => int.tryParse(item.trim())?.clamp(0, 100) ?? 0)
          .toList();
      while (values.length < Coach.leadershipPeriodCount) {
        values.add(0);
      }
      return values.take(Coach.leadershipPeriodCount).toList();
    }

    final curve = read('leadership_curve').isEmpty
        ? Coach.defaultLeadershipCurve()
        : readCurve('leadership_curve');

    return Coach(
      id: read('coach_id', alt: 'id'),
      name: read('name'),
      fakeName: read('fake_name').isEmpty ? null : read('fake_name'),
      nationality: read('nationality').isEmpty ? null : read('nationality'),
      age: readInt('age'),
      rank: readInt('rank')?.clamp(1, 5),
      coachType: read('coach_type'),
      baseLeadership: (readInt('base_leadership') ?? 0).clamp(0, 100),
      abilityId: read('ability_id'),
      abilityName: read('ability_name'),
      abilityEffect: read('ability_effect'),
      fitGood: readList('fit_good'),
      fitNormal: readList('fit_normal'),
      fitBad: readList('fit_bad'),
      leadershipCurve: curve,
      comment: read('comment').isEmpty ? null : read('comment'),
    );
  }

  static String _cleanHeader(String value) {
    return value
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');
  }
}
