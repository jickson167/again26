import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player.dart';

class PlayerService {
  PlayerService(this._client);

  final SupabaseClient _client;

  static const table = 'players';

  Future<List<Player>> fetchAll({String? search, PlayerPositionFilter? position}) async {
    var query = _client.from(table).select();

    if (search != null && search.trim().isNotEmpty) {
      query = query.or('name.ilike.%$search%,fake_name.ilike.%$search%');
    }

    if (position != null) {
      query = query.eq('position', position.code);
    }

    final rows = await query.order('id', ascending: true);
    return (rows as List)
        .map((row) => Player.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Player?> fetchById(String id) async {
    final row = await _client.from(table).select().eq('id', id).maybeSingle();
    if (row == null) {
      return null;
    }
    return Player.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Player> create(Player player) async {
    final row = await _client
        .from(table)
        .insert(player.toJson(includeId: false))
        .select()
        .single();
    return Player.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Player> update(Player player) async {
    final row = await _client
        .from(table)
        .update(player.toJson(includeId: false))
        .eq('id', player.id)
        .select()
        .single();
    return Player.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  /// portrait_url이 비어 있는 선수 (id 오름차순, 최대 [limit]명).
  Future<List<Player>> fetchNextWithoutPortraitUrls({int limit = 5}) async {
    final rows = await _client
        .from(table)
        .select()
        .or('portrait_url.is.null,portrait_url.eq.')
        .order('id', ascending: true)
        .limit(limit);
    return (rows as List)
        .map((row) => Player.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// @deprecated [fetchNextWithoutPortraitUrls] 사용
  Future<Player?> fetchNextWithoutPortraitUrl() async {
    final list = await fetchNextWithoutPortraitUrls(limit: 1);
    return list.isEmpty ? null : list.first;
  }

  Future<List<Player>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const [];
    }

    final rows = await _client.from(table).select().inFilter('id', ids);
    final playersById = {
      for (final row in rows as List)
        '${row['id']}': Player.fromJson(Map<String, dynamic>.from(row)),
    };
    return [for (final id in ids) if (playersById[id] != null) playersById[id]!];
  }

  Future<void> upsertMany(List<Player> players) async {
    if (players.isEmpty) {
      return;
    }

    final payload = players.map((player) => player.toJson()).toList();
    await _client.from(table).upsert(payload);
  }
}

enum PlayerPositionFilter {
  fw('fw'),
  mf('mf'),
  df('df'),
  gk('gk');

  const PlayerPositionFilter(this.code);

  final String code;
}
