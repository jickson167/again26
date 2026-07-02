import 'dart:ui';

import 'package:again26/utils/formation_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 줄이 동일한 고정 간격으로 넓게 배치된다', () {
    const size = Size(136, 136);
    const gap = 136 * FormationPitchLayout.dotGapRatio;

    final dots = FormationPitchLayout.allDotOffsets('3-4-1-2', size);
    final twoRow = dots.sublist(dots.length - 2);
    final fourRow = dots.sublist(4, 8);

    expect(twoRow[0].dx, closeTo(68 - gap / 2, 0.01));
    expect(twoRow[1].dx, closeTo(68 + gap / 2, 0.01));

    expect(fourRow[1].dx - fourRow[0].dx, closeTo(gap, 0.01));
    expect(fourRow[2].dx - fourRow[1].dx, closeTo(gap, 0.01));
    expect(fourRow.last.dx - fourRow.first.dx, closeTo(gap * 3, 0.01));

    expect(fourRow.last.dx - fourRow.first.dx, greaterThan(size.width * 0.55));
    expect(fourRow.first.dx, greaterThan(size.width * 0.05));
    expect(fourRow.last.dx, lessThan(size.width * 0.95));
  });
}
