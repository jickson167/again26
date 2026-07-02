import 'dart:ui';

/// 포메이션 13칸 슬롯 좌표 (공격=위, GK=아래)
class FormationSlotLayout {
  FormationSlotLayout._();

  static const slotLabels = {
    1: 'LF/LW',
    2: 'CF/ST',
    3: 'RF/RW',
    4: 'LM/LW',
    5: 'AM/CM',
    6: 'RM/RW',
    7: 'LWB/LM',
    8: 'DM/CM',
    9: 'RWB/RM',
    10: 'LB/LCB',
    11: 'CB',
    12: 'RB/RCB',
    13: 'GK',
  };

  /// x, y in 0~1 relative coordinates
  static Offset slotOffset(int slot, {required Size size, double padding = 8}) {
    final normalized = _normalizedOffsets[slot.clamp(1, 13)] ?? const Offset(0.5, 0.5);
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;
    return Offset(
      padding + usableWidth * normalized.dx,
      padding + usableHeight * normalized.dy,
    );
  }

  static const _normalizedOffsets = {
    1: Offset(0.18, 0.10),
    2: Offset(0.50, 0.06),
    3: Offset(0.82, 0.10),
    4: Offset(0.18, 0.28),
    5: Offset(0.50, 0.28),
    6: Offset(0.82, 0.28),
    7: Offset(0.14, 0.48),
    8: Offset(0.50, 0.48),
    9: Offset(0.86, 0.48),
    10: Offset(0.18, 0.68),
    11: Offset(0.50, 0.68),
    12: Offset(0.82, 0.68),
    13: Offset(0.50, 0.88),
  };
}
