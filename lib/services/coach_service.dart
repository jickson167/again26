import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coach.dart';

class CoachService {
  CoachService(this._client);

  final SupabaseClient _client;

  static const table = 'coaches';

  bool _isMissingPortraitUrlColumn(Object error) {
    if (error is! PostgrestException) {
      return false;
    }
    final message = '${error.message} ${error.details ?? ''}';
    return error.code == 'PGRST204' && message.contains('portrait_url');
  }

  Map<String, dynamic> _withoutPortraitUrl(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy.remove('portrait_url');
    return copy;
  }

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
    final payload = coach.toJson();
    try {
      final row = await _client.from(table).insert(payload).select().single();
      return Coach.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      if (!_isMissingPortraitUrlColumn(error)) {
        rethrow;
      }
      final fallbackRow = await _client
          .from(table)
          .insert(_withoutPortraitUrl(payload))
          .select()
          .single();
      return Coach.fromJson(Map<String, dynamic>.from(fallbackRow));
    }
  }

  Future<Coach> update(Coach coach) async {
    final payload = coach.toJson(includeId: false);
    try {
      final row = await _client
          .from(table)
          .update(payload)
          .eq('id', coach.id)
          .select()
          .single();
      return Coach.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      if (!_isMissingPortraitUrlColumn(error)) {
        rethrow;
      }
      final fallbackRow = await _client
          .from(table)
          .update(_withoutPortraitUrl(payload))
          .eq('id', coach.id)
          .select()
          .single();
      return Coach.fromJson(Map<String, dynamic>.from(fallbackRow));
    }
  }

  /// 폼에 없는 필드를 지우지 않고 일부 컬럼만 갱신한다.
  Future<Coach> patch(String id, Map<String, dynamic> fields) async {
    if (fields.isEmpty) {
      final existing = await fetchById(id);
      if (existing == null) {
        throw StateError('감독을 찾을 수 없습니다: $id');
      }
      return existing;
    }
    try {
      final row = await _client
          .from(table)
          .update(fields)
          .eq('id', id)
          .select()
          .single();
      return Coach.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      if (!_isMissingPortraitUrlColumn(error)) {
        rethrow;
      }
      final fallbackRow = await _client
          .from(table)
          .update(_withoutPortraitUrl(fields))
          .eq('id', id)
          .select()
          .single();
      return Coach.fromJson(Map<String, dynamic>.from(fallbackRow));
    }
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> upsertMany(List<Coach> coaches) async {
    if (coaches.isEmpty) {
      return;
    }
    final payload = coaches.map((coach) => coach.toJson()).toList();
    try {
      await _client.from(table).upsert(payload);
    } on PostgrestException catch (error) {
      if (!_isMissingPortraitUrlColumn(error)) {
        rethrow;
      }
      await _client
          .from(table)
          .upsert(payload.map(_withoutPortraitUrl).toList());
    }
  }

  Future<List<Coach>> fetchNextWithoutPortraitUrls({int limit = 5}) async {
    try {
      final rows = await _client
          .from(table)
          .select()
          .or('portrait_url.is.null,portrait_url.eq.')
          .order('id', ascending: true)
          .limit(limit);
      return (rows as List)
          .map((row) => Coach.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (error) {
      if (!_isMissingPortraitUrlColumn(error)) {
        rethrow;
      }
      final all = await fetchAll();
      return all
          .where((coach) => (coach.portraitUrl ?? '').trim().isEmpty)
          .take(limit)
          .toList();
    }
  }
}
