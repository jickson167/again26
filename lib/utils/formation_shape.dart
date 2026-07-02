import 'dart:ui';

import 'formation_slot_layout.dart';

/// 정사각형 미니맵용 포메이션 좌표 (GK + 필드 10명 = 11점)
class FormationPitchLayout {
  FormationPitchLayout._();

  /// 골키퍼 — 골대 안쪽 (맨 아래 X)
  static const gkYRatio = 0.87;

  /// 공격선 — 상단 센터서클 근처
  static const attackYRatio = 0.07;

  /// 수비선 — GK 위
  static const defYRatio = 0.70;

  /// 좌우 여백 — 좁음(0.075)과 넓음(0.04)의 중간
  static const sideMargin = 0.058;

  /// 모든 선수 점을 위로 올리는 px
  static const dotLiftPx = 5.0;

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

  /// GK(맨 아래) + 수비→공격 순으로 11개 좌표
  static List<Offset> allDotOffsets(String formationName, Size size) {
    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return [_lift(Offset(size.width / 2, size.height * gkYRatio))];
    }

    final dots = <Offset>[_lift(Offset(size.width / 2, size.height * gkYRatio))];

    for (var row = 0; row < lines.length; row++) {
      final players = lines[row];
      if (players <= 0) {
        continue;
      }
      final y = size.height * rowYRatio(row, lines.length);
      dots.addAll(_rowDots(players, y, size).map(_lift));
    }
    return dots;
  }

  static Offset _lift(Offset point) => Offset(point.dx, point.dy - dotLiftPx);

  /// 키포지션 slot → 해당 줄에 맞춘 좌표 (별표용)
  static Offset keySlotOffset(int slot, String formationName, Size size) {
    if (slot == 13) {
      return _lift(Offset(size.width / 2, size.height * gkYRatio));
    }

    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return FormationSlotLayout.slotOffset(slot, size: size);
    }

    final rowIndex = _rowIndexForSlot(slot, lines.length);
    final players = lines[rowIndex];
    final y = size.height * rowYRatio(rowIndex, lines.length);

    final slotX = FormationSlotLayout.normalizedOffset(slot).dx;
    final rowDots = _rowDots(players, y, size);
    var best = rowDots.first;
    var bestDist = double.infinity;
    final targetX = size.width * (sideMargin + slotX * (1 - sideMargin * 2));
    for (final dot in rowDots) {
      final dist = (dot.dx - targetX).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = dot;
      }
    }
    return _lift(best);
  }

  static int _rowIndexForSlot(int slot, int lineCount) {
    final slotY = FormationSlotLayout.normalizedOffset(slot).dy;
    const refDefY = 0.68;
    const refFwdY = 0.08;
    final t = ((slotY - refFwdY) / (refDefY - refFwdY)).clamp(0.0, 1.0);
    final fromAttack = (t * (lineCount - 1)).round();
    return (lineCount - 1 - fromAttack).clamp(0, lineCount - 1);
  }

  static List<Offset> _rowDots(int players, double y, Size size) {
    if (players == 1) {
      return [Offset(size.width / 2, y)];
    }

    final left = size.width * sideMargin;
    final right = size.width * (1 - sideMargin);
    final span = right - left;

    return [
      for (var col = 0; col < players; col++)
        Offset(left + span * col / (players - 1), y),
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
