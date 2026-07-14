class CommentTemplate {
  const CommentTemplate({
    required this.id,
    required this.eventType,
    required this.text,
    this.weight = 1.0,
    this.when = const {},
  });

  final String id;
  final String eventType;
  final String text;
  final double weight;

  /// AND of keys; list values are OR. Special keys:
  /// - requireAssist: bool
  /// - afterDribble / counterAttack / oneOnOne / keeperTouched: bool
  /// - minDefendersBeaten: int
  final Map<String, Object?> when;
}

class CommentContext {
  const CommentContext({
    required this.nameOf,
    required this.matchSeed,
    this.homeName,
    this.awayName,
  });

  final String? Function(String? id) nameOf;
  final int matchSeed;
  final String? homeName;
  final String? awayName;
}
