import 'player.dart';

/// 구단 보유 선수 (유저 전용). position_index 1~11 선발, 12~21 후보.
class ClubPlayer {
  const ClubPlayer({
    this.id,
    required this.player,
    required this.positionIndex,
    required this.acquiredAt,
    this.currentStage = 1,
  });

  final String? id;
  final Player player;
  final int positionIndex;
  final DateTime acquiredAt;
  final int currentStage;

  String get playerId => player.id;

  bool get isStarter => positionIndex >= 1 && positionIndex <= 11;

  bool get isBench => positionIndex >= 12 && positionIndex <= 21;

  ClubPlayer copyWith({
    String? id,
    Player? player,
    int? positionIndex,
    DateTime? acquiredAt,
    int? currentStage,
  }) {
    return ClubPlayer(
      id: id ?? this.id,
      player: player ?? this.player,
      positionIndex: positionIndex ?? this.positionIndex,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      currentStage: currentStage ?? this.currentStage,
    );
  }

  Map<String, dynamic> toInsertRow({required String clubId}) {
    return {
      'club_id': clubId,
      'player_id': player.id,
      'position_index': positionIndex,
      'acquired_at': acquiredAt.toUtc().toIso8601String(),
      'current_stage': currentStage,
    };
  }

  static List<ClubPlayer> fromStartersAndBench({
    required List<Player> starters,
    required List<Player> bench,
    DateTime? acquiredAt,
  }) {
    final at = acquiredAt ?? DateTime.now();
    return [
      for (var i = 0; i < starters.length && i < 11; i++)
        ClubPlayer(
          player: starters[i],
          positionIndex: i + 1,
          acquiredAt: at,
        ),
      for (var i = 0; i < bench.length && i < 10; i++)
        ClubPlayer(
          player: bench[i],
          positionIndex: 12 + i,
          acquiredAt: at,
        ),
    ];
  }
}
