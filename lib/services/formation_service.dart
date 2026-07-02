import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/formation.dart';
import '../utils/formation_display.dart';

class FormationService {
  FormationService(this._client);

  final SupabaseClient _client;

  static const table = 'formations';

  Future<List<Formation>> fetchAll() async {
    final rows = await _client.from(table).select().order('id', ascending: true);
    return (rows as List)
        .map((row) => Formation.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Formation?> fetchById(String id) async {
    final row = await _client.from(table).select().eq('id', id).maybeSingle();
    if (row == null) {
      return null;
    }
    return Formation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Formation> update(Formation item) async {
    final row = await _client
        .from(table)
        .update(item.toJson(includeId: false))
        .eq('id', item.id)
        .select()
        .single();
    return Formation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> upsertMany(List<Formation> items) async {
    if (items.isEmpty) {
      return;
    }
    await _client.from(table).upsert(items.map((e) => e.toJson()).toList());
  }

  /// 옛 CSV 버그로 id/필드 전체가 한 줄로 저장된 row 제거
  Future<int> deleteCorruptRecords() async {
    final items = await fetchAll();
    var removed = 0;
    for (final item in items) {
      if (!FormationDisplay.isCorruptRecord(item)) {
        continue;
      }
      await delete(item.id);
      removed++;
    }
    return removed;
  }
}
