import 'dart:ui';

import '../models/field_position_layout.dart';
import 'formation_shape.dart';
import 'position_fit_display.dart';

/// 피치 위 13구역 사각형 + 포메이션→선발 11슬롯 매핑.
/// 주황 시너지 패널과 선수 배치가 같은 칸 기하를 쓴다.
class FieldZoneLayout {
  FieldZoneLayout._();

  /// 필드(라인) 영역 안쪽 패딩
  static const zonePadding = 5.0;

  /// 시너지 패널 사이 간격
  static const panelGap = 2.0;

  /// 슬롯 1~13 → 피치 내 Rect (공격=위, GK=아래). 패널 사이 [panelGap]px.
  static Map<int, Rect> zoneRects(
    Size size, {
    double padding = zonePadding,
    double gap = panelGap,
  }) {
    final inner = Rect.fromLTWH(
      padding,
      padding,
      (size.width - padding * 2).clamp(1.0, size.width),
      (size.height - padding * 2).clamp(1.0, size.height),
    );
    final rows = FieldPositionLayout.gridRows;
    final rowCount = rows.length;
    const colCount = 3;
    final cellW = ((inner.width - gap * (colCount - 1)) / colCount).clamp(1.0, inner.width);
    final cellH = ((inner.height - gap * (rowCount - 1)) / rowCount).clamp(1.0, inner.height);
    final result = <int, Rect>{};
    for (var r = 0; r < rowCount; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final slot = row[c];
        if (slot == null) continue;
        result[slot] = Rect.fromLTWH(
          inner.left + c * (cellW + gap),
          inner.top + r * (cellH + gap),
          cellW,
          cellH,
        );
      }
    }
    return result;
  }

  /// position_fit 1~7 → 주황 투명도 (1=0%·미표시, 2=10% … 6~7=80%).
  static Color? synergyColor(int value) => PositionFitDisplay.fillColor(value);
}

/// 포메이션별 선발 11명 필드 슬롯 (순서: GK → 수비 → … → 공격, 줄 안 좌→우).
/// 어긋나면 [_overrides] 값만 수정하면 된다.
class FormationFieldSlots {
  FormationFieldSlots._();

  /// 길이 11. index 0 = GK(13).
  static List<int> slotsFor(String formationName) {
    final lines = FormationPitchLayout.parseLines(formationName);
    final key = lines.join('-');
    final override = _overrides[key];
    if (override != null && override.length == 11) {
      return List<int>.from(override);
    }
    return _defaultFromLines(lines);
  }

  /// 선수 좌표 = 구역 칸 중심. 동일 슬롯 중복 시 칸 안에서 좌우 분산.
  static List<Offset> playerCenters(
    String formationName,
    Size size, {
    double padding = FieldZoneLayout.zonePadding,
  }) {
    final slots = slotsFor(formationName);
    final rects = FieldZoneLayout.zoneRects(size, padding: padding);
    final totalForSlot = <int, int>{};
    for (final s in slots) {
      totalForSlot[s] = (totalForSlot[s] ?? 0) + 1;
    }
    final seen = <int, int>{};
    return [
      for (final slot in slots)
        () {
          final rect = rects[slot] ??
              Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2),
                width: 10,
                height: 10,
              );
          final total = totalForSlot[slot] ?? 1;
          final index = seen[slot] = (seen[slot] ?? 0) + 1;
          final t = total == 1 ? 0.5 : (index - 0.5) / total;
          return Offset(rect.left + rect.width * t, rect.center.dy);
        }(),
    ];
  }

  /// 수동 튜닝 테이블. 키 = 라인 숫자 "4-4-2".
  static const Map<String, List<int>> _overrides = {
    // GK + LB/LCB/RCB/RB + LM/DM/CAM/RM + LW/RW(투톱)
    '4-4-2': [13, 10, 11, 12, 9, 4, 8, 5, 6, 1, 3],
    '4-3-3': [13, 10, 11, 12, 9, 4, 8, 6, 1, 2, 3],
    // GK + DEF4 + CDM×2 + LAM/CAM/RAM + ST
    '4-2-3-1': [13, 10, 11, 12, 9, 8, 7, 4, 5, 6, 2],
    '3-5-2': [13, 10, 11, 12, 7, 4, 8, 6, 9, 1, 3],
    // GK + LCB/CB/RCB + LM/DM/AM/RM + LW/ST/RW
    // 중원 외곽=LM/RM(4·6), 안쪽=DM/AM — 전력·적정포지션 슬롯과 시각 배치 맞춤
    '3-4-3': [13, 10, 11, 12, 4, 8, 5, 6, 1, 2, 3],
    '3-4-1-2': [13, 10, 11, 12, 7, 4, 6, 9, 5, 1, 3],
    '4-1-4-1': [13, 10, 11, 12, 9, 8, 4, 5, 6, 3, 2],
    '4-5-1': [13, 10, 11, 12, 9, 7, 4, 8, 6, 5, 2],
    '4-3-1-2': [13, 10, 11, 12, 9, 4, 8, 6, 5, 1, 3],
    '5-3-2': [13, 7, 10, 11, 12, 9, 4, 8, 6, 1, 3],
    '5-4-1': [13, 7, 10, 11, 12, 9, 4, 8, 5, 6, 2],
    '4-2-2-2': [13, 10, 11, 12, 9, 8, 5, 4, 6, 1, 3],
    '4-2-4': [13, 10, 11, 12, 9, 8, 5, 1, 4, 3, 6],
    '3-2-4-1': [13, 10, 11, 12, 8, 5, 4, 1, 6, 3, 2],
    '4-1-2-1-2': [13, 10, 11, 12, 9, 8, 4, 6, 5, 1, 3],
  };

  static List<int> _defaultFromLines(List<int> lines) {
    const bands = [
      [10, 11, 12, 7, 9], // 수비
      [4, 8, 5, 6, 7, 9], // 중원
      [1, 2, 3, 4, 6], // 공격
    ];
    final result = <int>[13];
    if (lines.isEmpty) {
      return [13, 10, 11, 12, 9, 4, 8, 5, 6, 1, 3];
    }
    for (var i = 0; i < lines.length; i++) {
      final bandIndex = lines.length == 1
          ? 1
          : ((i / (lines.length - 1)) * 2).round().clamp(0, 2);
      final pool = bands[bandIndex];
      for (var k = 0; k < lines[i]; k++) {
        result.add(pool[k % pool.length]);
      }
    }
    while (result.length < 11) {
      result.add(2);
    }
    return result.take(11).toList();
  }
}
