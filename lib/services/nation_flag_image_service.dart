import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/nation_flag_image.dart';

class NationFlagImageService {
  NationFlagImageService(this._client);

  final SupabaseClient _client;

  static const table = 'nation_flag_images';

  Future<List<NationFlagImage>> fetchAll() async {
    final rows = await _client
        .from(table)
        .select()
        .order('nationality', ascending: true);
    return (rows as List)
        .map((row) => NationFlagImage.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, String>> fetchImageMap() async {
    final list = await fetchAll();
    return {
      for (final item in list)
        if (item.nationality.isNotEmpty && item.imageData.isNotEmpty)
          item.nationality: item.imageData,
    };
  }

  Future<void> upsert({
    required String nationality,
    required String imageData,
  }) async {
    await _client.from(table).upsert({
      'nationality': nationality,
      'image_data': imageData,
    });
  }
}
