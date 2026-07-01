class PlayerGrowth {
  const PlayerGrowth({
    required this.speed,
    required this.power,
    required this.technique,
  });

  final int speed;
  final int power;
  final int technique;

  factory PlayerGrowth.empty() {
    return const PlayerGrowth(speed: 0, power: 0, technique: 0);
  }

  factory PlayerGrowth.fromJson(Map<String, dynamic> json) {
    return PlayerGrowth(
      speed: _clampStat(json['speed']),
      power: _clampStat(json['power']),
      technique: _clampStat(json['technique']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speed': speed,
      'power': power,
      'technique': technique,
    };
  }

  PlayerGrowth copyWith({int? speed, int? power, int? technique}) {
    return PlayerGrowth(
      speed: speed ?? this.speed,
      power: power ?? this.power,
      technique: technique ?? this.technique,
    );
  }

  static int _clampStat(dynamic value) {
    final parsed = value is int ? value : int.tryParse('$value') ?? 0;
    return parsed.clamp(0, 10);
  }
}
