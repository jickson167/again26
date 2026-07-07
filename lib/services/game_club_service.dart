import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coach.dart';
import '../models/formation.dart';
import '../models/game_club.dart';
import '../models/player.dart';
import 'coach_service.dart';
import 'formation_service.dart';
import 'player_service.dart';

class GameClubService {
  GameClubService(this._client);

  final SupabaseClient _client;

  static const clubsTable = 'game_clubs';
  static const rostersTable = 'game_rosters';

  Future<GameClub> createUserClub({
    required GameClub club,
    required String userId,
  }) async {
    final clubRow = await _client
        .from(clubsTable)
        .insert({
          'user_id': userId,
          'club_name': club.clubName,
          'club_logo_url': club.clubLogoUrl,
          'league_tier': club.leagueTierCode,
          'club_stats': club.clubStats,
          'player_results': club.playerResults,
          'coach_results': club.coachResults,
        })
        .select('id')
        .single();

    final clubId = '${clubRow['id']}';
    await _client.from(rostersTable).insert({
      'club_id': clubId,
      'formation_id': club.formation.id,
      'coach_id': club.coach.id,
      'starter_player_ids': club.starters.map((player) => player.id).toList(),
      'bench_player_ids': club.bench.map((player) => player.id).toList(),
      'roster_data': {
        'formation_name': club.formation.name,
        'coach_name': club.coach.name,
        'starter_names': club.starters.map((player) => player.name).toList(),
        'bench_names': club.bench.map((player) => player.name).toList(),
      },
    });

    return club.copyWith(id: clubId, userId: userId);
  }

  Future<void> deleteUserClubData({required String userId}) async {
    final clubRows = await _client
        .from(clubsTable)
        .select('id')
        .eq('user_id', userId);
    for (final row in clubRows as List) {
      final clubId = '${row['id']}';
      await _client.from(rostersTable).delete().eq('club_id', clubId);
      await _client.from(clubsTable).delete().eq('id', clubId);
    }
  }

  Future<GameClub?> fetchUserClub({
    required String userId,
    required PlayerService playerService,
    required CoachService coachService,
    required FormationService formationService,
  }) async {
    final clubRow = await _client
        .from(clubsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (clubRow == null) {
      return null;
    }

    return _clubFromRows(
      clubRow: clubRow,
      userId: userId,
      playerService: playerService,
      coachService: coachService,
      formationService: formationService,
    );
  }

  @Deprecated('Google 로그인(user_id)으로 대체됨')
  Future<GameClub> createGuestClub({
    required GameClub club,
    required String guestId,
  }) async {
    final clubRow = await _client
        .from(clubsTable)
        .insert({
          'guest_id': guestId,
          'club_name': club.clubName,
          'club_logo_url': club.clubLogoUrl,
          'league_tier': club.leagueTierCode,
          'club_stats': club.clubStats,
          'player_results': club.playerResults,
          'coach_results': club.coachResults,
        })
        .select('id')
        .single();

    final clubId = '${clubRow['id']}';
    await _client.from(rostersTable).insert({
      'club_id': clubId,
      'formation_id': club.formation.id,
      'coach_id': club.coach.id,
      'starter_player_ids': club.starters.map((player) => player.id).toList(),
      'bench_player_ids': club.bench.map((player) => player.id).toList(),
      'roster_data': {
        'formation_name': club.formation.name,
        'coach_name': club.coach.name,
        'starter_names': club.starters.map((player) => player.name).toList(),
        'bench_names': club.bench.map((player) => player.name).toList(),
      },
    });

    return club.copyWith(id: clubId, guestId: guestId);
  }

  @Deprecated('Google 로그인(user_id)으로 대체됨')
  Future<GameClub?> fetchGuestClub({
    required String guestId,
    required PlayerService playerService,
    required CoachService coachService,
    required FormationService formationService,
  }) async {
    final clubRow = await _client
        .from(clubsTable)
        .select()
        .eq('guest_id', guestId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (clubRow == null) {
      return null;
    }

    return _clubFromRows(
      clubRow: clubRow,
      guestId: guestId,
      playerService: playerService,
      coachService: coachService,
      formationService: formationService,
    );
  }

  Future<GameClub?> _clubFromRows({
    required Map<String, dynamic> clubRow,
    String? userId,
    String? guestId,
    required PlayerService playerService,
    required CoachService coachService,
    required FormationService formationService,
  }) async {
    final clubId = '${clubRow['id']}';
    final rosterRow = await _client
        .from(rostersTable)
        .select()
        .eq('club_id', clubId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (rosterRow == null) {
      return null;
    }

    final formationId = '${rosterRow['formation_id']}';
    final coachId = '${rosterRow['coach_id']}';
    final starterIds = [
      for (final id in (rosterRow['starter_player_ids'] as List? ?? const []))
        '$id',
    ];
    final benchIds = [
      for (final id in (rosterRow['bench_player_ids'] as List? ?? const []))
        '$id',
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
      id: clubId,
      userId: userId ?? clubRow['user_id'] as String?,
      guestId: guestId ?? clubRow['guest_id'] as String?,
      clubName: '${clubRow['club_name']}',
      formation: formation,
      coach: coach,
      starters: starters,
      bench: bench,
      leagueTier: _leagueTierFromCode('${clubRow['league_tier']}'),
      clubLogoUrl: clubRow['club_logo_url'] as String?,
      clubStats: Map<String, dynamic>.from(
        clubRow['club_stats'] as Map? ?? const {},
      ),
      playerResults: _parseNestedMap(clubRow['player_results']),
      coachResults: _parseNestedMap(clubRow['coach_results']),
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
