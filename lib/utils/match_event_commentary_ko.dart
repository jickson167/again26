import '../models/match_simulation_dto.dart';
import 'event_comment_generator/event_comment_generator.dart';

/// Converts match events to Korean commentary lines (display only).
class MatchEventCommentaryKo {
  MatchEventCommentaryKo._();

  static const timelineTypes = {
    'attack',
    'attack_build',
    'key_pass',
    'dribble',
    'cross',
    'shot',
    // Intermediate step — save/goal/woodwork carry the result narrative
    // 'shot_on_target',
    'save',
    'shot_saved',
    'post',
    'shot_woodwork',
    'goal',
    'corner',
    'free_kick',
    'penalty',
    'penalty_scored',
    'penalty_missed',
    'penalty_miss',
    'offside',
    'foul',
    'yellow_card',
    'red_card',
    'injury',
    'substitution',
    'halftime',
    'fulltime',
  };

  static List<MatchEventDto> filterForTimeline(List<MatchEventDto> events) {
    return [
      for (final e in events)
        if (timelineTypes.contains(e.type)) e,
    ]..sort((a, b) {
        final m = a.matchMinute.compareTo(b.matchMinute);
        if (m != 0) return m;
        return a.matchSecond.compareTo(b.matchSecond);
      });
  }

  static String line(
    MatchEventDto e,
    String? Function(String? id) nameOf, {
    int matchSeed = 0,
    String? homeName,
    String? awayName,
  }) {
    return EventCommentGenerator.generate(
      e,
      CommentContext(
        nameOf: nameOf,
        matchSeed: matchSeed,
        homeName: homeName,
        awayName: awayName,
      ),
    );
  }
}
