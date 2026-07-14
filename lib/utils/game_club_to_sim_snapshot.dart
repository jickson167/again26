import '../models/club_player.dart';
import '../models/game_club.dart';
import '../utils/field_zone_layout.dart';

/// Converts [GameClub] into MatchSimulationInput JSON for Edge dry-run.
/// Display/transport only — does not simulate the match.
class GameClubToSimSnapshot {
  GameClubToSimSnapshot._();

  static const simulationVersion = '4';

  static Map<String, dynamic> buildInput({
    required GameClub home,
    required GameClub away,
    required int seed,
    required bool homeAdvantage,
    String? matchId,
  }) {
    return {
      'matchId': matchId ?? 'admin_dry_${seed}_${DateTime.now().millisecondsSinceEpoch}',
      'seed': seed,
      'simulationVersion': simulationVersion,
      'homeAdvantage': homeAdvantage,
      'home': _team(home),
      'away': _team(away),
    };
  }

  static Map<String, dynamic> _team(GameClub club) {
    final starters = club.starterClubPlayers;
    final bench = club.benchClubPlayers;
    final slots = FormationFieldSlots.slotsFor(club.formation.name);
    final assignments = <Map<String, dynamic>>[];
    for (var i = 0; i < starters.length && i < 11; i++) {
      final fitSlot = i < slots.length ? slots[i] : 5;
      assignments.add({
        'pitchSlot': i + 1,
        'fitSlot': fitSlot,
        'lane': _laneForFit(fitSlot),
        'line': _lineForFit(fitSlot),
      });
    }
    return {
      'clubId': club.id ?? club.clubName,
      'clubName': club.clubName,
      'formationName': club.formation.name,
      'formationType': club.formation.formationType,
      'tactic': {
        'possession': club.formation.possession,
        'attack': club.formation.attack,
        'stability': club.formation.stability,
        'lineHeight': 5,
        'coachStyle': club.coach.coachType,
      },
      'starters': [
        for (var i = 0; i < starters.length; i++)
          _player(
            starters[i],
            fitSlot: i < slots.length ? slots[i] : 5,
          ),
      ],
      'bench': [
        for (final cp in bench) _player(cp, fitSlot: 5),
      ],
      'assignments': assignments,
      'keyPositions': [
        for (final e in club.formation.keyPositionEntries)
          {'id': e.id, 'slot': e.slot},
      ],
      'pkPlayerId': club.pkPlayerId,
      'fkPlayerId': club.fkPlayerId,
      'ckPlayerId': club.ckPlayerId,
      'captainPlayerId': club.captainPlayerId,
    };
  }

  static Map<String, dynamic> _player(ClubPlayer cp, {required int fitSlot}) {
    final p = cp.player;
    final fit = _clampFit(p.positionFit[fitSlot] ?? 5);
    return {
      'playerId': p.id,
      'userPlayerId': cp.id,
      'name': p.name,
      'speed': p.speed,
      'power': p.power,
      'technique': p.technique,
      'shooting': p.shooting,
      'passing': p.passing,
      'stamina': p.stamina,
      'pkAbility': p.pkAbility,
      'fkAbility': p.fkAbility,
      'ckAbility': p.ckAbility,
      'leadership': p.leadership,
      'assignedFit': fit,
      'staminaFraction': 1.0,
      'styleIds': p.styleIds,
      'positionFits': {
        for (final e in p.positionFit.entries) '${e.key}': _clampFit(e.value),
      },
    };
  }

  static int _clampFit(int v) {
    if (v < 1) return 1;
    if (v > 7) return 7;
    return v;
  }

  static String _laneForFit(int fitSlot) {
    switch (fitSlot) {
      case 1:
      case 4:
      case 7:
      case 10:
        return 'left';
      case 3:
      case 6:
      case 9:
      case 12:
        return 'right';
      default:
        return 'center';
    }
  }

  static String _lineForFit(int fitSlot) {
    if (fitSlot == 13) return 'gk';
    if (fitSlot <= 3) return 'attack';
    if (fitSlot <= 6 || fitSlot == 8) return 'midfield';
    return 'defense';
  }
}
