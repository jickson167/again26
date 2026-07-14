import 'package:again26/utils/field_zone_layout.dart';
import 'package:again26/utils/formation_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('포메이션 선발 슬롯은 항상 11개이고 GK(13)로 시작', () {
    const names = [
      '4-4-2',
      '4-3-3',
      '4-2-3-1',
      '3-5-2',
      '3-4-3',
      '5-3-2',
    ];
    for (final name in names) {
      final slots = FormationFieldSlots.slotsFor(name);
      expect(slots.length, 11, reason: name);
      expect(slots.first, 13, reason: name);
    }
  });

  test('시너지 색은 1~7 스케일, 1 미표시', () {
    expect(FieldZoneLayout.synergyColor(0), isNull); // 0→1
    expect(FieldZoneLayout.synergyColor(1), isNull);
    expect(FieldZoneLayout.synergyColor(2)?.a, closeTo(0.10, 0.01));
    expect(FieldZoneLayout.synergyColor(3)?.a, closeTo(0.20, 0.01));
    expect(FieldZoneLayout.synergyColor(4)?.a, closeTo(0.40, 0.01));
    expect(FieldZoneLayout.synergyColor(5)?.a, closeTo(0.60, 0.01));
    expect(FieldZoneLayout.synergyColor(6)?.a, closeTo(0.80, 0.01));
    expect(FieldZoneLayout.synergyColor(7)?.a, closeTo(0.80, 0.01));
    expect(FieldZoneLayout.synergyColor(9)?.a, closeTo(0.80, 0.01)); // 9→7
  });

  test('parseLines와 override 키가 맞다', () {
    expect(FormationPitchLayout.parseLines('레스터 4-4-2'), [4, 4, 2]);
    expect(FormationFieldSlots.slotsFor('레스터 4-4-2').length, 11);
  });
}
