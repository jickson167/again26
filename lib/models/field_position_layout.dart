/// 필드 13슬롯 라벨 (pos_1 ~ pos_13)
class FieldPositionLayout {
  static const labels = {
    1: 'LW',
    2: 'ST',
    3: 'RW',
    4: 'LM',
    5: 'CAM',
    6: 'RM',
    7: 'LB',
    8: 'DM',
    9: 'RB',
    10: 'LWB',
    11: 'CB',
    12: 'RWB',
    13: 'GK',
  };

  /// 그리드 배치 (3열). null = 빈 칸
  static const gridRows = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
    [10, 11, 12],
    [null, 13, null],
  ];
}
