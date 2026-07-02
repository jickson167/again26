import 'dart:ui';

import 'formation_slot_layout.dart';

/// 정사각형 미니맵용 포메이션 좌표 (GK + 필드 10명 = 11점)
class FormationPitchLayout {
  FormationPitchLayout._();

  static const _gkY = 0.905;
  static const _topY = 0.13;

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

  /// GK(맨 아래) + 수비→공격 순으로 11개 좌표
  static List<Offset> allDotOffsets(String formationName, Size size) {
    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return [Offset(size.width / 2, size.height * _gkY)];
    }

    final dots = <Offset>[Offset(size.width / 2, size.height * _gkY)];
    final outfieldTop = size.height * _topY;
    final outfieldBottom = size.height * (_gkY - 0.11);

    for (var row = 0; row < lines.length; row++) {
      final players = lines[row];
      if (players <= 0) {
        continue;
      }
      final y = outfieldBottom -
          (row + 0.5) / lines.length * (outfieldBottom - outfieldTop);
      dots.addAll(_rowDots(players, y, size));
    }
    return dots;
  }

  /// 키포지션 slot → 해당 줄에 맞춘 좌표 (별표용)
  static Offset keySlotOffset(int slot, String formationName, Size size) {
    if (slot == 13) {
      return Offset(size.width / 2, size.height * _gkY);
    }

    final lines = parseLines(formationName);
    if (lines.isEmpty) {
      return FormationSlotLayout.slotOffset(slot, size: size);
    }

    final rowIndex = _rowIndexForSlot(slot, lines.length);
    final players = lines[rowIndex];
    final outfieldTop = size.height * _topY;
    final outfieldBottom = size.height * (_gkY - 0.11);
    final y = outfieldBottom -
        (rowIndex + 0.5) / lines.length * (outfieldBottom - outfieldTop);

    final slotX = FormationSlotLayout.normalizedOffset(slot).dx;
    final rowDots = _rowDots(players, y, size);
    var best = rowDots.first;
    var bestDist = double.infinity;
    final targetX = size.width * (0.06 + slotX * 0.88);
    for (final dot in rowDots) {
      final dist = (dot.dx - targetX).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = dot;
      }
    }
    return best;
  }

  static int _rowIndexForSlot(int slot, int lineCount) {
    final slotY = FormationSlotLayout.normalizedOffset(slot).dy;
    const defY = 0.68;
    const fwdY = 0.08;
    final t = ((slotY - fwdY) / (defY - fwdY)).clamp(0.0, 1.0);
    final fromAttack = (t * (lineCount - 1)).round();
    return (lineCount - 1 - fromAttack).clamp(0, lineCount - 1);
  }

  static List<Offset> _rowDots(int players, double y, Size size) {
    final widthRatio = switch (players) {
      1 => 0.0,
      2 => 0.36,
      3 => 0.56,
      4 => 0.80,
      5 => 0.92,
      _ => 0.88,
    };
    final rowWidth = size.width * widthRatio;
    final left = (size.width - rowWidth) / 2;
    if (players == 1) {
      return [Offset(size.width / 2, y)];
    }
    return [
      for (var col = 0; col < players; col++)
        Offset(
          left + rowWidth * (col + 1) / (players + 1),
          y,
        ),
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
