import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'club_emblem_service.dart';
import 'coach_master_service.dart';
import 'coach_service.dart';
import 'formation_service.dart';
import 'game_club_service.dart';
import 'key_position_service.dart';
import 'nation_flag_image_service.dart';
import 'player_service.dart';

class AppServices {
  AppServices(SupabaseClient client)
    : playerService = PlayerService(client),
      keyPositionService = KeyPositionService(client),
      formationService = FormationService(client),
      coachService = CoachService(client),
      coachMasterService = CoachMasterService(client),
      gameClubService = GameClubService(client),
      nationFlagImageService = NationFlagImageService(client),
      clubEmblemService = ClubEmblemService(client),
      authService = AuthService(client);

  final PlayerService playerService;
  final KeyPositionService keyPositionService;
  final FormationService formationService;
  final CoachService coachService;
  final CoachMasterService coachMasterService;
  final GameClubService gameClubService;
  final NationFlagImageService nationFlagImageService;
  final ClubEmblemService clubEmblemService;
  final AuthService authService;
}
