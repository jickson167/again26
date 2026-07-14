/// CSV 적정포지션 컬럼 → 필드 13슬롯 ([FieldPositionLayout] 기준)
const playerPositionFitCsvColumns = [
  'pos_gk',
  'pos_lb',
  'pos_cb',
  'pos_rb',
  'pos_lwb',
  'pos_cdm',
  'pos_cm',
  'pos_cam',
  'pos_rwb',
  'pos_lm',
  'pos_rm',
  'pos_lw',
  'pos_rw',
  'pos_st',
];

/// pos_* 컬럼명 → 그리드 슬롯 (1=LW … 13=GK)
const playerPositionFitColumnToSlot = {
  'pos_gk': 13,
  'pos_lb': 7,
  'pos_cb': 11,
  'pos_rb': 9,
  'pos_lwb': 10,
  'pos_cdm': 8,
  'pos_cm': 5,
  'pos_cam': 5,
  'pos_rwb': 12,
  'pos_lm': 4,
  'pos_rm': 6,
  'pos_lw': 1,
  'pos_rw': 3,
  'pos_st': 2,
};

int playerPositionFitSlotForColumn(String column) {
  return playerPositionFitColumnToSlot[column] ?? 0;
}

const playerPositionFitCsvLabels = {
  'pos_gk': 'GK',
  'pos_lb': 'LB',
  'pos_cb': 'CB',
  'pos_rb': 'RB',
  'pos_lwb': 'LWB',
  'pos_cdm': 'CDM',
  'pos_cm': 'CM',
  'pos_cam': 'CAM',
  'pos_rwb': 'RWB',
  'pos_lm': 'LM',
  'pos_rm': 'RM',
  'pos_lw': 'LW',
  'pos_rw': 'RW',
  'pos_st': 'ST',
};
