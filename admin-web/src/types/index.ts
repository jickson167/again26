export type PlayerPosition = 'fw' | 'mf' | 'df' | 'gk';

export interface PlayerGrowth {
  speed: number;
  power: number;
  technique: number;
}

export interface Player {
  id: string;
  name: string;
  fake_name?: string | null;
  position: PlayerPosition;
  position_fit: Record<string, number>;
  rank?: number | null;
  age_stage?: string | null;
  peak_age?: number | null;
  detail_position?: string | null;
  comment?: string | null;
  height?: number | null;
  weight?: number | null;
  nationality?: string | null;
  growth_type: PlayerGrowth[];
  speed: number;
  power: number;
  technique: number;
  shooting: number;
  passing: number;
  defense: number;
  stamina: number;
  goalkeeper: number;
  pk_ability: number;
  fk_ability: number;
  ck_ability: number;
  leadership: number;
  intelligence_sense: number;
  individual_organization: number;
  recommend_key_positions?: string | null;
  portrait_url?: string | null;
  seed_names: string[];
}

export interface Formation {
  id: string;
  name: string;
  formation_type?: string | null;
  possession: number;
  attack: number;
  stability: number;
  key_pos_1?: string | null;
  key_pos_1_slot?: number | null;
  key_pos_2?: string | null;
  key_pos_2_slot?: number | null;
  key_pos_3?: string | null;
  key_pos_3_slot?: number | null;
  comment?: string | null;
}

export interface KeyPosition {
  id: string;
  name: string;
  simple_position: PlayerPosition;
  main_stat: string;
  sub_stat: string;
  mental_pref: string;
  team_pref: string;
  description?: string | null;
  comment?: string | null;
}

export const DEFAULT_SEED = '일반시드';

export const POSITION_LABELS: Record<PlayerPosition, string> = {
  fw: 'FW',
  mf: 'MF',
  df: 'DF',
  gk: 'GK',
};

export const FIELD_SLOTS: Record<number, string> = {
  1: 'LW', 2: 'ST', 3: 'RW', 4: 'LM', 5: 'CAM', 6: 'RM',
  7: 'LB', 8: 'DM', 9: 'RB', 10: 'LWB', 11: 'CB', 12: 'RWB', 13: 'GK',
};
