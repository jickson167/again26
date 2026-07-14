/// 구단 내 선수별 유저 누적 기록 (경기/득점/어시 등).
class PlayerMatchStats {
  const PlayerMatchStats({
    this.matches = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.rating = 0.0,
  });

  final int matches;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final double rating;

  static const zeros = PlayerMatchStats();

  factory PlayerMatchStats.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return zeros;
    return PlayerMatchStats(
      matches: _int(json['matches'] ?? json['경기']),
      goals: _int(json['goals'] ?? json['득점']),
      assists: _int(json['assists'] ?? json['어시스트']),
      yellowCards: _int(json['yellow_cards'] ?? json['yellowCards'] ?? json['옐로우']),
      redCards: _int(json['red_cards'] ?? json['redCards'] ?? json['레드'] ?? json['퇴장']),
      rating: _double(json['rating'] ?? json['평점']),
    );
  }

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'goals': goals,
        'assists': assists,
        'yellow_cards': yellowCards,
        'red_cards': redCards,
        'rating': rating,
      };

  /// 스쿼드 전원에 0값 기록을 보장 (기존 값이 있으면 유지).
  static Map<String, Map<String, dynamic>> ensureForPlayerIds({
    required Iterable<String> playerIds,
    Map<String, Map<String, dynamic>> existing = const {},
  }) {
    final out = <String, Map<String, dynamic>>{
      for (final e in existing.entries)
        e.key: Map<String, dynamic>.from(e.value),
    };
    for (final id in playerIds) {
      if (id.isEmpty) continue;
      out.putIfAbsent(id, () => zeros.toJson());
    }
    return out;
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _double(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
