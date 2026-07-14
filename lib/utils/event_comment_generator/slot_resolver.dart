import '../../models/match_simulation_dto.dart';
import 'dictionary_bank.dart';
import 'meta/event_meta.dart';
import 'seeded_random.dart';
import 'template_models.dart';

class SlotResolver {
  SlotResolver._();

  static String fill({
    required CommentTemplate template,
    required MatchEventDto event,
    required EventMeta? meta,
    required CommentContext ctx,
    required SeededRandom rng,
  }) {
    // save: primary=GK, secondary=shooter
    // goal/shot: primary=shooter, secondary=assist
    final isSave = event.type == 'save' || event.type == 'shot_saved';
    final shooterId =
        isSave ? event.secondaryPlayerId : event.primaryPlayerId;
    final scorer = ctx.nameOf(shooterId) ?? '선수';
    final assist = isSave
        ? ''
        : (ctx.nameOf(event.secondaryPlayerId) ?? '');
    final gk = ctx.nameOf(event.goalkeeperId) ??
        (isSave ? ctx.nameOf(event.primaryPlayerId) : null) ??
        '골키퍼';
    final victim = ctx.nameOf(event.fouledPlayerId) ?? '상대';
    final outPlayer = ctx.nameOf(event.substitutedOutPlayerId) ?? '?';
    final inPlayer = ctx.nameOf(event.substitutedInPlayerId) ?? '?';
    final time = "${event.matchMinute.toString().padLeft(2, '0')}'";
    final score = '${event.currentHomeScore}-${event.currentAwayScore}';

    final goal = meta != null ? GoalMetaView(meta) : null;
    final foul = meta != null ? FoulMetaView(meta) : null;
    final card = meta != null ? CardMetaView(meta) : null;
    final shot = meta != null ? ShotMetaView(meta) : null;
    final corner = meta != null ? CornerMetaView(meta) : null;

    final shotType = goal?.shotType ?? shot?.shotType;
    final foot = goal?.foot ?? shot?.foot;
    final bodyPart = goal?.bodyPart;
    final distance = goal?.distance ?? shot?.distance;
    final assistType = goal?.assistType ?? shot?.assistType;
    final foulType = foul?.foulType ?? card?.linkedFoulType;
    final reason = card?.reason;
    final styles = meta?.primaryStyleIds ?? const <String>[];
    final lane = meta?.stringField('lane');

    String styleTone() {
      if (styles.isEmpty) return '';
      final id = rng.pick(styles);
      final tones = DictionaryBank.styleTone[id];
      if (tones == null || tones.isEmpty) return '';
      return ' ${rng.pick(tones)}';
    }

    String attackBuildAction() {
      final candidates = <String>[];
      for (final id in styles) {
        final list = DictionaryBank.attackBuildByStyle[id];
        if (list != null) candidates.addAll(list);
      }
      if (candidates.isNotEmpty) {
        return rng.pick(candidates);
      }
      if (lane != null) {
        final byLane = DictionaryBank.attackBuildByLane[lane];
        if (byLane != null && byLane.isNotEmpty) {
          return rng.pick(byLane);
        }
      }
      return rng.pick(DictionaryBank.attackBuildDefault);
    }

    String lanePhrase() {
      switch (lane) {
        case 'left':
          return '왼쪽에서';
        case 'right':
          return '오른쪽에서';
        case 'center':
          return '중앙에서';
        default:
          return '';
      }
    }

    String shotOutcome() {
      if (shot?.hitPost == true || event.type == 'shot_woodwork') {
        return DictionaryBank.pick(rng, DictionaryBank.shotOutcome['hitPost']!);
      }
      if (shot?.saved == true || event.type == 'save') {
        return DictionaryBank.pick(rng, DictionaryBank.shotOutcome['saved']!);
      }
      if (shot?.blocked == true) {
        return DictionaryBank.pick(rng, DictionaryBank.shotOutcome['blocked']!);
      }
      return DictionaryBank.pick(rng, DictionaryBank.shotOutcome['offTarget']!);
    }

    String cornerSidePhrase() {
      final side = corner?.cornerSide;
      if (side == 'far') {
        return DictionaryBank.pick(rng, DictionaryBank.cornerFar);
      }
      return DictionaryBank.pick(rng, DictionaryBank.cornerNear);
    }

    final map = <String, String Function()>{
      'time': () => time,
      'score': () => score,
      'scorer': () => scorer,
      'shooter': () => scorer,
      'assist': () => assist.isEmpty ? '동료' : assist,
      'gk': () => gk,
      'victim': () => victim,
      'outPlayer': () => outPlayer,
      'inPlayer': () => inPlayer,
      'intensity': () => DictionaryBank.pick(rng, DictionaryBank.intensity),
      'reaction': () => DictionaryBank.pick(rng, DictionaryBank.reaction),
      'connector': () => DictionaryBank.pick(rng, DictionaryBank.connector),
      'shotVerb': () => DictionaryBank.pickKeyed(
            rng,
            DictionaryBank.shotVerb,
            shotType,
            fallback: '슈팅으로',
          ),
      'footPhrase': () {
        // header: no foot; both → pick left or right for natural Korean
        if (shotType == 'header' || bodyPart == 'head') return '';
        var key = foot;
        if (key == null || key == 'both' || key.isEmpty) {
          key = rng.boolChance(0.6) ? 'right' : 'left';
        }
        return DictionaryBank.pickKeyed(
          rng,
          DictionaryBank.footPhrase,
          key,
          fallback: rng.boolChance(0.6) ? '오른발로' : '왼발로',
        );
      },
      'distancePhrase': () => DictionaryBank.pickKeyed(
            rng,
            DictionaryBank.distancePhrase,
            distance,
            fallback: '',
          ),
      'assistLead': () => DictionaryBank.pickKeyed(
            rng,
            DictionaryBank.assistLead,
            assistType,
            fallback: '패스',
          ),
      'headerVerb': () => DictionaryBank.pick(rng, DictionaryBank.headerVerb),
      'dribblePhrase': () =>
          DictionaryBank.pick(rng, DictionaryBank.dribblePhrase),
      'oneOnOnePhrase': () =>
          DictionaryBank.pick(rng, DictionaryBank.oneOnOnePhrase),
      'counterPhrase': () =>
          DictionaryBank.pick(rng, DictionaryBank.counterPhrase),
      'keeperTouchPhrase': () =>
          DictionaryBank.pick(rng, DictionaryBank.keeperTouchPhrase),
      'foulPhrase': () => DictionaryBank.pickKeyed(
            rng,
            DictionaryBank.foulPhrase,
            foulType,
            fallback: '파울',
          ),
      'foulTypeKo': () =>
          DictionaryBank.foulTypeKo[foulType ?? ''] ?? foulType ?? '파울',
      'reasonPhrase': () => DictionaryBank.pickKeyed(
            rng,
            DictionaryBank.reasonPhrase,
            reason,
            fallback: '반칙으로',
          ),
      'cardNoun': () => event.type == 'red_card'
          ? DictionaryBank.pick(rng, DictionaryBank.cardNounRed)
          : DictionaryBank.pick(rng, DictionaryBank.cardNounYellow),
      'shotOutcome': shotOutcome,
      'cornerSidePhrase': cornerSidePhrase,
      'defendersBeaten': () => '${goal?.defendersBeaten ?? 0}',
      'styleTone': styleTone,
      'attackBuildAction': attackBuildAction,
      'lanePhrase': lanePhrase,
    };

    var text = template.text;
    // Optional slots: {name?} — removed with surrounding space if empty
    text = text.replaceAllMapped(RegExp(r'\{(\w+)\?}'), (m) {
      final key = m.group(1)!;
      final fn = map[key];
      final v = fn?.call() ?? '';
      return v;
    });
    text = text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
      final key = m.group(1)!;
      final fn = map[key];
      return fn?.call() ?? m.group(0)!;
    });

    return _normalize(text);
  }

  static String _normalize(String s) {
    return s
        .replaceAll(RegExp(r' +'), ' ')
        .replaceAll(RegExp(r' +([,.!])'), r'$1')
        .replaceAll(' .', '.')
        .trim();
  }
}
