import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_style.dart';

class PlayerStyleService {
  PlayerStyleService(this._client);

  final SupabaseClient _client;

  static const table = 'player_styles';

  Future<List<PlayerStyle>> fetchAll() async {
    final rows = await _client
        .from(table)
        .select()
        .order('category', ascending: true)
        .order('sort_order', ascending: true)
        .order('id', ascending: true);
    return (rows as List)
        .map((row) => PlayerStyle.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, PlayerStyle>> fetchByIdMap() async {
    final items = await fetchAll();
    return {for (final item in items) item.id: item};
  }

  Future<void> updateLabel({
    required String id,
    required String labelKo,
  }) async {
    await _client.from(table).update({'label_ko': labelKo}).eq('id', id);
  }

  Future<void> create({
    required String id,
    required PlayerStyleCategory category,
    required String labelKo,
    int sortOrder = 0,
  }) async {
    await _client.from(table).insert({
      'id': id,
      'category': category.code,
      'label_ko': labelKo,
      'sort_order': sortOrder,
    });
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
