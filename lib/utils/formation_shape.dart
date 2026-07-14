import 'dart:ui';

import 'formation_slot_layout.dart';

/// 포메이션 피치 좌표 (GK + 필드 10명 = 11점).
/// 균등 라인 배치만 담당한다. 팀편성·전력용 미세 위치는
/// [Formation.layoutOutfield](편집기)만 사용한다.
class FormationPitchLayout {
  FormationPitchLayout._();

  /// 골대 박스 중심 Y
  static const boxCenterYRatio = 0.875;

  /// GK 점 — 박스 하단 근처
  static const gkDotYRatio = 0.935;

  /// GK 점 추가 오프셋 (아래로 +, 픽셀)
  static const gkDotYNudgePx = 5.0;

  /// 공격선 — 상단
  static const attackYRatio = 0.12;

  /// 수비선 — GK 위
  static const defYRatio = 0.78;

  /// 인접 선수 기본 좌우 간격
  static const dotGapRatio = 0.22;

  /// 줄 전체 폭 상한
  static const maxRowSpanRatio = 0.90;

  static List<int> parseLines(String formationName) {
    final match = RegExp(r'\d+(?:-\d+)+').firstMatch(formationName.trim());
    if (match == null) {
      return [4, 4, 2];
    }
    return match.group(0)!.split('-').map(int.parse).toList();
  }

  static String linesKey(List<int> lines) => lines.join('-');

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

  /// GK + 각 라인. 공격=위(작은 y), GK=아래. (보정 없음 · 균등 라인)
  static List<Offset> allDotOffsets(String formationName, Size size) {
    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return [_gkOffset(size)];
    }

    final dots = <Offset>[_gkOffset(size)];

    for (var row = 0; row < lines.length; row++) {
      final players = lines[row];
      if (players <= 0) continue;
      final baseY = size.height * rowYRatio(row, lines.length);
      dots.addAll(
        _lineDots(
          players: players,
          baseY: baseY,
          size: size,
        ),
      );
    }
    return dots;
  }

  static Offset keySlotOffset(int slot, String formationName, Size size) {
    if (slot == 13) {
      return _gkOffset(size);
    }

    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return _gkOffset(size);
    }

    final rowIndex = _rowIndexForSlot(slot, lines.length);
    final players = lines[rowIndex];
    final baseY = size.height * rowYRatio(rowIndex, lines.length);
    final rowDots = _lineDots(
      players: players,
      baseY: baseY,
      size: size,
    );
    final col = _columnForSlot(slot, players);
    return rowDots[col.clamp(0, rowDots.length - 1)];
  }

  static Offset _gkOffset(Size size) {
    return Offset(
      size.width / 2,
      size.height * gkDotYRatio + gkDotYNudgePx,
    );
  }

  static int _rowIndexForSlot(int slot, int lineCount) {
    final slotY = FormationSlotLayout.normalizedOffset(slot).dy;
    const refDefY = 0.68;
    const refFwdY = 0.08;
    final t = ((slotY - refFwdY) / (refDefY - refFwdY)).clamp(0.0, 1.0);
    final fromAttack = (t * (lineCount - 1)).round();
    return (lineCount - 1 - fromAttack).clamp(0, lineCount - 1);
  }

  static int _columnForSlot(int slot, int players) {
    if (players <= 1) return 0;
    final slotX = FormationSlotLayout.normalizedOffset(slot).dx;
    return (slotX * (players - 1)).round().clamp(0, players - 1);
  }

  static List<Offset> _lineDots({
    required int players,
    required double baseY,
    required Size size,
  }) {
    final xs = _rowXs(players, size);
    return [
      for (var col = 0; col < players; col++)
        Offset(
          xs[col],
          baseY.clamp(size.height * 0.05, size.height * 0.92),
        ),
    ];
  }

  static List<double> _rowXs(int players, Size size) {
    if (players <= 1) {
      return [size.width / 2];
    }
    final preferred = size.width * dotGapRatio;
    final maxSpan = size.width * maxRowSpanRatio;
    final preferredSpan = preferred * (players - 1);
    final gap = preferredSpan <= maxSpan ? preferred : maxSpan / (players - 1);
    final centerX = size.width / 2;
    final halfSpan = gap * (players - 1) / 2;
    return [
      for (var col = 0; col < players; col++)
        centerX - halfSpan + gap * col,
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
