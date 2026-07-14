import 'dart:math';

import 'club_player.dart';
import 'coach.dart';
import 'formation.dart';
import 'player.dart';
import 'player_match_stats.dart';

enum GameLeagueTier {
  entry('entry', '엔트리 리그', 0),
  class1('class_1', '클래스 1', 1),
  class2('class_2', '클래스 2', 2),
  class3('class_3', '클래스 3', 3),
  class4('class_4', '클래스 4', 4),
  class5('class_5', '클래스 5', 5),
  class6('class_6', '클래스 6', 6),
  class7('class_7', '클래스 7', 7),
  class8('class_8', '클래스 8', 8),
  class9('class_9', '클래스 9', 9),
  class10('class_10', '클래스 10', 10);

  const GameLeagueTier(this.code, this.label, this.sortWeight);

  final String code;
  final String label;

  /// 낮을수록 하위 리그 (목록 정렬용).
  final int sortWeight;

  /// 승급·강등 전까지 전원 동일 임시 등수.
  static const temporaryStanding = 1;

  static GameLeagueTier fromCode(String? value) {
    final code = value ?? 'entry';
    for (final tier in GameLeagueTier.values) {
      if (tier.code == code) return tier;
    }
    // 레거시 second/first/pro
    return GameLeagueTier.entry;
  }
}

/// 선발 11명 기준 PK/FK/CK/Cap 역할 배정 결과.
class ClubSkillRoles {
  const ClubSkillRoles({
    required this.pkPlayerId,
    required this.fkPlayerId,
    required this.ckPlayerId,
    required this.captainPlayerId,
  });

  final String pkPlayerId;
  final String fkPlayerId;
  final String ckPlayerId;
  final String captainPlayerId;
}

class GameClub {
  const GameClub({
    this.id,
    this.guestId,
    this.userId,
    required this.clubName,
    required this.formation,
    required this.coach,
    required this.squad,
    this.pkPlayerId,
    this.fkPlayerId,
    this.ckPlayerId,
    this.captainPlayerId,
    this.leagueTier = GameLeagueTier.entry,
    this.clubLogoUrl,
    this.clubStats = const {},
    this.playerResults = const {},
    this.coachResults = const {},
  });

  /// 선발/후보 리스트로 구단을 만들 때 사용 (구단 생성 플로우).
  factory GameClub.fromStartersBench({
    String? id,
    String? guestId,
    String? userId,
    required String clubName,
    required Formation formation,
    required Coach coach,
    required List<Player> starters,
    required List<Player> bench,
    String? pkPlayerId,
    String? fkPlayerId,
    String? ckPlayerId,
    String? captainPlayerId,
    GameLeagueTier leagueTier = GameLeagueTier.entry,
    String? clubLogoUrl,
    Map<String, dynamic> clubStats = const {},
    Map<String, Map<String, dynamic>> playerResults = const {},
    Map<String, Map<String, dynamic>> coachResults = const {},
    DateTime? acquiredAt,
    Random? random,
  }) {
    final squad = ClubPlayer.fromStartersAndBench(
      starters: starters,
      bench: bench,
      acquiredAt: acquiredAt,
    );
    final defaults = assignDefaultRoles(starters, random: random);
    final seededResults = PlayerMatchStats.ensureForPlayerIds(
      playerIds: [for (final cp in squad) cp.playerId],
      existing: playerResults,
    );
    return GameClub(
      id: id,
      guestId: guestId,
      userId: userId,
      clubName: clubName,
      formation: formation,
      coach: coach,
      squad: squad,
      pkPlayerId: pkPlayerId ?? defaults?.pkPlayerId,
      fkPlayerId: fkPlayerId ?? defaults?.fkPlayerId,
      ckPlayerId: ckPlayerId ?? defaults?.ckPlayerId,
      captainPlayerId: captainPlayerId ?? defaults?.captainPlayerId,
      leagueTier: leagueTier,
      clubLogoUrl: clubLogoUrl,
      clubStats: clubStats,
      playerResults: seededResults,
      coachResults: coachResults,
    );
  }

  /// 선발 중 각 능력 최고자에게 PK/FK/CK/Cap 배정. 동점이면 [random]으로 선택.
  /// 역할은 서로 독립이므로 한 선수가 4개 모두 맡을 수 있다.
  static ClubSkillRoles? assignDefaultRoles(
    List<Player> starters, {
    Random? random,
  }) {
    if (starters.isEmpty) {
      return null;
    }
    final rng = random ?? Random();
    return ClubSkillRoles(
      pkPlayerId: pickBestByAbility(starters, (p) => p.pkAbility, rng),
      fkPlayerId: pickBestByAbility(starters, (p) => p.fkAbility, rng),
      ckPlayerId: pickBestByAbility(starters, (p) => p.ckAbility, rng),
      captainPlayerId: pickBestByAbility(starters, (p) => p.leadership, rng),
    );
  }

  /// 역할 보유자가 선발이 아니거나 null이면 해당 역할만 선발 기준으로 재배정.
  static ClubSkillRoles? ensureRolesOnStarters({
    required List<Player> starters,
    String? pkPlayerId,
    String? fkPlayerId,
    String? ckPlayerId,
    String? captainPlayerId,
    Random? random,
  }) {
    if (starters.isEmpty) {
      return null;
    }
    final rng = random ?? Random();
    final starterIds = {for (final p in starters) p.id};

    String resolve(String? current, int Function(Player) ability) {
      if (current != null && starterIds.contains(current)) {
        return current;
      }
      return pickBestByAbility(starters, ability, rng);
    }

    return ClubSkillRoles(
      pkPlayerId: resolve(pkPlayerId, (p) => p.pkAbility),
      fkPlayerId: resolve(fkPlayerId, (p) => p.fkAbility),
      ckPlayerId: resolve(ckPlayerId, (p) => p.ckAbility),
      captainPlayerId: resolve(captainPlayerId, (p) => p.leadership),
    );
  }

  /// 능력치가 가장 높은 선수 ID. 동점이면 [random]으로 한 명 선택.
  static String pickBestByAbility(
    List<Player> starters,
    int Function(Player) abilityOf,
    Random random,
  ) {
    assert(starters.isNotEmpty);
    var max = abilityOf(starters.first);
    for (var i = 1; i < starters.length; i++) {
      final v = abilityOf(starters[i]);
      if (v > max) {
        max = v;
      }
    }
    final tied = [
      for (final p in starters)
        if (abilityOf(p) == max) p,
    ];
    return tied[random.nextInt(tied.length)].id;
  }

  /// 선발↔후보 스왑: [fromPlayerId]가 가진 역할을 [toPlayerId]에게 이전.
  static ClubSkillRoles transferRoles({
    required String fromPlayerId,
    required String toPlayerId,
    required String pkPlayerId,
    required String fkPlayerId,
    required String ckPlayerId,
    required String captainPlayerId,
  }) {
    return ClubSkillRoles(
      pkPlayerId: pkPlayerId == fromPlayerId ? toPlayerId : pkPlayerId,
      fkPlayerId: fkPlayerId == fromPlayerId ? toPlayerId : fkPlayerId,
      ckPlayerId: ckPlayerId == fromPlayerId ? toPlayerId : ckPlayerId,
      captainPlayerId:
          captainPlayerId == fromPlayerId ? toPlayerId : captainPlayerId,
    );
  }

  final String? id;
  final String? guestId;
  final String? userId;
  final String clubName;
  final Formation formation;
  final Coach coach;
  final List<ClubPlayer> squad;
  final String? pkPlayerId;
  final String? fkPlayerId;
  final String? ckPlayerId;
  final String? captainPlayerId;
  final GameLeagueTier leagueTier;
  final String? clubLogoUrl;

  /// 추후 승점, 재정, 시설, 팬 수 같은 구단 단위 저장 공간.
  final Map<String, dynamic> clubStats;

  /// 추후 선수별 골, 도움, 평점, 컨디션 저장 공간. key는 playerId.
  final Map<String, Map<String, dynamic>> playerResults;

  /// 추후 감독별 전술 결과, 승률, 컵 성적 저장 공간. key는 coachId.
  final Map<String, Map<String, dynamic>> coachResults;

  PlayerMatchStats matchStatsFor(String playerId) {
    return PlayerMatchStats.fromJson(playerResults[playerId]);
  }

  /// 스쿼드에 없는 기록은 유지하고, 스쿼드 전원 0값 보장.
  GameClub withEnsuredPlayerResults() {
    final seeded = PlayerMatchStats.ensureForPlayerIds(
      playerIds: [for (final cp in squad) cp.playerId],
      existing: playerResults,
    );
    if (seeded.length == playerResults.length &&
        seeded.keys.every(playerResults.containsKey)) {
      return this;
    }
    return copyWith(playerResults: seeded);
  }

  List<ClubPlayer> get starterClubPlayers {
    final list = squad.where((p) => p.isStarter).toList()
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    return list;
  }

  List<ClubPlayer> get benchClubPlayers {
    final list = squad.where((p) => p.isBench).toList()
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    return list;
  }

  List<Player> get starters => [
        for (final cp in starterClubPlayers) cp.player,
      ];

  List<Player> get bench => [
        for (final cp in benchClubPlayers) cp.player,
      ];

  ClubPlayer? clubPlayerAt(int positionIndex) {
    for (final cp in squad) {
      if (cp.positionIndex == positionIndex) {
        return cp;
      }
    }
    return null;
  }

  ClubPlayer? clubPlayerById(String playerId) {
    for (final cp in squad) {
      if (cp.playerId == playerId) {
        return cp;
      }
    }
    return null;
  }

  int get teamPower {
    var sum = 0;
    for (final cp in starterClubPlayers) {
      final p = cp.player;
      sum += p.speed +
          p.power +
          p.technique +
          p.shooting +
          p.passing +
          p.stamina;
    }
    return sum;
  }

  String get leagueTierCode => leagueTier.code;

  int get leagueStanding => GameLeagueTier.temporaryStanding;

  GameClub copyWith({
    String? id,
    String? guestId,
    String? userId,
    String? clubName,
    Formation? formation,
    Coach? coach,
    List<ClubPlayer>? squad,
    String? pkPlayerId,
    String? fkPlayerId,
    String? ckPlayerId,
    String? captainPlayerId,
    bool clearPkPlayerId = false,
    bool clearFkPlayerId = false,
    bool clearCkPlayerId = false,
    bool clearCaptainPlayerId = false,
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
      squad: squad ?? this.squad,
      pkPlayerId: clearPkPlayerId ? null : (pkPlayerId ?? this.pkPlayerId),
      fkPlayerId: clearFkPlayerId ? null : (fkPlayerId ?? this.fkPlayerId),
      ckPlayerId: clearCkPlayerId ? null : (ckPlayerId ?? this.ckPlayerId),
      captainPlayerId: clearCaptainPlayerId
          ? null
          : (captainPlayerId ?? this.captainPlayerId),
      leagueTier: leagueTier ?? this.leagueTier,
      clubLogoUrl: clubLogoUrl ?? this.clubLogoUrl,
      clubStats: clubStats ?? this.clubStats,
      playerResults: playerResults ?? this.playerResults,
      coachResults: coachResults ?? this.coachResults,
    );
  }
}
