class Coach {
  const Coach({
    required this.id,
    required this.name,
    this.fakeName,
    this.nationality,
    this.age,
    this.rank,
    required this.coachType,
    required this.baseLeadership,
    required this.abilityId,
    required this.abilityName,
    required this.abilityEffect,
    this.fitGood = const [],
    this.fitNormal = const [],
    this.fitBad = const [],
    required this.leadershipCurve,
    this.comment,
    this.portraitUrl,
    this.createdAt,
    this.updatedAt,
  });

  static const leadershipPeriodCount = 18;
  static const baseFormationUnlockCount = 4;

  final String id;
  final String name;
  final String? fakeName;
  final String? nationality;
  final int? age;
  final int? rank;
  final String coachType;
  final int baseLeadership;
  final String abilityId;
  final String abilityName;
  final String abilityEffect;
  final List<String> fitGood;
  final List<String> fitNormal;
  final List<String> fitBad;
  final List<int> leadershipCurve;
  final String? comment;
  final String? portraitUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get abilityBonusTotal {
    final matches = RegExp(r'\+(\d+)').allMatches(abilityEffect);
    return matches
        .map((match) => int.tryParse(match.group(1) ?? '') ?? 0)
        .fold<int>(0, (sum, value) => sum + value);
  }

  int get calculatedRank {
    final score = baseLeadership + abilityBonusTotal;
    if (score >= 110) return 5;
    if (score >= 95) return 4;
    if (score >= 80) return 3;
    if (score >= 65) return 2;
    return 1;
  }

  int get effectiveRank => (rank ?? calculatedRank).clamp(1, 5);

  int get unlockFormationCount => baseFormationUnlockCount + effectiveRank - 1;

  int get maxGoodFitCount => 3 + effectiveRank;

  int get maxNormalFitCount => 2 + effectiveRank;

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] as String? ?? json['coach_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fakeName: json['fake_name'] as String?,
      nationality: json['nationality'] as String?,
      age: _parseInt(json['age']),
      rank: _parseInt(json['rank']),
      coachType: json['coach_type'] as String? ?? '',
      baseLeadership: _parseInt(json['base_leadership'])?.clamp(0, 100) ?? 0,
      abilityId: json['ability_id'] as String? ?? '',
      abilityName: json['ability_name'] as String? ?? '',
      abilityEffect: json['ability_effect'] as String? ?? '',
      fitGood: _parseStringList(json['fit_good']),
      fitNormal: _parseStringList(json['fit_normal']),
      fitBad: _parseStringList(json['fit_bad']),
      leadershipCurve: _normalizeLeadershipCurve(_parseIntList(json['leadership_curve'])),
      comment: json['comment'] as String?,
      portraitUrl: json['portrait_url'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'fake_name': fakeName,
      'nationality': nationality,
      'age': age,
      'rank': rank,
      'coach_type': coachType,
      'base_leadership': baseLeadership,
      'ability_id': abilityId,
      'ability_name': abilityName,
      'ability_effect': abilityEffect,
      'fit_good': fitGood,
      'fit_normal': fitNormal,
      'fit_bad': fitBad,
      'leadership_curve': leadershipCurve,
      'comment': comment,
      'portrait_url': portraitUrl,
    };
  }

  Coach copyWith({
    String? id,
    String? name,
    String? fakeName,
    String? nationality,
    int? age,
    int? rank,
    String? coachType,
    int? baseLeadership,
    String? abilityId,
    String? abilityName,
    String? abilityEffect,
    List<String>? fitGood,
    List<String>? fitNormal,
    List<String>? fitBad,
    List<int>? leadershipCurve,
    String? comment,
    String? portraitUrl,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      fakeName: fakeName ?? this.fakeName,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      rank: rank ?? this.rank,
      coachType: coachType ?? this.coachType,
      baseLeadership: baseLeadership ?? this.baseLeadership,
      abilityId: abilityId ?? this.abilityId,
      abilityName: abilityName ?? this.abilityName,
      abilityEffect: abilityEffect ?? this.abilityEffect,
      fitGood: fitGood ?? this.fitGood,
      fitNormal: fitNormal ?? this.fitNormal,
      fitBad: fitBad ?? this.fitBad,
      leadershipCurve: leadershipCurve ?? this.leadershipCurve,
      comment: comment ?? this.comment,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<int> defaultLeadershipCurve() {
    return const [
      60, 66, 72, 78, 84, 88, 90, 91, 90, 88, 85, 80, 72, 62, 45, 25, 10, 0,
    ];
  }

  static int? _parseInt(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) {
      return null;
    }
    return int.tryParse('$value');
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value.map((item) => '$item'.trim()).where((item) => item.isNotEmpty).toList();
    }
    return '$value'
        .split(RegExp(r'[|;；,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _parseIntList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value.map((item) => _parseInt(item) ?? 0).toList();
    }
    return '$value'
        .split(RegExp(r'[|;；,]'))
        .map((item) => int.tryParse(item.trim()) ?? 0)
        .toList();
  }

  static List<int> _normalizeLeadershipCurve(List<int> curve) {
    final result = curve.map((value) => value.clamp(0, 100)).toList();
    while (result.length < leadershipPeriodCount) {
      result.add(0);
    }
    return result.take(leadershipPeriodCount).toList();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse('$value');
  }
}
