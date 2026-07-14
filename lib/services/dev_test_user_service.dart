import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/club_player.dart';
import '../models/coach.dart';
import '../models/formation.dart';
import '../models/game_club.dart';
import '../models/player.dart';
import 'coach_service.dart';
import 'formation_service.dart';
import 'player_service.dart';

/// 개발테스트 전용 로컬 유저 데이터 저장소 (Supabase OAuth·game_clubs와 분리).
class DevTestUserService {
  static const devUserId = 'dev-test-user';
  static const _loggedInKey = 'dev_test_logged_in';
  static const _clubDataKey = 'dev_test_club_data';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> signIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  /// 유저 데이터 DB를 비웁니다. 다음 로그인 시 구단 생성 화면으로 이동합니다.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clubDataKey);
    await prefs.setBool(_loggedInKey, false);
  }

  Future<GameClub?> fetchClub({
    required PlayerService playerService,
    required CoachService coachService,
    required FormationService formationService,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clubDataKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return _hydrateClub(
      data: data,
      playerService: playerService,
      coachService: coachService,
      formationService: formationService,
    );
  }

  Future<GameClub> createClub({required GameClub club}) async {
    final clubId = club.id ?? 'dev-club-1';
    final squad = club.squad.isNotEmpty
        ? club.squad
        : ClubPlayer.fromStartersAndBench(
            starters: club.starters,
            bench: club.bench,
          );
    final withSquad = club.copyWith(id: clubId, userId: devUserId, squad: squad);
    final data = _serializeClub(withSquad, clubId: clubId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clubDataKey, jsonEncode(data));
    return withSquad;
  }

  Future<GameClub> updateTeamOrganization({required GameClub club}) async {
    final clubId = club.id ?? 'dev-club-1';
    final data = _serializeClub(club, clubId: clubId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clubDataKey, jsonEncode(data));
    return club.copyWith(id: clubId, userId: devUserId);
  }

  Map<String, dynamic> _serializeClub(GameClub club, {required String clubId}) {
    final starters = club.starterClubPlayers;
    final bench = club.benchClubPlayers;
    return {
      'id': clubId,
      'club_name': club.clubName,
      'club_logo_url': club.clubLogoUrl,
      'league_tier': club.leagueTierCode,
      'club_stats': club.clubStats,
      'player_results': club.playerResults,
      'coach_results': club.coachResults,
      'formation_id': club.formation.id,
      'coach_id': club.coach.id,
      'starter_player_ids': [for (final cp in starters) cp.playerId],
      'bench_player_ids': [for (final cp in bench) cp.playerId],
      'pk_player_id': club.pkPlayerId,
      'fk_player_id': club.fkPlayerId,
      'ck_player_id': club.ckPlayerId,
      'captain_player_id': club.captainPlayerId,
      'squad': [
        for (final cp in club.squad)
          {
            'player_id': cp.playerId,
            'position_index': cp.positionIndex,
            'acquired_at': cp.acquiredAt.toUtc().toIso8601String(),
            'current_stage': cp.currentStage,
          },
      ],
    };
  }

  Future<GameClub?> _hydrateClub({
    required Map<String, dynamic> data,
    required PlayerService playerService,
    required CoachService coachService,
    required FormationService formationService,
  }) async {
    final formationId = '${data['formation_id']}';
    final coachId = '${data['coach_id']}';

    final squadRaw = data['squad'] as List?;
    final List<String> playerIds;
    final List<Map<String, dynamic>> cpRows;
    if (squadRaw != null && squadRaw.isNotEmpty) {
      cpRows = [
        for (final row in squadRaw) Map<String, dynamic>.from(row as Map),
      ];
      playerIds = [for (final row in cpRows) '${row['player_id']}'];
    } else {
      final starterIds = [
        for (final id in (data['starter_player_ids'] as List? ?? const []))
          '$id',
      ];
      final benchIds = [
        for (final id in (data['bench_player_ids'] as List? ?? const [])) '$id',
      ];
      playerIds = [...starterIds, ...benchIds];
      cpRows = [
        for (var i = 0; i < starterIds.length; i++)
          {
            'player_id': starterIds[i],
            'position_index': i + 1,
            'acquired_at': DateTime.now().toUtc().toIso8601String(),
            'current_stage': 1,
          },
        for (var i = 0; i < benchIds.length; i++)
          {
            'player_id': benchIds[i],
            'position_index': 12 + i,
            'acquired_at': DateTime.now().toUtc().toIso8601String(),
            'current_stage': 1,
          },
      ];
    }

    final results = await Future.wait([
      formationService.fetchById(formationId),
      coachService.fetchById(coachId),
      playerService.fetchByIds(playerIds),
    ]);

    final formation = results[0] as Formation?;
    final coach = results[1] as Coach?;
    final players = results[2] as List<Player>;
    if (formation == null || coach == null) {
      return null;
    }

    final playersById = {for (final player in players) player.id: player};
    final squad = <ClubPlayer>[
      for (final row in cpRows)
        if (playersById['${row['player_id']}'] != null)
          ClubPlayer(
            player: playersById['${row['player_id']}']!,
            positionIndex: _parseInt(row['position_index']) ?? 1,
            acquiredAt: DateTime.tryParse('${row['acquired_at']}') ??
                DateTime.now(),
            currentStage: _parseInt(row['current_stage']) ?? 1,
          ),
    ];

    return GameClub(
      id: '${data['id']}',
      userId: devUserId,
      clubName: '${data['club_name']}',
      formation: formation,
      coach: coach,
      squad: squad,
      pkPlayerId: data['pk_player_id'] as String?,
      fkPlayerId: data['fk_player_id'] as String?,
      ckPlayerId: data['ck_player_id'] as String?,
      captainPlayerId: data['captain_player_id'] as String?,
      leagueTier: _leagueTierFromCode('${data['league_tier']}'),
      clubLogoUrl: data['club_logo_url'] as String?,
      clubStats: Map<String, dynamic>.from(
        data['club_stats'] as Map? ?? const {},
      ),
      playerResults: _parseNestedMap(data['player_results']),
      coachResults: _parseNestedMap(data['coach_results']),
    ).withEnsuredPlayerResults();
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  GameLeagueTier _leagueTierFromCode(String code) {
    return GameLeagueTier.fromCode(code);
  }

  Map<String, Map<String, dynamic>> _parseNestedMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map(
      (key, nested) => MapEntry(
        '$key',
        Map<String, dynamic>.from(nested as Map? ?? const {}),
      ),
    );
  }
}
