import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
    final data = _serializeClub(club, clubId: clubId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clubDataKey, jsonEncode(data));
    return club.copyWith(id: clubId, userId: devUserId);
  }

  Map<String, dynamic> _serializeClub(GameClub club, {required String clubId}) {
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
      'starter_player_ids': club.starters.map((player) => player.id).toList(),
      'bench_player_ids': club.bench.map((player) => player.id).toList(),
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
    final starterIds = [
      for (final id in (data['starter_player_ids'] as List? ?? const [])) '$id',
    ];
    final benchIds = [
      for (final id in (data['bench_player_ids'] as List? ?? const [])) '$id',
    ];

    final results = await Future.wait([
      formationService.fetchById(formationId),
      coachService.fetchById(coachId),
      playerService.fetchByIds([...starterIds, ...benchIds]),
    ]);

    final formation = results[0] as Formation?;
    final coach = results[1] as Coach?;
    final players = results[2] as List<Player>;
    if (formation == null || coach == null) {
      return null;
    }

    final playersById = {for (final player in players) player.id: player};
    final starters = [
      for (final id in starterIds)
        if (playersById[id] != null) playersById[id]!,
    ];
    final bench = [
      for (final id in benchIds)
        if (playersById[id] != null) playersById[id]!,
    ];

    return GameClub(
      id: '${data['id']}',
      userId: devUserId,
      clubName: '${data['club_name']}',
      formation: formation,
      coach: coach,
      starters: starters,
      bench: bench,
      leagueTier: _leagueTierFromCode('${data['league_tier']}'),
      clubLogoUrl: data['club_logo_url'] as String?,
      clubStats: Map<String, dynamic>.from(
        data['club_stats'] as Map? ?? const {},
      ),
      playerResults: _parseNestedMap(data['player_results']),
      coachResults: _parseNestedMap(data['coach_results']),
    );
  }

  GameLeagueTier _leagueTierFromCode(String code) {
    return switch (code) {
      'first' => GameLeagueTier.first,
      'pro' => GameLeagueTier.pro,
      _ => GameLeagueTier.second,
    };
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
