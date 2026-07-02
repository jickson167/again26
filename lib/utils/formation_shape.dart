import 'dart:ui';

/// 포메이션 이름(예: 4-2-3-1) 파싱 — 숫자는 골키퍼 제외 필드 10명
class FormationShape {
  FormationShape._();

  static String? normalizeName(String formationName) {
    final match = RegExp(r'\d+(?:-\d+)+').firstMatch(formationName.trim());
    return match?.group(0);
  }

  static List<int> parseLineCounts(String formationName) {
    final normalized = normalizeName(formationName);
    if (normalized == null) {
      return [4, 4, 2];
    }
    return normalized.split('-').map(int.parse).toList();
  }

  static int outfieldCount(String formationName) {
    return parseLineCounts(formationName).fold<int>(0, (sum, count) => sum + count);
  }

  /// 수비선(첫 숫자)부터 공격선(마지막)까지 각 줄의 좌표 (GK 제외)
  static List<Offset> lineDotOffsets(String formationName, Size size) {
    final lines = parseLineCounts(formationName);
    if (lines.isEmpty) {
      return [];
    }

    const sidePad = 10.0;
    const topPad = 12.0;
    const bottomPad = 12.0;
    final usableWidth = size.width - sidePad * 2;
    final usableHeight = size.height - topPad - bottomPad;
    final rowCount = lines.length;

    final positions = <Offset>[];
    for (var row = 0; row < rowCount; row++) {
      final players = lines[row];
      if (players <= 0) {
        continue;
      }
      // row 0 = 수비(아래), 마지막 row = 공격(위)
      final y = topPad + usableHeight * (1.0 - (row + 0.5) / rowCount);
      for (var col = 0; col < players; col++) {
        final x = sidePad + usableWidth * (col + 1) / (players + 1);
        positions.add(Offset(x, y));
      }
    }
    return positions;
  }
}

// Offset is from dart:ui - need import in formation_shape or use a record
