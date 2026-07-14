/// Parsed MatchEvent.metadata (schemaVersion 1).
class EventMeta {
  const EventMeta({
    required this.schemaVersion,
    required this.kind,
    required this.payload,
    this.primaryStyleIds = const [],
    this.secondaryStyleIds = const [],
  });

  final int schemaVersion;
  final String kind;
  final Map<String, dynamic> payload;
  final List<String> primaryStyleIds;
  final List<String> secondaryStyleIds;

  static EventMeta? tryParse(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final kind = raw['kind']?.toString();
    if (kind == null || kind.isEmpty) return null;
    final payloadRaw = raw['payload'];
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};
    final styleRaw = raw['styleContext'];
    List<String> primary = const [];
    List<String> secondary = const [];
    if (styleRaw is Map) {
      primary = _stringList(styleRaw['primaryStyleIds']);
      secondary = _stringList(styleRaw['secondaryStyleIds']);
    }
    return EventMeta(
      schemaVersion: _asInt(raw['schemaVersion'], 1),
      kind: kind,
      payload: payload,
      primaryStyleIds: primary,
      secondaryStyleIds: secondary,
    );
  }

  String? stringField(String key) {
    final v = payload[key];
    if (v == null) return null;
    return v.toString();
  }

  bool boolField(String key, [bool fallback = false]) {
    final v = payload[key];
    if (v is bool) return v;
    return fallback;
  }

  int intField(String key, [int fallback = 0]) {
    return _asInt(payload[key], fallback);
  }

  static List<String> _stringList(Object? v) {
    if (v is! List) return const [];
    return [for (final e in v) e.toString()];
  }

  static int _asInt(Object? v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }
}

class GoalMetaView {
  GoalMetaView(this.meta);

  final EventMeta meta;

  String? get foot => meta.stringField('foot');
  String? get shotType => meta.stringField('shotType');
  String? get distance => meta.stringField('distance');
  String? get bodyPart => meta.stringField('bodyPart');
  bool get afterDribble => meta.boolField('afterDribble');
  int get defendersBeaten => meta.intField('defendersBeaten');
  bool get keeperTouched => meta.boolField('keeperTouched');
  String? get assistType => meta.stringField('assistType');
  bool get counterAttack => meta.boolField('counterAttack');
  bool get oneOnOne => meta.boolField('oneOnOne');
}

class FoulMetaView {
  FoulMetaView(this.meta);
  final EventMeta meta;
  String? get foulType => meta.stringField('foulType');
}

class CardMetaView {
  CardMetaView(this.meta);
  final EventMeta meta;
  String? get reason => meta.stringField('reason');
  String? get linkedFoulType => meta.stringField('linkedFoulType');
}

class ShotMetaView {
  ShotMetaView(this.meta);
  final EventMeta meta;
  String? get foot => meta.stringField('foot');
  String? get shotType => meta.stringField('shotType');
  String? get distance => meta.stringField('distance');
  bool get blocked => meta.boolField('blocked');
  bool get saved => meta.boolField('saved');
  bool get offTarget => meta.boolField('offTarget');
  bool get hitPost => meta.boolField('hitPost');
  bool get afterDribble => meta.boolField('afterDribble');
  bool get counterAttack => meta.boolField('counterAttack');
  bool get oneOnOne => meta.boolField('oneOnOne');
  String? get assistType => meta.stringField('assistType');
}

class CornerMetaView {
  CornerMetaView(this.meta);
  final EventMeta meta;
  String? get cornerSide => meta.stringField('cornerSide');
}
