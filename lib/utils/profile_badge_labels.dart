import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/player_position.dart';

/// 상단 포지션 배지 — 기본 4포지션(FW/MF/DF/GK)만 표시.
/// 상세 포지션(LW/ST 등)은 카드 본문 텍스트에서 따로 표시한다.
String playerPositionBadgeLabel(Player player) {
  switch (player.position) {
    case PlayerPosition.fw:
      return 'FW';
    case PlayerPosition.mf:
      return 'MF';
    case PlayerPosition.df:
      return 'DF';
    case PlayerPosition.gk:
      return 'GK';
  }
}

Color positionBadgeColor(String label) {
  switch (label.toUpperCase()) {
    case 'FW':
      return const Color(0xFFC62828);
    case 'MF':
      return const Color(0xFF2E7D32);
    case 'DF':
      return const Color(0xFF1565C0);
    case 'GK':
      return const Color(0xFF212121);
    default:
      return const Color(0xFF475569);
  }
}

String coachPositionBadgeLabel(String coachType) {
  final trimmed = coachType.trim();
  if (trimmed.isEmpty) {
    return 'HC';
  }
  if (trimmed.length <= 3) {
    return trimmed.toUpperCase();
  }
  return trimmed.substring(0, 1).toUpperCase();
}
