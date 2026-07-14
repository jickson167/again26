import 'dart:ui';

import 'package:again26/utils/field_zone_layout.dart';
import 'package:again26/utils/formation_layout_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cell 인덱스와 중심이 3×2 격자에서 맞다', () {
    const panel = Rect.fromLTWH(0, 0, 90, 60);
    expect(FormationLayoutGrid.cellCol(5), 2);
    expect(FormationLayoutGrid.cellRow(5), 1);
    expect(FormationLayoutGrid.cellCenter(panel, 0), const Offset(15, 15));
    expect(FormationLayoutGrid.cellCenter(panel, 2), const Offset(75, 15));
    expect(FormationLayoutGrid.cellCenter(panel, 3), const Offset(15, 45));
    expect(FormationLayoutGrid.cellCenter(panel, 5), const Offset(75, 45));
  });

  test('snapToCell은 최근접 필드 패널·셀을 고른다', () {
    const size = Size(300, 480);
    final panels = FieldZoneLayout.zoneRects(size);
    final st = panels[2]!;
    final snapped = FormationLayoutGrid.snapToCell(st.center, panels);
    expect(snapped.slot, 2);
    expect(snapped.cell, inInclusiveRange(0, 5));
  });

  test('snap은 GK(13)를 고르지 않는다', () {
    const size = Size(300, 480);
    final panels = FieldZoneLayout.zoneRects(size);
    final gk = panels[13]!;
    final snapped = FormationLayoutGrid.snapToCell(gk.center, panels);
    expect(snapped.slot, isNot(13));
    expect(snapped.slot, inInclusiveRange(1, 12));
  });

  test('backfill은 길이 10·유효 slot/cell', () {
    final layout = FormationLayoutGrid.defaultFromFormationName('3-4-3');
    expect(layout.length, 10);
    for (final p in layout) {
      expect(p.isValid, isTrue);
    }
  });

  test('allDotOffsets는 layout이 있으면 필드만 교체하고 GK는 유지', () {
    const size = Size(300, 480);
    final layout = List.generate(
      10,
      (i) => OutfieldLayoutPoint(slot: (i % 12) + 1, cell: i % 6),
    );
    final withLayout = FormationLayoutGrid.allDotOffsets(
      formationName: '4-4-2',
      size: size,
      layoutOutfield: layout,
    );
    final fallback = FormationLayoutGrid.allDotOffsets(
      formationName: '4-4-2',
      size: size,
    );
    expect(withLayout.length, 11);
    expect(withLayout.first, fallback.first);
    // 커스텀 layout과 슬롯 기본은 필드 좌표가 다름
    expect(withLayout.sublist(1), isNot(fallback.sublist(1)));
  });

  test('parseLayout은 잘못된 길이를 null로', () {
    expect(FormationLayoutGrid.parseLayout(null), isNull);
    expect(FormationLayoutGrid.parseLayout([]), isNull);
    expect(
      FormationLayoutGrid.parseLayout([
        for (var i = 0; i < 10; i++) {'slot': 2, 'cell': 1},
      ]),
      hasLength(10),
    );
  });
}
