import 'dart:ui';

/// 포지션 적정도(1~7) 표시용. 팀편성 시너지 패널 · 선수상세 그리드 공통.
class PositionFitDisplay {
  PositionFitDisplay._();

  static const baseOrange = Color(0xFFEA580C);

  /// 0 → 1, 7 초과 → 7.
  static int normalize(int value) {
    if (value <= 0) return 1;
    if (value > 7) return 7;
    return value;
  }

  /// 1: 0%, 2: 10%, 3: 20%, 4: 40%, 5: 60%, 6~7: 80%.
  static double opacity(int rawValue) {
    switch (normalize(rawValue)) {
      case 1:
        return 0.0;
      case 2:
        return 0.10;
      case 3:
        return 0.20;
      case 4:
        return 0.40;
      case 5:
        return 0.60;
      case 6:
      case 7:
        return 0.80;
      default:
        return 0.0;
    }
  }

  /// 표시용 주황(투명도 적용). 알파 0이면 null(미표시).
  static Color? fillColor(int rawValue) {
    final a = opacity(rawValue);
    if (a <= 0) return null;
    return baseOrange.withValues(alpha: a);
  }
}
