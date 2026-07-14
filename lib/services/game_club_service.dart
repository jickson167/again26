import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/club_player.dart';
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
  static const clubPlayersTable = 'club_players';

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
    final squad = club.squad.isNotEmpty
        ? club.squad
        : ClubPlayer.fromStartersAndBench(
            starters: club.starters,
            bench: club.bench,
          );

    await _client.from(rostersTable).insert({
      'club_id': clubId,
      'formation_id': club.formation.id,
      'coach_id': club.coach.id,
      'starter_player_ids': [
        for (final cp in _sortedStarters(squad)) cp.playerId,
      ],
      'bench_player_ids': [
        for (final cp in _sortedBench(squad)) cp.playerId,
      ],
      'pk_player_id': club.pkPlayerId,
      'fk_player_id': club.fkPlayerId,
      'ck_player_id': club.ckPlayerId,
      'captain_player_id': club.captainPlayerId,
      'roster_data': {
        'formation_name': club.formation.name,
        'coach_name': club.coach.name,
        'starter_names': [
          for (final cp in _sortedStarters(squad)) cp.player.name,
        ],
        'bench_names': [
          for (final cp in _sortedBench(squad)) cp.player.name,
        ],
      },
    });

    if (squad.isNotEmpty) {
      await _client.from(clubPlayersTable).insert([
        for (final cp in squad) cp.toInsertRow(clubId: clubId),
      ]);
    }

    return club.copyWith(id: clubId, userId: userId, squad: squad);
  }

  Future<GameClub> updateTeamOrganization({
    required GameClub club,
  }) async {
    final clubId = club.id;
    if (clubId == null || clubId.isEmpty) {
      throw StateError('club.id is required to update team organization');
    }

    final starters = _sortedStarters(club.squad);
    final bench = _sortedBench(club.squad);

    await _client.from(rostersTable).update({
      'formation_id': club.formation.id,
      'coach_id': club.coach.id,
      'starter_player_ids': [for (final cp in starters) cp.playerId],
      'bench_player_ids': [for (final cp in bench) cp.playerId],
      'pk_player_id': club.pkPlayerId,
      'fk_player_id': club.fkPlayerId,
      'ck_player_id': club.ckPlayerId,
      'captain_player_id': club.captainPlayerId,
      'roster_data': {
        'formation_name': club.formation.name,
        'coach_name': club.coach.name,
        'starter_names': [for (final cp in starters) cp.player.name],
        'bench_names': [for (final cp in bench) cp.player.name],
      },
    }).eq('club_id', clubId);

    // position_index UNIQUE + CHECK(1~21) 충돌 없이 재배치:
    // 임시 +100 업데이트는 check 제약을 깨므로 delete → insert.
    final squadRows = <Map<String, dynamic>>[];
    for (final cp in club.squad) {
      if (cp.positionIndex < 1 || cp.positionIndex > 21) {
        throw StateError(
          'invalid position_index ${cp.positionIndex} for ${cp.playerId}',
        );
      }
      final row = cp.toInsertRow(clubId: clubId);
      final id = cp.id;
      if (id != null && id.isNotEmpty) {
        row['id'] = id;
      }
      squadRows.add(row);
    }

    await _client.from(clubPlayersTable).delete().eq('club_id', clubId);
    if (squadRows.isNotEmpty) {
      await _client.from(clubPlayersTable).insert(squadRows);
    }

    return club;
  }

  Future<void> deleteUserClubData({required String userId}) async {
    final clubRows = await _client
        .from(clubsTable)
        .select('id')
        .eq('user_id', userId);
    for (final row in clubRows as List) {
      final clubId = '${row['id']}';
      await _client.from(clubPlayersTable).delete().eq('club_id', clubId);
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

  /// 관리자 시뮬레이션용. 최대 [limit]개 구단을 불러와 티어→등수→이름 순 정렬.
  Future<List<GameClub>> fetchClubs({
    int limit = 100,
    required PlayerService playerService,
    required CoachService coachService,
    required FormationService formationService,
  }) async {
    final rows = await _client
        .from(clubsTable)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final clubs = <GameClub>[];
    for (final row in rows as List) {
      final club = await _clubFromRows(
        clubRow: Map<String, dynamic>.from(row as Map),
        playerService: playerService,
        coachService: coachService,
        formationService: formationService,
      );
      if (club != null) {
        clubs.add(club);
      }
    }
    clubs.sort(_compareClubsForList);
    return clubs;
  }

  static int _compareClubsForList(GameClub a, GameClub b) {
    final tier = a.leagueTier.sortWeight.compareTo(b.leagueTier.sortWeight);
    if (tier != 0) return tier;
    final standing = a.leagueStanding.compareTo(b.leagueStanding);
    if (standing != 0) return standing;
    return a.clubName.compareTo(b.clubName);
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
    final squad = club.squad.isNotEmpty
        ? club.squad
        : ClubPlayer.fromStartersAndBench(
            starters: club.starters,
            bench: club.bench,
          );

    await _client.from(rostersTable).insert({
      'club_id': clubId,
      'formation_id': club.formation.id,
      'coach_id': club.coach.id,
      'starter_player_ids': [
        for (final cp in _sortedStarters(squad)) cp.playerId,
      ],
      'bench_player_ids': [
        for (final cp in _sortedBench(squad)) cp.playerId,
      ],
      'pk_player_id': club.pkPlayerId,
      'fk_player_id': club.fkPlayerId,
      'ck_player_id': club.ckPlayerId,
      'captain_player_id': club.captainPlayerId,
      'roster_data': {
        'formation_name': club.formation.name,
        'coach_name': club.coach.name,
        'starter_names': [
          for (final cp in _sortedStarters(squad)) cp.player.name,
        ],
        'bench_names': [
          for (final cp in _sortedBench(squad)) cp.player.name,
        ],
      },
    });

    if (squad.isNotEmpty) {
      await _client.from(clubPlayersTable).insert([
        for (final cp in squad) cp.toInsertRow(clubId: clubId),
      ]);
    }

    return club.copyWith(id: clubId, guestId: guestId, squad: squad);
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

    final clubPlayerRows = await _client
        .from(clubPlayersTable)
        .select()
        .eq('club_id', clubId)
        .order('position_index', ascending: true);

    final List<String> playerIds;
    final List<Map<String, dynamic>> cpRows;
    if ((clubPlayerRows as List).isNotEmpty) {
      cpRows = [
        for (final row in clubPlayerRows)
          Map<String, dynamic>.from(row as Map),
      ];
      playerIds = [for (final row in cpRows) '${row['player_id']}'];
    } else {
      // 마이그레이션 전 폴백: roster 배열
      final starterIds = [
        for (final id in (rosterRow['starter_player_ids'] as List? ?? const []))
          '$id',
      ];
      final benchIds = [
        for (final id in (rosterRow['bench_player_ids'] as List? ?? const []))
          '$id',
      ];
      playerIds = [...starterIds, ...benchIds];
      cpRows = [
        for (var i = 0; i < starterIds.length; i++)
          {
            'player_id': starterIds[i],
            'position_index': i + 1,
            'acquired_at': rosterRow['created_at'],
            'current_stage': 1,
          },
        for (var i = 0; i < benchIds.length; i++)
          {
            'player_id': benchIds[i],
            'position_index': 12 + i,
            'acquired_at': rosterRow['created_at'],
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
            id: row['id']?.toString(),
            player: playersById['${row['player_id']}']!,
            positionIndex: _parseInt(row['position_index']) ?? 1,
            acquiredAt: _parseDate(row['acquired_at']) ?? DateTime.now(),
            currentStage: _parseInt(row['current_stage']) ?? 1,
          ),
    ];

    return GameClub(
      id: clubId,
      userId: userId ?? clubRow['user_id'] as String?,
      guestId: guestId ?? clubRow['guest_id'] as String?,
      clubName: '${clubRow['club_name']}',
      formation: formation,
      coach: coach,
      squad: squad,
      pkPlayerId: rosterRow['pk_player_id'] as String?,
      fkPlayerId: rosterRow['fk_player_id'] as String?,
      ckPlayerId: rosterRow['ck_player_id'] as String?,
      captainPlayerId: rosterRow['captain_player_id'] as String?,
      leagueTier: _leagueTierFromCode('${clubRow['league_tier']}'),
      clubLogoUrl: clubRow['club_logo_url'] as String?,
      clubStats: Map<String, dynamic>.from(
        clubRow['club_stats'] as Map? ?? const {},
      ),
      playerResults: _parseNestedMap(clubRow['player_results']),
      coachResults: _parseNestedMap(clubRow['coach_results']),
    ).withEnsuredPlayerResults();
  }

  List<ClubPlayer> _sortedStarters(List<ClubPlayer> squad) {
    final list = squad.where((p) => p.isStarter).toList()
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    return list;
  }

  List<ClubPlayer> _sortedBench(List<ClubPlayer> squad) {
    final list = squad.where((p) => p.isBench).toList()
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    return list;
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse('$value');
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
