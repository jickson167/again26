import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/player.dart';
import '../models/player_growth.dart';
import '../models/player_position.dart';
import '../utils/file_download.dart';

class CsvService {
  static final _csv = Csv(lineDelimiter: '\n');
  static List<String> get headers => [
        'id',
        'name',
        'fake_name',
        'position',
        ...List.generate(Player.positionFitCount, (index) => 'pos_${index + 1}'),
        'rank',
        'age_stage',
        'height',
        'weight',
        'nationality',
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
      for (var i = 1; i <= Player.positionFitCount; i++) player.positionFit[i] ?? 0,
      player.rank ?? '',
      player.ageStage ?? '',
      player.height ?? '',
      player.weight ?? '',
      player.nationality ?? '',
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
    for (var i = 1; i <= Player.positionFitCount; i++) {
      positionFit[i] = readStat('pos_$i');
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

    return Player(
      id: readString('id'),
      name: readString('name'),
      fakeName: readString('fake_name').isEmpty ? null : readString('fake_name'),
      position: PlayerPosition.fromCode(readString('position', defaultValue: 'mf')),
      positionFit: positionFit,
      rank: readInt('rank'),
      ageStage: readString('age_stage').isEmpty ? null : readString('age_stage'),
      height: readInt('height'),
      weight: readInt('weight'),
      nationality:
          readString('nationality').isEmpty ? null : readString('nationality'),
      growthType: growthType,
      speed: readStat('speed'),
      power: readStat('power'),
      technique: readStat('technique'),
      pkAbility: readStat('pk_ability'),
      fkAbility: readStat('fk_ability'),
      ckAbility: readStat('ck_ability'),
      leadership: readStat('leadership'),
      intelligenceSense: readStat('intelligence_sense', defaultValue: 5),
      individualOrganization: readStat('individual_organization', defaultValue: 5),
      portraitUrl:
          readString('portrait_url').isEmpty ? null : readString('portrait_url'),
    );
  }
}
