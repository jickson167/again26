import 'package:flutter_test/flutter_test.dart';

import 'package:again26/models/match_simulation_dto.dart';
import 'package:again26/utils/event_comment_generator/event_comment_generator.dart';
import 'package:again26/utils/match_event_commentary_ko.dart';

void main() {
  test('goal dictionary has 100+ entries', () {
    expect(
      EventCommentGenerator.goalDictionaryCount(),
      greaterThanOrEqualTo(100),
    );
  });

  test('goal templates are at least 50', () {
    expect(EventCommentGenerator.goalTemplateCount(), greaterThanOrEqualTo(50));
  });

  test('goal commentary produces 100+ unique natural lines', () {
    final lines = EventCommentGenerator.sampleGoalLines(
      matchSeed: 42,
      sampleCount: 100,
    );
    expect(lines.length, greaterThanOrEqualTo(100));
    expect(lines.any((l) => l.contains('김공격') || l.contains('골')), isTrue);
  });

  test('same event + seed is reproducible', () {
    final e = MatchEventDto(
      matchMinute: 23,
      matchSecond: 10,
      type: 'goal',
      teamId: 'h',
      side: 'home',
      primaryPlayerId: 'p1',
      secondaryPlayerId: 'p2',
      metadata: {
        'schemaVersion': 1,
        'kind': 'goal',
        'payload': {
          'foot': 'right',
          'shotType': 'placement',
          'distance': 'inside_box',
          'bodyPart': 'foot',
          'afterDribble': false,
          'defendersBeaten': 0,
          'keeperTouched': false,
          'assistType': 'through',
          'counterAttack': false,
          'oneOnOne': true,
        },
        'styleContext': {
          'primaryStyleIds': ['finisher'],
          'secondaryStyleIds': ['playmaker'],
        },
      },
      currentHomeScore: 1,
      currentAwayScore: 0,
    );
    final ctx = CommentContext(
      matchSeed: 99,
      nameOf: (id) => id == 'p1' ? 'A' : 'B',
    );
    expect(
      EventCommentGenerator.generate(e, ctx),
      EventCommentGenerator.generate(e, ctx),
    );
  });

  test('save commentary uses GK and shooter correctly', () {
    final e = MatchEventDto(
      matchMinute: 40,
      matchSecond: 12,
      type: 'save',
      teamId: 'away',
      side: 'away',
      primaryPlayerId: 'gk1',
      secondaryPlayerId: 'shooter1',
      goalkeeperId: 'gk1',
      currentHomeScore: 0,
      currentAwayScore: 0,
    );
    final line = EventCommentGenerator.generate(
      e,
      CommentContext(
        matchSeed: 7,
        nameOf: (id) {
          if (id == 'gk1') return '박키퍼';
          if (id == 'shooter1') return '최슈터';
          return id;
        },
      ),
    );
    expect(line.contains('박키퍼'), isTrue);
    expect(line.contains('최슈터'), isTrue);
    expect(line.contains('박키퍼의 슈팅'), isFalse);
  });

  test('shot commentary uses left/right foot without duplicate 슈팅', () {
    final e = MatchEventDto(
      matchMinute: 22,
      matchSecond: 5,
      type: 'shot',
      teamId: 'h',
      side: 'home',
      primaryPlayerId: 'p1',
      metadata: {
        'schemaVersion': 1,
        'kind': 'shot',
        'payload': {
          'foot': 'both',
          'shotType': 'power',
          'distance': 'outside_box',
          'blocked': false,
          'saved': false,
          'offTarget': false,
          'hitPost': false,
        },
      },
      currentHomeScore: 0,
      currentAwayScore: 0,
    );
    final line = EventCommentGenerator.generate(
      e,
      CommentContext(
        matchSeed: 3,
        nameOf: (id) => id == 'p1' ? '김선수' : id,
      ),
    );
    expect(
      line.contains('왼발로') || line.contains('오른발로'),
      isTrue,
      reason: line,
    );
    expect(line.contains('어느 발로든'), isFalse, reason: line);
    expect(line.contains('슈팅으로 슈팅'), isFalse, reason: line);
  });

  test('foul commentary always names the victim', () {
    for (var seed = 0; seed < 20; seed++) {
      final e = MatchEventDto(
        matchMinute: 33,
        matchSecond: seed,
        type: 'foul',
        teamId: 'h',
        side: 'home',
        primaryPlayerId: 'fouler',
        fouledPlayerId: 'victim',
        metadata: {
          'schemaVersion': 1,
          'kind': 'foul',
          'payload': {'foulType': 'push'},
        },
        currentHomeScore: 0,
        currentAwayScore: 0,
      );
      final line = EventCommentGenerator.generate(
        e,
        CommentContext(
          matchSeed: seed,
          nameOf: (id) {
            if (id == 'fouler') return '김파울';
            if (id == 'victim') return '이피해';
            return id;
          },
        ),
      );
      expect(line.contains('김파울'), isTrue, reason: line);
      expect(line.contains('이피해'), isTrue, reason: line);
    }
  });

  test('shot ment aims or seeks chance, not fires twice', () {
    final shot = MatchEventDto(
      matchMinute: 12,
      matchSecond: 10,
      type: 'shot',
      teamId: 'h',
      side: 'home',
      primaryPlayerId: 'p1',
      metadata: {
        'schemaVersion': 1,
        'kind': 'shot',
        'payload': {
          'foot': 'right',
          'shotType': 'power',
          'distance': 'outside_box',
        },
      },
      currentHomeScore: 0,
      currentAwayScore: 0,
    );
    final save = MatchEventDto(
      matchMinute: 12,
      matchSecond: 12,
      type: 'save',
      teamId: 'a',
      side: 'away',
      primaryPlayerId: 'gk',
      secondaryPlayerId: 'p1',
      goalkeeperId: 'gk',
      currentHomeScore: 0,
      currentAwayScore: 0,
    );
    String nameOf(String? id) {
      if (id == 'p1') return '김슈터';
      if (id == 'gk') return '박키퍼';
      return id ?? '';
    }

    final shotLine = EventCommentGenerator.generate(
      shot,
      CommentContext(matchSeed: 1, nameOf: nameOf),
    );
    final saveLine = EventCommentGenerator.generate(
      save,
      CommentContext(matchSeed: 1, nameOf: nameOf),
    );

    expect(
      shotLine.contains('겨냥') ||
          shotLine.contains('찬스') ||
          shotLine.contains('노립'),
      isTrue,
      reason: shotLine,
    );
    expect(shotLine.contains('슈팅을 날립'), isFalse, reason: shotLine);
    expect(shotLine.contains('슈팅을 때립'), isFalse, reason: shotLine);

    expect(saveLine.contains('유효슈팅'), isTrue, reason: saveLine);
    expect(saveLine.contains('박키퍼'), isTrue, reason: saveLine);
    expect(
      saveLine.contains('선방') || saveLine.contains('걷어내'),
      isTrue,
      reason: saveLine,
    );

    final timeline = MatchEventCommentaryKo.filterForTimeline([shot, save]);
    expect(timeline.map((e) => e.type).toList(), ['shot', 'save']);
  });

  test('attack_build uses player style phrasing', () {
    final e = MatchEventDto(
      matchMinute: 8,
      matchSecond: 20,
      type: 'attack_build',
      teamId: 'h',
      side: 'home',
      primaryPlayerId: 'p1',
      metadata: {
        'schemaVersion': 1,
        'kind': 'attack_build',
        'payload': {'lane': 'center'},
        'styleContext': {
          'primaryStyleIds': ['speed', 'dribbler'],
        },
      },
      currentHomeScore: 0,
      currentAwayScore: 0,
    );
    final line = EventCommentGenerator.generate(
      e,
      CommentContext(
        matchSeed: 11,
        nameOf: (id) => id == 'p1' ? '이스피드' : id,
        homeName: '서울FC',
        awayName: '부산FC',
      ),
    );
    expect(line.contains('이스피드'), isTrue, reason: line);
    expect(line.contains('공격을 전개합니다'), isFalse, reason: line);
    expect(line.contains('[서울FC]'), isTrue, reason: line);
    expect(
      line.contains('드리블') ||
          line.contains('스피드') ||
          line.contains('질주') ||
          line.contains('돌파') ||
          line.contains('중원'),
      isTrue,
      reason: line,
    );
  });

  test('commentary prefixes team name from side', () {
    final e = MatchEventDto(
      matchMinute: 15,
      matchSecond: 0,
      type: 'foul',
      teamId: 'away-id',
      side: 'away',
      primaryPlayerId: 'f1',
      fouledPlayerId: 'v1',
      metadata: {
        'schemaVersion': 1,
        'kind': 'foul',
        'payload': {'foulType': 'trip'},
      },
      currentHomeScore: 0,
      currentAwayScore: 0,
    );
    final line = EventCommentGenerator.generate(
      e,
      CommentContext(
        matchSeed: 2,
        homeName: '홈유나이티드',
        awayName: '원정시티',
        nameOf: (id) => id == 'f1' ? 'A' : 'B',
      ),
    );
    expect(line.startsWith("15' [원정시티]"), isTrue, reason: line);
    expect(line.contains('홈유나이티드'), isFalse, reason: line);
  });
}
