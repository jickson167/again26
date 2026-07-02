import 'package:again26/utils/formation_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('4-2-3-1 은 필드 10명 + GK 11점', () {
    expect(FormationShape.parseLineCounts('4-2-3-1'), [4, 2, 3, 1]);
    expect(FormationShape.outfieldCount('4-2-3-1'), 10);
    expect(FormationPitchLayout.totalDots('4-2-3-1'), 11);
  });

  test('4-4-2 는 11점', () {
    expect(FormationPitchLayout.totalDots('4-4-2'), 11);
  });

  test('3-4-1-2 는 11점', () {
    expect(FormationPitchLayout.parseLines('3-4-1-2'), [3, 4, 1, 2]);
    expect(FormationPitchLayout.totalDots('3-4-1-2'), 11);
  });

  test('모든 런치 포메이션은 11점', () {
    const names = [
      '4-4-2',
      '4-3-3',
      '4-2-3-1',
      '3-4-1-2',
      '3-5-2',
      '3-4-3',
      '4-1-4-1',
      '4-5-1',
      '4-3-1-2',
      '4-1-2-1-2',
      '5-3-2',
      '5-4-1',
      '3-2-4-1',
      '4-2-2-2',
      '4-2-4',
    ];
    for (final name in names) {
      expect(FormationPitchLayout.totalDots(name), 11, reason: name);
    }
  });
}
