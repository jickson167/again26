import '../../models/match_simulation_dto.dart';
import 'catalogs/goal_templates.dart';
import 'catalogs/other_templates.dart';
import 'meta/event_meta.dart';
import 'template_models.dart';

class TemplateRegistry {
  TemplateRegistry._() {
    _all = [
      ...buildGoalTemplates(),
      ...buildShotTemplates(),
      ...buildFoulTemplates(),
      ...buildCardTemplates(),
      ...buildCornerTemplates(),
      ...buildMiscTemplates(),
    ];
  }

  static final TemplateRegistry instance = TemplateRegistry._();

  late final List<CommentTemplate> _all;

  List<CommentTemplate> allForType(String eventType) =>
      [for (final t in _all) if (t.eventType == eventType) t];

  List<CommentTemplate> matching({
    required String eventType,
    required MatchEventDto event,
    required EventMeta? meta,
  }) {
    final pool = allForType(eventType);
    final matched = [
      for (final t in pool)
        if (_matches(t, event, meta)) t,
    ];
    if (matched.isNotEmpty) return matched;
    // Fall back to unconstrained templates of same type
    final loose = [
      for (final t in pool) if (t.when.isEmpty) t,
    ];
    return loose.isNotEmpty ? loose : pool;
  }

  static bool _matches(
    CommentTemplate t,
    MatchEventDto event,
    EventMeta? meta,
  ) {
    if (t.when.isEmpty) return true;
    final goal = meta != null ? GoalMetaView(meta) : null;
    final foul = meta != null ? FoulMetaView(meta) : null;
    final card = meta != null ? CardMetaView(meta) : null;
    final shot = meta != null ? ShotMetaView(meta) : null;
    final corner = meta != null ? CornerMetaView(meta) : null;
    final hasAssist = event.secondaryPlayerId != null &&
        event.secondaryPlayerId!.isNotEmpty &&
        event.type == 'goal';

    for (final entry in t.when.entries) {
      final key = entry.key;
      final expected = entry.value;
      switch (key) {
        case 'requireAssist':
          if (expected is bool && expected != hasAssist) return false;
          break;
        case 'afterDribble':
          if (expected is bool && (goal?.afterDribble ?? false) != expected) {
            return false;
          }
          break;
        case 'counterAttack':
          if (expected is bool && (goal?.counterAttack ?? false) != expected) {
            return false;
          }
          break;
        case 'oneOnOne':
          if (expected is bool && (goal?.oneOnOne ?? false) != expected) {
            return false;
          }
          break;
        case 'keeperTouched':
          if (expected is bool && (goal?.keeperTouched ?? false) != expected) {
            return false;
          }
          break;
        case 'minDefendersBeaten':
          if (expected is int &&
              (goal?.defendersBeaten ?? 0) < expected) {
            return false;
          }
          break;
        case 'offTarget':
          if (expected is bool && (shot?.offTarget ?? false) != expected) {
            return false;
          }
          break;
        case 'hitPost':
          if (expected is bool &&
              (shot?.hitPost ?? event.type == 'shot_woodwork') != expected) {
            return false;
          }
          break;
        case 'saved':
          if (expected is bool &&
              (shot?.saved ?? event.type == 'save') != expected) {
            return false;
          }
          break;
        case 'shotType':
          if (!_listContains(expected, goal?.shotType ?? shot?.shotType)) {
            return false;
          }
          break;
        case 'distance':
          if (!_listContains(expected, goal?.distance ?? shot?.distance)) {
            return false;
          }
          break;
        case 'foot':
          if (!_listContains(expected, goal?.foot ?? shot?.foot)) {
            return false;
          }
          break;
        case 'assistType':
          if (!_listContains(expected, goal?.assistType ?? shot?.assistType)) {
            return false;
          }
          break;
        case 'cornerSide':
          if (!_listContains(expected, corner?.cornerSide)) return false;
          break;
        case 'foulType':
          if (!_listContains(expected, foul?.foulType)) return false;
          break;
        case 'reason':
          if (!_listContains(expected, card?.reason)) return false;
          break;
        default:
          break;
      }
    }
    return true;
  }

  static bool _listContains(Object? expected, String? actual) {
    if (expected is! List) return true;
    if (actual == null) return false;
    return expected.map((e) => e.toString()).contains(actual);
  }

  int get goalTemplateCount =>
      allForType('goal').length;
}
