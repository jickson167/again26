import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/club_emblem.dart';

class ClubEmblemService {
  ClubEmblemService(this._client);

  final SupabaseClient _client;

  static const table = 'club_emblems';

  Future<List<ClubEmblem>> fetchAll() async {
    final rows = await _client
        .from(table)
        .select()
        .order('id', ascending: true);
    return (rows as List)
        .map((row) => ClubEmblem.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> updateMeta({
    required String id,
    required int grade,
    required String seedType,
  }) async {
    await _client
        .from(table)
        .update({'grade': grade, 'seed_type': seedType})
        .eq('id', id);
  }

  Future<void> updateImage({
    required String id,
    required String imageData,
  }) async {
    await _client.from(table).update({'image_data': imageData}).eq('id', id);
  }

  Future<void> create({
    required String id,
    required int grade,
    required String seedType,
  }) async {
    await _client.from(table).insert({
      'id': id,
      'grade': grade,
      'seed_type': seedType,
    });
  }

  Future<String> createNext({
    required int grade,
    required String seedType,
  }) async {
    final rows = await _client
        .from(table)
        .select('id')
        .order('id', ascending: true);
    final used = <int>{
      for (final row in rows as List)
        int.tryParse((row as Map<String, dynamic>)['id']?.toString() ?? '') ??
            -1,
    };

    for (var i = 1; i <= 999; i++) {
      if (used.contains(i)) {
        continue;
      }
      final id = i.toString().padLeft(3, '0');
      try {
        await create(id: id, grade: grade, seedType: seedType);
        return id;
      } catch (error) {
        final text = error.toString();
        // Concurrent adds can race; on duplicate key, try the next ID.
        if (text.contains('23505') || text.contains('duplicate key value')) {
          used.add(i);
          continue;
        }
        rethrow;
      }
    }

    throw StateError('사용 가능한 앰블럼 ID가 없습니다.');
  }

  Future<void> delete(String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
