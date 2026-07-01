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

    final rows = await query.order('rank', ascending: true).order('name');
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
