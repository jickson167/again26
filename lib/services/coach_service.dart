import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coach.dart';

class CoachService {
  CoachService(this._client);

  final SupabaseClient _client;

  static const table = 'coaches';

  Future<List<Coach>> fetchAll() async {
    final rows = await _client.from(table).select().order('id', ascending: true);
    return (rows as List)
        .map((row) => Coach.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Coach?> fetchById(String id) async {
    final row = await _client.from(table).select().eq('id', id).maybeSingle();
    if (row == null) {
      return null;
    }
    return Coach.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<Coach>> fetchGoodFitForFormation(String formationId) async {
    final rows = await _client
        .from(table)
        .select()
        .contains('fit_good', [formationId])
        .order('id', ascending: true);
    return (rows as List)
        .map((row) => Coach.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Coach> create(Coach coach) async {
    final row = await _client
        .from(table)
        .insert(coach.toJson())
        .select()
        .single();
    return Coach.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Coach> update(Coach coach) async {
    final row = await _client
        .from(table)
        .update(coach.toJson(includeId: false))
        .eq('id', coach.id)
        .select()
        .single();
    return Coach.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> upsertMany(List<Coach> coaches) async {
    if (coaches.isEmpty) {
      return;
    }
    await _client.from(table).upsert(coaches.map((coach) => coach.toJson()).toList());
  }
}
