import 'package:supabase_flutter/supabase_flutter.dart';

import 'formation_service.dart';
import 'key_position_service.dart';
import 'player_service.dart';

class AppServices {
  AppServices(SupabaseClient client)
      : playerService = PlayerService(client),
        keyPositionService = KeyPositionService(client),
        formationService = FormationService(client);

  final PlayerService playerService;
  final KeyPositionService keyPositionService;
  final FormationService formationService;
}
