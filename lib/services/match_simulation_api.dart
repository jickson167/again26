import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_simulation_dto.dart';

/// Invokes simulate-match Edge Function only — no local match calculation.
class MatchSimulationApi {
  MatchSimulationApi(this._client);

  final SupabaseClient _client;

  static const functionName = 'simulate-match';

  Future<MatchSimApiResponse> runDryRun({
    required Map<String, dynamic> input,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: {
        'dryRun': true,
        'input': input,
      },
    );
    final data = response.data;
    if (data is! Map) {
      return MatchSimApiResponse(
        ok: false,
        dryRun: true,
        persisted: false,
        dbAccumulation: false,
        error: 'Unexpected response: $data',
      );
    }
    return MatchSimApiResponse.fromJson(Map<String, dynamic>.from(data));
  }
}
