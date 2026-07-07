class CoachAbility {
  const CoachAbility({
    required this.id,
    required this.name,
    required this.baseEffect,
    required this.rankEffects,
  });

  final String id;
  final String name;
  final String baseEffect;
  final Map<int, String> rankEffects;

  String effectForRank(int rank) {
    return rankEffects[rank.clamp(1, 5)] ?? baseEffect;
  }

  factory CoachAbility.fromJson(Map<String, dynamic> json) {
    final rawRankEffects = json['rank_effects'];
    final rankEffects = <int, String>{};
    if (rawRankEffects is Map) {
      for (final entry in rawRankEffects.entries) {
        final rank = int.tryParse('${entry.key}');
        if (rank != null) {
          rankEffects[rank] = '${entry.value}';
        }
      }
    }

    return CoachAbility(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseEffect: json['base_effect'] as String? ?? '',
      rankEffects: rankEffects,
    );
  }
}

class CoachStyle {
  const CoachStyle({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory CoachStyle.fromJson(Map<String, dynamic> json) {
    return CoachStyle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
