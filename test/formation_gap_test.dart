import 'dart:ui';

import 'package:again26/utils/formation_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('2명·4명 줄 모두 양끝에 붙지 않는다', () {
    const size = Size(136, 136);
    const gap = 136 * FormationPitchLayout.dotGapRatio;

    final dots = FormationPitchLayout.allDotOffsets('3-4-1-2', size);
    final twoRow = dots.sublist(dots.length - 2);
    final fourRow = dots.sublist(4, 8);

    expect(twoRow[0].dx, closeTo(68 - gap / 2, 0.01));
    expect(twoRow[1].dx, closeTo(68 + gap / 2, 0.01));
    expect(twoRow[0].dx, greaterThan(size.width * 0.35));
    expect(twoRow[1].dx, lessThan(size.width * 0.65));

    expect(fourRow.first.dx, greaterThan(size.width * 0.25));
    expect(fourRow.last.dx, lessThan(size.width * 0.75));
    expect(fourRow[1].dx - fourRow[0].dx, closeTo(gap, 0.01));
    expect(fourRow[2].dx - fourRow[1].dx, closeTo(gap, 0.01));
  });
}
