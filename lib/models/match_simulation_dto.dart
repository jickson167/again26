// DTOs for simulate-match Edge Function responses (display only — no calc).

class MatchSimApiResponse {
  const MatchSimApiResponse({
    required this.ok,
    required this.dryRun,
    required this.persisted,
    required this.dbAccumulation,
    this.warning,
    this.result,
    this.error,
    this.raw,
  });

  final bool ok;
  final bool dryRun;
  final bool persisted;
  final bool dbAccumulation;
  final String? warning;
  final MatchSimulationResultDto? result;
  final String? error;
  final Map<String, dynamic>? raw;

  factory MatchSimApiResponse.fromJson(Map<String, dynamic> json) {
    final resultRaw = json['result'];
    return MatchSimApiResponse(
      ok: json['ok'] == true,
      dryRun: json['dryRun'] != false,
      persisted: json['persisted'] == true,
      dbAccumulation: json['dbAccumulation'] == true,
      warning: json['warning']?.toString(),
      result: resultRaw is Map
          ? MatchSimulationResultDto.fromJson(
              Map<String, dynamic>.from(resultRaw),
            )
          : null,
      error: json['error']?.toString(),
      raw: json,
    );
  }
}

class MatchSimulationResultDto {
  const MatchSimulationResultDto({
    required this.matchId,
    required this.seed,
    required this.simulationVersion,
    required this.homeScore,
    required this.awayScore,
    required this.homeClubId,
    required this.awayClubId,
    this.homeClubName,
    this.awayClubName,
    required this.events,
    required this.statistics,
    required this.playerMatchStats,
    this.mvpPlayerId,
  });

  final String matchId;
  final int seed;
  final String simulationVersion;
  final int homeScore;
  final int awayScore;
  final String homeClubId;
  final String awayClubId;
  final String? homeClubName;
  final String? awayClubName;
  final List<MatchEventDto> events;
  final MatchStatisticsDto statistics;
  final List<PlayerMatchStatsDto> playerMatchStats;
  final String? mvpPlayerId;

  factory MatchSimulationResultDto.fromJson(Map<String, dynamic> json) {
    final statsList = json['playerMatchStats'] ?? json['playerResults'];
    return MatchSimulationResultDto(
      matchId: '${json['matchId']}',
      seed: _int(json['seed']),
      simulationVersion: '${json['simulationVersion'] ?? ''}',
      homeScore: _int(json['homeScore']),
      awayScore: _int(json['awayScore']),
      homeClubId: '${json['homeClubId']}',
      awayClubId: '${json['awayClubId']}',
      homeClubName: json['homeClubName']?.toString(),
      awayClubName: json['awayClubName']?.toString(),
      events: [
        for (final e in (json['events'] as List? ?? const []))
          if (e is Map)
            MatchEventDto.fromJson(Map<String, dynamic>.from(e)),
      ],
      statistics: MatchStatisticsDto.fromJson(
        Map<String, dynamic>.from(json['statistics'] as Map? ?? const {}),
      ),
      playerMatchStats: [
        for (final p in (statsList as List? ?? const []))
          if (p is Map)
            PlayerMatchStatsDto.fromJson(Map<String, dynamic>.from(p)),
      ],
      mvpPlayerId: json['mvpPlayerId']?.toString(),
    );
  }

  String? playerName(String? id) {
    if (id == null) return null;
    for (final p in playerMatchStats) {
      if (p.playerId == id) return p.name ?? id;
    }
    return id;
  }
}

class MatchEventDto {
  const MatchEventDto({
    required this.matchMinute,
    required this.matchSecond,
    required this.type,
    required this.teamId,
    required this.side,
    this.primaryPlayerId,
    this.secondaryPlayerId,
    this.goalkeeperId,
    this.fouledPlayerId,
    this.substitutedOutPlayerId,
    this.substitutedInPlayerId,
    this.success,
    this.value,
    this.commentaryKey,
    this.metadata,
    this.startPosition,
    this.endPosition,
    required this.currentHomeScore,
    required this.currentAwayScore,
  });

  final int matchMinute;
  final int matchSecond;
  final String type;
  final String teamId;
  final String side;
  final String? primaryPlayerId;
  final String? secondaryPlayerId;
  final String? goalkeeperId;
  final String? fouledPlayerId;
  final String? substitutedOutPlayerId;
  final String? substitutedInPlayerId;
  final bool? success;
  final num? value;
  final String? commentaryKey;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? startPosition;
  final Map<String, dynamic>? endPosition;
  final int currentHomeScore;
  final int currentAwayScore;

  factory MatchEventDto.fromJson(Map<String, dynamic> json) {
    return MatchEventDto(
      matchMinute: _int(json['matchMinute']),
      matchSecond: _int(json['matchSecond']),
      type: '${json['type']}',
      teamId: '${json['teamId']}',
      side: '${json['side']}',
      primaryPlayerId: json['primaryPlayerId']?.toString(),
      secondaryPlayerId: json['secondaryPlayerId']?.toString(),
      goalkeeperId: json['goalkeeperId']?.toString(),
      fouledPlayerId: json['fouledPlayerId']?.toString(),
      substitutedOutPlayerId: json['substitutedOutPlayerId']?.toString(),
      substitutedInPlayerId: json['substitutedInPlayerId']?.toString(),
      success: json['success'] as bool?,
      value: json['value'] as num?,
      commentaryKey: json['commentaryKey']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      startPosition: json['startPosition'] is Map
          ? Map<String, dynamic>.from(json['startPosition'] as Map)
          : null,
      endPosition: json['endPosition'] is Map
          ? Map<String, dynamic>.from(json['endPosition'] as Map)
          : null,
      currentHomeScore: _int(json['currentHomeScore']),
      currentAwayScore: _int(json['currentAwayScore']),
    );
  }
}

class MatchStatisticsDto {
  const MatchStatisticsDto({
    required this.homePossession,
    required this.awayPossession,
    required this.homeShots,
    required this.awayShots,
    required this.homeShotsOnTarget,
    required this.awayShotsOnTarget,
    required this.homeGoals,
    required this.awayGoals,
    required this.homeAssists,
    required this.awayAssists,
    required this.homeCorners,
    required this.awayCorners,
    required this.homeFreeKicks,
    required this.awayFreeKicks,
    required this.homeOffsides,
    required this.awayOffsides,
    required this.homeFouls,
    required this.awayFouls,
    required this.homeYellowCards,
    required this.awayYellowCards,
    required this.homeRedCards,
    required this.awayRedCards,
    required this.homeSaves,
    required this.awaySaves,
    required this.homePassesAttempted,
    required this.awayPassesAttempted,
    required this.homePassesCompleted,
    required this.awayPassesCompleted,
    required this.homePassCompletionRate,
    required this.awayPassCompletionRate,
    required this.homeExpectedGoals,
    required this.awayExpectedGoals,
  });

  final int homePossession;
  final int awayPossession;
  final int homeShots;
  final int awayShots;
  final int homeShotsOnTarget;
  final int awayShotsOnTarget;
  final int homeGoals;
  final int awayGoals;
  final int homeAssists;
  final int awayAssists;
  final int homeCorners;
  final int awayCorners;
  final int homeFreeKicks;
  final int awayFreeKicks;
  final int homeOffsides;
  final int awayOffsides;
  final int homeFouls;
  final int awayFouls;
  final int homeYellowCards;
  final int awayYellowCards;
  final int homeRedCards;
  final int awayRedCards;
  final int homeSaves;
  final int awaySaves;
  final int homePassesAttempted;
  final int awayPassesAttempted;
  final int homePassesCompleted;
  final int awayPassesCompleted;
  final double homePassCompletionRate;
  final double awayPassCompletionRate;
  final double homeExpectedGoals;
  final double awayExpectedGoals;

  factory MatchStatisticsDto.fromJson(Map<String, dynamic> json) {
    return MatchStatisticsDto(
      homePossession: _int(json['homePossession']),
      awayPossession: _int(json['awayPossession']),
      homeShots: _int(json['homeShots']),
      awayShots: _int(json['awayShots']),
      homeShotsOnTarget: _int(json['homeShotsOnTarget']),
      awayShotsOnTarget: _int(json['awayShotsOnTarget']),
      homeGoals: _int(json['homeGoals']),
      awayGoals: _int(json['awayGoals']),
      homeAssists: _int(json['homeAssists']),
      awayAssists: _int(json['awayAssists']),
      homeCorners: _int(json['homeCorners']),
      awayCorners: _int(json['awayCorners']),
      homeFreeKicks: _int(json['homeFreeKicks']),
      awayFreeKicks: _int(json['awayFreeKicks']),
      homeOffsides: _int(json['homeOffsides']),
      awayOffsides: _int(json['awayOffsides']),
      homeFouls: _int(json['homeFouls']),
      awayFouls: _int(json['awayFouls']),
      homeYellowCards: _int(json['homeYellowCards']),
      awayYellowCards: _int(json['awayYellowCards']),
      homeRedCards: _int(json['homeRedCards']),
      awayRedCards: _int(json['awayRedCards']),
      homeSaves: _int(json['homeSaves']),
      awaySaves: _int(json['awaySaves']),
      homePassesAttempted: _int(json['homePassesAttempted']),
      awayPassesAttempted: _int(json['awayPassesAttempted']),
      homePassesCompleted: _int(json['homePassesCompleted']),
      awayPassesCompleted: _int(json['awayPassesCompleted']),
      homePassCompletionRate: _double(json['homePassCompletionRate']),
      awayPassCompletionRate: _double(json['awayPassCompletionRate']),
      homeExpectedGoals: _double(json['homeExpectedGoals']),
      awayExpectedGoals: _double(json['awayExpectedGoals']),
    );
  }
}

class PlayerMatchStatsDto {
  const PlayerMatchStatsDto({
    required this.playerId,
    this.userPlayerId,
    required this.teamId,
    required this.side,
    this.name,
    required this.started,
    required this.minutesPlayed,
    required this.position,
    required this.positionFit,
    required this.rating,
    required this.goals,
    required this.assists,
    required this.shots,
    required this.shotsOnTarget,
    required this.shotsOffTarget,
    required this.passesAttempted,
    required this.passesCompleted,
    required this.cornersTaken,
    required this.freeKicksTaken,
    required this.saves,
    required this.goalsConceded,
    required this.foulsCommitted,
    required this.foulsSuffered,
    required this.yellowCards,
    required this.redCards,
    required this.staminaUsed,
    required this.staminaRemaining,
    required this.sentOff,
    required this.keyPasses,
    required this.offsides,
    required this.penaltiesTaken,
    required this.penaltiesScored,
    required this.penaltiesMissed,
    required this.tacklesWon,
    required this.interceptions,
    required this.clearances,
    required this.dribblesCompleted,
  });

  final String playerId;
  final String? userPlayerId;
  final String teamId;
  final String side;
  final String? name;
  final bool started;
  final int minutesPlayed;
  final String position;
  final int positionFit;
  final double rating;
  final int goals;
  final int assists;
  final int shots;
  final int shotsOnTarget;
  final int shotsOffTarget;
  final int passesAttempted;
  final int passesCompleted;
  final int cornersTaken;
  final int freeKicksTaken;
  final int saves;
  final int goalsConceded;
  final int foulsCommitted;
  final int foulsSuffered;
  final int yellowCards;
  final int redCards;
  final double staminaUsed;
  final double staminaRemaining;
  final bool sentOff;
  final int keyPasses;
  final int offsides;
  final int penaltiesTaken;
  final int penaltiesScored;
  final int penaltiesMissed;
  final int tacklesWon;
  final int interceptions;
  final int clearances;
  final int dribblesCompleted;

  bool get isGk => position.toUpperCase() == 'GK';

  factory PlayerMatchStatsDto.fromJson(Map<String, dynamic> json) {
    return PlayerMatchStatsDto(
      playerId: '${json['playerId']}',
      userPlayerId: json['userPlayerId']?.toString(),
      teamId: '${json['teamId']}',
      side: '${json['side']}',
      name: json['name']?.toString(),
      started: json['started'] == true,
      minutesPlayed: _int(json['minutesPlayed']),
      position: '${json['position'] ?? ''}',
      positionFit: _int(json['positionFit']),
      rating: _double(json['rating']),
      goals: _int(json['goals']),
      assists: _int(json['assists']),
      shots: _int(json['shots']),
      shotsOnTarget: _int(json['shotsOnTarget']),
      shotsOffTarget: _int(json['shotsOffTarget']),
      passesAttempted: _int(json['passesAttempted']),
      passesCompleted: _int(json['passesCompleted']),
      cornersTaken: _int(json['cornersTaken']),
      freeKicksTaken: _int(json['freeKicksTaken']),
      saves: _int(json['saves']),
      goalsConceded: _int(json['goalsConceded']),
      foulsCommitted: _int(json['foulsCommitted']),
      foulsSuffered: _int(json['foulsSuffered']),
      yellowCards: _int(json['yellowCards']),
      redCards: _int(json['redCards']),
      staminaUsed: _double(json['staminaUsed']),
      staminaRemaining: _double(json['staminaRemaining']),
      sentOff: json['sentOff'] == true,
      keyPasses: _int(json['keyPasses']),
      offsides: _int(json['offsides']),
      penaltiesTaken: _int(json['penaltiesTaken']),
      penaltiesScored: _int(json['penaltiesScored']),
      penaltiesMissed: _int(json['penaltiesMissed']),
      tacklesWon: _int(json['tacklesWon']),
      interceptions: _int(json['interceptions']),
      clearances: _int(json['clearances']),
      dribblesCompleted: _int(json['dribblesCompleted']),
    );
  }
}

int _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _double(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
