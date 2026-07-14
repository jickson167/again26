import '../../models/match_simulation_dto.dart';
import 'dictionary_bank.dart';
import 'meta/event_meta.dart';
import 'seeded_random.dart';
import 'slot_resolver.dart';
import 'template_models.dart';
import 'template_registry.dart';

export 'dictionary_bank.dart';
export 'meta/event_meta.dart';
export 'seeded_random.dart';
export 'template_models.dart';
export 'template_registry.dart';

/// Template + dictionary commentary (no LLM).
class EventCommentGenerator {
  EventCommentGenerator._();

  static final TemplateRegistry _registry = TemplateRegistry.instance;

  static String generate(MatchEventDto event, CommentContext ctx) {
    final meta = EventMeta.tryParse(event.metadata);
    final pool = _registry.matching(
      eventType: event.type,
      event: event,
      meta: meta,
    );
    if (pool.isEmpty) {
      final t = "${event.matchMinute.toString().padLeft(2, '0')}'";
      return _withTeamPrefix('$t ${event.type}', event, ctx);
    }

    final seed = commentarySeed(
      matchSeed: ctx.matchSeed,
      minute: event.matchMinute,
      second: event.matchSecond,
      type: event.type,
      primaryPlayerId: event.primaryPlayerId,
    );
    final rng = SeededRandom(seed);
    final template = rng.weightedPick([
      for (final t in pool) (value: t, w: t.weight),
    ]);

    final body = SlotResolver.fill(
      template: template,
      event: event,
      meta: meta,
      ctx: ctx,
      rng: rng,
    );
    return _withTeamPrefix(body, event, ctx);
  }

  static String teamLabel(MatchEventDto event, CommentContext ctx) {
    if (event.side == 'home') {
      final n = ctx.homeName?.trim();
      return (n != null && n.isNotEmpty) ? n : '홈';
    }
    if (event.side == 'away') {
      final n = ctx.awayName?.trim();
      return (n != null && n.isNotEmpty) ? n : '원정';
    }
    return event.side;
  }

  /// `12' text` → `12' [팀명] text`
  static String _withTeamPrefix(
    String line,
    MatchEventDto event,
    CommentContext ctx,
  ) {
    final team = teamLabel(event, ctx);
    final m = RegExp(r"^(\d{1,2}')\s+(.*)$").firstMatch(line);
    if (m == null) return '[$team] $line';
    return "${m.group(1)} [$team] ${m.group(2)}";
  }

  /// For diversity tests: generate many lines across seeds/meta variants.
  static Set<String> sampleGoalLines({
    required int matchSeed,
    required int sampleCount,
  }) {
    final out = <String>{};
    final variants = _goalMetaVariants();
    var i = 0;
    while (out.length < sampleCount && i < sampleCount * 20) {
      final meta = variants[i % variants.length];
      final e = MatchEventDto(
        matchMinute: 10 + (i % 80),
        matchSecond: i % 60,
        type: 'goal',
        teamId: 'h',
        side: 'home',
        primaryPlayerId: 'p1',
        secondaryPlayerId: meta['assistType'] != null ? 'p2' : null,
        metadata: {
          'schemaVersion': 1,
          'kind': 'goal',
          'payload': meta,
          'styleContext': {
            'primaryStyleIds': ['finisher', 'dribbler'],
            'secondaryStyleIds': ['playmaker'],
          },
        },
        currentHomeScore: 1,
        currentAwayScore: 0,
      );
      final line = generate(
        e,
        CommentContext(
          matchSeed: matchSeed + i,
          nameOf: (id) {
            if (id == 'p1') return '김공격';
            if (id == 'p2') return '이도움';
            return id;
          },
        ),
      );
      out.add(line);
      i++;
    }
    return out;
  }

  static List<Map<String, dynamic>> _goalMetaVariants() {
    final shotTypes = [
      'power',
      'placement',
      'curler',
      'chip',
      'volley',
      'header',
      'tapin',
      'outside_foot',
    ];
    final distances = ['inside_box', 'outside_box', 'long_range'];
    final assists = [null, 'through', 'cross', 'cutback', 'rebound', 'corner'];
    final foots = ['left', 'right', 'both', null];
    final list = <Map<String, dynamic>>[];
    for (final st in shotTypes) {
      for (final d in distances) {
        for (final a in assists) {
          if (st == 'tapin' && d == 'long_range') continue;
          if (st == 'header' && a == 'through') continue;
          list.add({
            'foot': st == 'header' ? null : foots[(list.length) % foots.length],
            'shotType': st,
            'distance': d,
            'bodyPart': st == 'header' ? 'head' : 'foot',
            'afterDribble': list.length % 3 == 0,
            'defendersBeaten': list.length % 4,
            'keeperTouched': list.length % 5 == 0,
            'assistType': ?a,
            'counterAttack': list.length % 4 == 1,
            'oneOnOne': a == 'through' || list.length % 7 == 0,
          });
        }
      }
    }
    return list;
  }

  static int goalTemplateCount() => _registry.goalTemplateCount;

  static int goalDictionaryCount() => DictionaryBank.goalDictionaryEntryCount();
}
