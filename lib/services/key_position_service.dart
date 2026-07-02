import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/key_position.dart';

class KeyPositionService {
  KeyPositionService(this._client);

  final SupabaseClient _client;

  static const table = 'key_positions';

  Future<List<KeyPosition>> fetchAll() async {
    final rows = await _client.from(table).select().order('id', ascending: true);
    return (rows as List)
        .map((row) => KeyPosition.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<KeyPosition?> fetchById(String id) async {
    final row = await _client.from(table).select().eq('id', id).maybeSingle();
    if (row == null) {
      return null;
    }
    return KeyPosition.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Map<String, KeyPosition>> fetchByIds(Iterable<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) {
      return {};
    }

    final rows = await _client.from(table).select().inFilter('id', unique);
    final map = <String, KeyPosition>{};
    for (final row in rows as List) {
      final kp = KeyPosition.fromJson(Map<String, dynamic>.from(row));
      map[kp.id] = kp;
    }
    return map;
  }

  Future<KeyPosition> update(KeyPosition item) async {
    final row = await _client
        .from(table)
        .update(item.toJson(includeId: false))
        .eq('id', item.id)
        .select()
        .single();
    return KeyPosition.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> upsertMany(List<KeyPosition> items) async {
    if (items.isEmpty) {
      return;
    }
    await _client.from(table).upsert(items.map((e) => e.toJson()).toList());
  }
}
