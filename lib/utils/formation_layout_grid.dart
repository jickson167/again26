import 'dart:ui';

import '../models/field_position_layout.dart';
import 'field_zone_layout.dart';
import 'formation_shape.dart';

/// 필드 선수 1명의 레이아웃 점 (GK 제외).
class OutfieldLayoutPoint {
  const OutfieldLayoutPoint({
    required this.slot,
    required this.cell,
  });

  /// 포지션 패널 1~12 (GK 13 제외)
  final int slot;

  /// 패널 내부 3×2 격자: 0 1 2 / 3 4 5
  final int cell;

  bool get isValid =>
      slot >= 1 && slot <= 12 && cell >= 0 && cell <= 5;

  Map<String, dynamic> toJson() => {'slot': slot, 'cell': cell};

  factory OutfieldLayoutPoint.fromJson(Map<String, dynamic> json) {
    final slot = int.tryParse('${json['slot']}') ?? 2;
    final cell = int.tryParse('${json['cell']}') ?? 0;
    return OutfieldLayoutPoint(
      slot: slot.clamp(1, 12),
      cell: cell.clamp(0, 5),
    );
  }

  OutfieldLayoutPoint copyWith({int? slot, int? cell}) {
    return OutfieldLayoutPoint(
      slot: slot ?? this.slot,
      cell: cell ?? this.cell,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OutfieldLayoutPoint && other.slot == slot && other.cell == cell;

  @override
  int get hashCode => Object.hash(slot, cell);
}

/// 포지션 패널 6등분 스냅·좌표 변환.
class FormationLayoutGrid {
  FormationLayoutGrid._();

  static const cols = 3;
  static const rows = 2;
  static const cellCount = cols * rows; // 6

  static int cellCol(int cell) => cell % cols;
  static int cellRow(int cell) => cell ~/ cols;

  static int cellIndex(int col, int row) =>
      (row.clamp(0, rows - 1) * cols) + col.clamp(0, cols - 1);

  /// 패널 Rect 안 cell 중심.
  static Offset cellCenter(Rect panel, int cell) {
    final c = cell.clamp(0, cellCount - 1);
    final w = panel.width / cols;
    final h = panel.height / rows;
    final col = cellCol(c);
    final row = cellRow(c);
    return Offset(
      panel.left + w * (col + 0.5),
      panel.top + h * (row + 0.5),
    );
  }

  /// 패널 안 local 좌표 → cell.
  static int cellAtLocal(Offset local, Size panelSize) {
    if (panelSize.width <= 0 || panelSize.height <= 0) return 0;
    final col = (local.dx / panelSize.width * cols).floor().clamp(0, cols - 1);
    final row = (local.dy / panelSize.height * rows).floor().clamp(0, rows - 1);
    return cellIndex(col, row);
  }

  /// 전역 좌표 → 최근접 (slot 1~12, cell). GK(13) 패널은 후보에서 제외.
  static OutfieldLayoutPoint snapToCell(
    Offset point,
    Map<int, Rect> panels,
  ) {
    OutfieldLayoutPoint? best;
    var bestDist = double.infinity;
    for (final entry in panels.entries) {
      final slot = entry.key;
      if (slot < 1 || slot > 12) continue;
      final panel = entry.value;
      final local = Offset(point.dx - panel.left, point.dy - panel.top);
      final cell = cellAtLocal(local, panel.size);
      final center = cellCenter(panel, cell);
      final d = (center - point).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = OutfieldLayoutPoint(slot: slot, cell: cell);
      }
    }
    return best ?? const OutfieldLayoutPoint(slot: 2, cell: 1);
  }

  /// layout 10점 → 피치 Offset 10개 (슬롯 패널 기준).
  static List<Offset> offsetsFor(
    List<OutfieldLayoutPoint> layout,
    Size size, {
    double padding = FieldZoneLayout.zonePadding,
  }) {
    final panels = FieldZoneLayout.zoneRects(size, padding: padding);
    return [
      for (final p in layout)
        cellCenter(
          panels[p.slot] ??
              Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2),
                width: 40,
                height: 40,
              ),
          p.cell,
        ),
    ];
  }

  /// GK + 필드10. layout이 있으면 필드만 격자 좌표, 없으면 슬롯 기본 격자.
  /// 알고리즘 미세 보정은 쓰지 않는다.
  static List<Offset> allDotOffsets({
    required String formationName,
    required Size size,
    List<OutfieldLayoutPoint>? layoutOutfield,
    double padding = FieldZoneLayout.zonePadding,
  }) {
    final layout = (layoutOutfield != null && layoutOutfield.length == 10)
        ? layoutOutfield
        : defaultFromFormationName(formationName);
    final out = offsetsFor(layout, size, padding: padding);
    final gk = FormationPitchLayout.allDotOffsets(formationName, size).first;
    return [gk, ...out];
  }

  /// 슬롯 매핑 기준 기본 레이아웃 (패널당 cell=1). 알고리즘 보정 없음.
  static List<OutfieldLayoutPoint> defaultFromFormationName(
    String formationName,
  ) {
    return fromFieldSlots(FormationFieldSlots.slotsFor(formationName));
  }

  /// @deprecated [defaultFromFormationName] 사용.
  static List<OutfieldLayoutPoint> backfillFromFormationName(
    String formationName, {
    Size size = const Size(300, 480),
  }) {
    return defaultFromFormationName(formationName);
  }

  /// 슬롯 배열(길이 11, [0]=GK)에서 필드 10명의 기본 cell(상단 중앙=1).
  static List<OutfieldLayoutPoint> fromFieldSlots(List<int> slots11) {
    final out = <OutfieldLayoutPoint>[];
    for (var i = 1; i < slots11.length && out.length < 10; i++) {
      final slot = slots11[i];
      out.add(
        OutfieldLayoutPoint(
          slot: slot == 13 ? 11 : slot.clamp(1, 12),
          cell: 1,
        ),
      );
    }
    while (out.length < 10) {
      out.add(const OutfieldLayoutPoint(slot: 2, cell: 1));
    }
    return out;
  }

  static List<OutfieldLayoutPoint>? parseLayout(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;
    final points = <OutfieldLayoutPoint>[];
    for (final item in raw) {
      if (item is Map) {
        points.add(
          OutfieldLayoutPoint.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    if (points.length != 10) return null;
    if (points.any((p) => !p.isValid)) return null;
    return points;
  }

  static List<Map<String, dynamic>> layoutToJson(
    List<OutfieldLayoutPoint> layout,
  ) =>
      [for (final p in layout) p.toJson()];

  /// 에디터용 패널 라벨 (1~13).
  static String labelFor(int slot) =>
      FieldPositionLayout.labels[slot] ?? 'S$slot';
}
