import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/player.dart';
import '../models/player_growth.dart';
import '../models/player_position.dart';
import '../models/player_position_fit_columns.dart';
import '../utils/file_download.dart';

class CsvService {
  static final _csv = Csv(lineDelimiter: '\n');

  static List<String> get headers => [
        'id',
        'name',
        'fake_name',
        'position',
        'rank',
        'current_age',
        'peak_age',
        'height',
        'weight',
        'nationality',
        ...playerPositionFitCsvColumns,
        ...List.generate(
          Player.growthPeriodCount,
          (index) => [
            'growth_${index + 1}_speed',
            'growth_${index + 1}_power',
            'growth_${index + 1}_technique',
          ],
        ).expand((columns) => columns),
        'speed',
        'power',
        'technique',
        'pk_ability',
        'fk_ability',
        'ck_ability',
        'leadership',
        'intelligence_sense',
        'individual_organization',
        'detail_position',
        'comment',
        'shooting',
        'passing',
        'defense',
        'stamina',
        'goalkeeper',
        'recommend_key_positions',
        'portrait_url',
      ];

  String exportPlayers(List<Player> players) {
    final rows = [
      headers,
      ...players.map(_playerToRow),
    ];
    return _csv.encode(rows);
  }

  List<Player> parseCsv(String content) {
    final rows = _csv.decode(content);
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first.map((cell) => '$cell'.trim()).toList();
    final headerIndex = {
      for (var i = 0; i < headerRow.length; i++) headerRow[i]: i,
    };

    final players = <Player>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.isEmpty || row.every((cell) => '$cell'.trim().isEmpty)) {
        continue;
      }

      final player = _rowToPlayer(row, headerIndex);
      if (player.name.trim().isNotEmpty) {
        players.add(player);
      }
    }

    return players;
  }

  Future<List<Player>> importFromPicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return [];
    }

    final content = utf8.decode(bytes);
    return parseCsv(content);
  }

  void downloadCsv(String content, {String filename = 'players.csv'}) {
    if (!kIsWeb) {
      return;
    }

    downloadTextFile(content, filename);
  }

  List<dynamic> _playerToRow(Player player) {
    return [
      player.id,
      player.name,
      player.fakeName ?? '',
      player.position.code,
      player.rank ?? '',
      player.ageStage ?? '',
      player.peakAge ?? '',
      player.height ?? '',
      player.weight ?? '',
      player.nationality ?? '',
      for (var i = 0; i < playerPositionFitCsvColumns.length; i++)
        player.positionFit[i + 1] ?? 0,
      for (var i = 0; i < Player.growthPeriodCount; i++) ...[
        player.growthType[i].speed,
        player.growthType[i].power,
        player.growthType[i].technique,
      ],
      player.speed,
      player.power,
      player.technique,
      player.pkAbility,
      player.fkAbility,
      player.ckAbility,
      player.leadership,
      player.intelligenceSense,
      player.individualOrganization,
      player.detailPosition ?? '',
      player.comment ?? '',
      player.shooting,
      player.passing,
      player.defense,
      player.stamina,
      player.goalkeeper,
      player.recommendKeyPositions ?? '',
      player.portraitUrl ?? '',
    ];
  }

  Player _rowToPlayer(List<dynamic> row, Map<String, int> headerIndex) {
    String readString(String key, {String defaultValue = ''}) {
      final index = headerIndex[key];
      if (index == null || index >= row.length) {
        return defaultValue;
      }
      return '$row[index]'.trim();
    }

    int? readInt(String key) {
      final value = readString(key);
      if (value.isEmpty) {
        return null;
      }
      return int.tryParse(value);
    }

    int readStat(String key, {int defaultValue = 0}) {
      return (readInt(key) ?? defaultValue).clamp(0, 10);
    }

    final positionFit = Player.defaultPositionFit();
    for (var i = 0; i < playerPositionFitCsvColumns.length; i++) {
      final column = playerPositionFitCsvColumns[i];
      positionFit[i + 1] = readStat(column);
    }
    for (var i = 1; i <= Player.positionFitCount; i++) {
      final legacyKey = 'pos_$i';
      if (headerIndex.containsKey(legacyKey)) {
        positionFit[i] = readStat(legacyKey);
      }
    }

    final growthType = <PlayerGrowth>[];
    for (var i = 1; i <= Player.growthPeriodCount; i++) {
      growthType.add(
        PlayerGrowth(
          speed: readStat('growth_${i}_speed'),
          power: readStat('growth_${i}_power'),
          technique: readStat('growth_${i}_technique'),
        ),
      );
    }

    final positionField = readString('position', defaultValue: 'mf');
    final simplePosition = headerIndex.containsKey('simple_position')
        ? readString('simple_position', defaultValue: positionField)
        : positionField;

    return Player(
      id: readString('id'),
      name: readString('name'),
      fakeName: readString('fake_name').isEmpty ? null : readString('fake_name'),
      position: PlayerPosition.fromCode(simplePosition),
      positionFit: positionFit,
      rank: readInt('rank'),
      ageStage: _readCurrentAge(readString, headerIndex),
      peakAge: readInt('peak_age'),
      detailPosition: _readDetailPosition(readString, headerIndex, positionField),
      comment: readString('comment').isEmpty ? null : readString('comment'),
      height: readInt('height'),
      weight: readInt('weight'),
      nationality:
          readString('nationality').isEmpty ? null : readString('nationality'),
      growthType: growthType,
      speed: readStat('speed'),
      power: readStat('power'),
      technique: readStat('technique'),
      shooting: readStat('shooting'),
      passing: readStat('passing'),
      defense: readStat('defense'),
      stamina: readStat('stamina'),
      goalkeeper: readStat('goalkeeper'),
      pkAbility: readStat('pk_ability'),
      fkAbility: readStat('fk_ability'),
      ckAbility: readStat('ck_ability'),
      leadership: readStat('leadership'),
      intelligenceSense: readStat('intelligence_sense', defaultValue: 5),
      individualOrganization: readStat('individual_organization', defaultValue: 5),
      recommendKeyPositions: readString('recommend_key_positions').isEmpty
          ? null
          : readString('recommend_key_positions'),
      portraitUrl:
          readString('portrait_url').isEmpty ? null : readString('portrait_url'),
    );
  }

  static String? _readCurrentAge(
    String Function(String key, {String defaultValue}) readString,
    Map<String, int> headerIndex,
  ) {
    if (headerIndex.containsKey('current_age')) {
      final value = readString('current_age');
      return value.isEmpty ? null : value;
    }
    final legacy = readString('age_stage');
    return legacy.isEmpty ? null : legacy;
  }

  static String? _readDetailPosition(
    String Function(String key, {String defaultValue}) readString,
    Map<String, int> headerIndex,
    String positionField,
  ) {
    final explicit = readString('detail_position');
    if (explicit.isNotEmpty) {
      return explicit;
    }
    if (headerIndex.containsKey('simple_position')) {
      final pos = readString('position');
      if (pos.contains('/') || pos.length > 2) {
        return pos;
      }
    }
    if (positionField.contains('/')) {
      return positionField;
    }
    return null;
  }
}
