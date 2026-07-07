import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coach_master.dart';

class CoachMasterService {
  CoachMasterService(this._client);

  final SupabaseClient _client;

  Future<List<CoachAbility>> fetchAbilities() async {
    final rows = await _client.from('coach_abilities').select().order('id');
    return (rows as List)
        .map((row) => CoachAbility.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<CoachStyle>> fetchStyles() async {
    final rows = await _client.from('coach_styles').select().order('id');
    return (rows as List)
        .map((row) => CoachStyle.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
