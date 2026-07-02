import 'dart:ui';

import 'formation_slot_layout.dart';

/// 정사각형 미니맵용 포메이션 좌표 (GK + 필드 10명 = 11점)
class FormationPitchLayout {
  FormationPitchLayout._();

  /// 골대 박스 중심 Y
  static const boxCenterYRatio = 0.875;

  /// GK 점 — 박스 하단 근처
  static const gkDotYRatio = 0.935;

  /// 공격선 — 상단 센터서클 근처
  static const attackYRatio = 0.13;

  /// 수비선 — GK 위·박스 상단 근처
  static const defYRatio = 0.785;

  /// 인접 선수 간 고정 좌우 간격 (미니맵 가로 대비, 모든 줄 동일)
  static const dotGapRatio = 0.25;

  /// 5명 줄 등에서 필드 밖으로 넘치지 않게 줄 전체 폭 상한
  static const maxRowSpanRatio = 0.88;

  static List<int> parseLines(String formationName) {
    final match = RegExp(r'\d+(?:-\d+)+').firstMatch(formationName.trim());
    if (match == null) {
      return [4, 4, 2];
    }
    return match.group(0)!.split('-').map(int.parse).toList();
  }

  static int totalDots(String formationName) {
    return parseLines(formationName).fold<int>(1, (sum, n) => sum + n);
  }

  static double rowYRatio(int rowIndex, int lineCount) {
    if (lineCount <= 1) {
      return (defYRatio + attackYRatio) / 2;
    }
    return defYRatio -
        (rowIndex / (lineCount - 1)) * (defYRatio - attackYRatio);
  }

  static List<Offset> allDotOffsets(String formationName, Size size) {
    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return [Offset(size.width / 2, size.height * gkDotYRatio)];
    }

    final dots = <Offset>[
      Offset(size.width / 2, size.height * gkDotYRatio),
    ];

    for (var row = 0; row < lines.length; row++) {
      final players = lines[row];
      if (players <= 0) {
        continue;
      }
      final y = size.height * rowYRatio(row, lines.length);
      dots.addAll(_rowDots(players, y, size));
    }
    return dots;
  }

  static Offset keySlotOffset(int slot, String formationName, Size size) {
    if (slot == 13) {
      return Offset(size.width / 2, size.height * gkDotYRatio);
    }

    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return _rowDots(1, size.height * gkDotYRatio, size).first;
    }

    final rowIndex = _rowIndexForSlot(slot, lines.length);
    final players = lines[rowIndex];
    final y = size.height * rowYRatio(rowIndex, lines.length);
    final rowDots = _rowDots(players, y, size);
    final col = _columnForSlot(slot, players);
    return rowDots[col.clamp(0, rowDots.length - 1)];
  }

  static int _rowIndexForSlot(int slot, int lineCount) {
    final slotY = FormationSlotLayout.normalizedOffset(slot).dy;
    const refDefY = 0.68;
    const refFwdY = 0.08;
    final t = ((slotY - refFwdY) / (refDefY - refFwdY)).clamp(0.0, 1.0);
    final fromAttack = (t * (lineCount - 1)).round();
    return (lineCount - 1 - fromAttack).clamp(0, lineCount - 1);
  }

  /// 슬롯 좌/우 성향 → 해당 줄 내 열 인덱스
  static int _columnForSlot(int slot, int players) {
    if (players <= 1) {
      return 0;
    }
    final slotX = FormationSlotLayout.normalizedOffset(slot).dx;
    return (slotX * (players - 1)).round().clamp(0, players - 1);
  }

  static double _dotGap(Size size) => size.width * dotGapRatio;

  static double _rowGap(int players, Size size) {
    if (players <= 1) {
      return 0;
    }
    final preferred = _dotGap(size);
    final maxSpan = size.width * maxRowSpanRatio;
    final preferredSpan = preferred * (players - 1);
    if (preferredSpan <= maxSpan) {
      return preferred;
    }
    return maxSpan / (players - 1);
  }

  /// 가운데 정렬 + 고정 간격 (양끝 stretch 없음)
  static List<Offset> _rowDots(int players, double y, Size size) {
    if (players == 1) {
      return [Offset(size.width / 2, y)];
    }

    final gap = _rowGap(players, size);
    final centerX = size.width / 2;
    final halfSpan = gap * (players - 1) / 2;

    return [
      for (var col = 0; col < players; col++)
        Offset(centerX - halfSpan + gap * col, y),
    ];
  }
}

/// @deprecated FormationPitchLayout 사용
class FormationShape {
  FormationShape._();

  static List<int> parseLineCounts(String formationName) {
    return FormationPitchLayout.parseLines(formationName);
  }

  static int outfieldCount(String formationName) {
    return parseLineCounts(formationName).fold<int>(0, (sum, n) => sum + n);
  }
}
