import 'coach.dart';
import 'formation.dart';
import 'player.dart';

enum GameLeagueTier {
  second('2부 리그'),
  first('1부 리그'),
  pro('프로리그');

  const GameLeagueTier(this.label);

  final String label;
}

class GameClub {
  const GameClub({
    this.id,
    this.guestId,
    this.userId,
    required this.clubName,
    required this.formation,
    required this.coach,
    required this.starters,
    required this.bench,
    this.leagueTier = GameLeagueTier.second,
    this.clubLogoUrl,
    this.clubStats = const {},
    this.playerResults = const {},
    this.coachResults = const {},
  });

  final String? id;
  final String? guestId;
  final String? userId;
  final String clubName;
  final Formation formation;
  final Coach coach;
  final List<Player> starters;
  final List<Player> bench;
  final GameLeagueTier leagueTier;
  final String? clubLogoUrl;

  /// 추후 승점, 재정, 시설, 팬 수 같은 구단 단위 저장 공간.
  final Map<String, dynamic> clubStats;

  /// 추후 선수별 골, 도움, 평점, 컨디션 저장 공간. key는 playerId.
  final Map<String, Map<String, dynamic>> playerResults;

  /// 추후 감독별 전술 결과, 승률, 컵 성적 저장 공간. key는 coachId.
  final Map<String, Map<String, dynamic>> coachResults;

  String get leagueTierCode {
    return switch (leagueTier) {
      GameLeagueTier.second => 'second',
      GameLeagueTier.first => 'first',
      GameLeagueTier.pro => 'pro',
    };
  }

  GameClub copyWith({
    String? id,
    String? guestId,
    String? userId,
    String? clubName,
    Formation? formation,
    Coach? coach,
    List<Player>? starters,
    List<Player>? bench,
    GameLeagueTier? leagueTier,
    String? clubLogoUrl,
    Map<String, dynamic>? clubStats,
    Map<String, Map<String, dynamic>>? playerResults,
    Map<String, Map<String, dynamic>>? coachResults,
  }) {
    return GameClub(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      userId: userId ?? this.userId,
      clubName: clubName ?? this.clubName,
      formation: formation ?? this.formation,
      coach: coach ?? this.coach,
      starters: starters ?? this.starters,
      bench: bench ?? this.bench,
      leagueTier: leagueTier ?? this.leagueTier,
      clubLogoUrl: clubLogoUrl ?? this.clubLogoUrl,
      clubStats: clubStats ?? this.clubStats,
      playerResults: playerResults ?? this.playerResults,
      coachResults: coachResults ?? this.coachResults,
    );
  }
}
