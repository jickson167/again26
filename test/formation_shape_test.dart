import 'package:again26/utils/formation_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('4-1-4-1 슬롯 배치', () {
    final slots = FormationShape.occupiedSlots('4-1-4-1');
    expect(slots, containsAll([10, 11, 12, 9, 8, 4, 5, 6, 7, 2, 13]));
    expect(slots.length, 11);
  });

  test('3-5-2 슬롯 배치', () {
    final slots = FormationShape.occupiedSlots('3-5-2');
    expect(slots, containsAll([10, 11, 12, 7, 4, 5, 6, 9, 1, 3, 13]));
    expect(slots.length, 11);
  });

  test('모든 런치 포메이션은 11슬롯', () {
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
      expect(
        FormationShape.occupiedSlots(name).length,
        11,
        reason: name,
      );
    }
  });
}
