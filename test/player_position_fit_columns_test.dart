import 'package:flutter_test/flutter_test.dart';

import 'package:again26/models/player_position_fit_columns.dart';

void main() {
  test('pos_gk maps to field slot 13 not LW slot 1', () {
    expect(playerPositionFitSlotForColumn('pos_gk'), 13);
    expect(playerPositionFitSlotForColumn('pos_lw'), 1);
  });

  test('pos_lm and pos_rm map to LM/RM field slots', () {
    expect(playerPositionFitSlotForColumn('pos_lm'), 4);
    expect(playerPositionFitSlotForColumn('pos_rm'), 6);
  });

  test('CSV columns include pos_lm and pos_rm in expected order', () {
    expect(playerPositionFitCsvColumns, containsAll(['pos_lm', 'pos_rm']));
    final rwb = playerPositionFitCsvColumns.indexOf('pos_rwb');
    final lm = playerPositionFitCsvColumns.indexOf('pos_lm');
    final rm = playerPositionFitCsvColumns.indexOf('pos_rm');
    final lw = playerPositionFitCsvColumns.indexOf('pos_lw');
    expect(lm, rwb + 1);
    expect(rm, lm + 1);
    expect(lw, rm + 1);
  });

  test('every CSV column maps to a valid field slot', () {
    for (final column in playerPositionFitCsvColumns) {
      final slot = playerPositionFitSlotForColumn(column);
      expect(slot, greaterThanOrEqualTo(1));
      expect(slot, lessThanOrEqualTo(13));
    }
  });
}
