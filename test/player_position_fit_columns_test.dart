import 'package:flutter_test/flutter_test.dart';

import 'package:again26/models/player_position_fit_columns.dart';

void main() {
  test('pos_gk maps to field slot 13 not LW slot 1', () {
    expect(playerPositionFitSlotForColumn('pos_gk'), 13);
    expect(playerPositionFitSlotForColumn('pos_lw'), 1);
  });

  test('every CSV column maps to a valid field slot', () {
    for (final column in playerPositionFitCsvColumns) {
      final slot = playerPositionFitSlotForColumn(column);
      expect(slot, greaterThanOrEqualTo(1));
      expect(slot, lessThanOrEqualTo(13));
    }
  });
}
