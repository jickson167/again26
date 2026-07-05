import Papa from 'papaparse';
import type { Formation, KeyPosition, Player, PlayerPosition } from '../types';
import { clampStat } from '../lib/utils';

const POS_FIT_COLS = [
  'pos_lw', 'pos_st', 'pos_rw', 'pos_lm', 'pos_cam', 'pos_rm',
  'pos_lb', 'pos_dm', 'pos_rb', 'pos_lwb', 'pos_cb', 'pos_rwb', 'pos_gk',
];

export const PLAYER_CSV_HEADERS = [
  'id', 'name', 'fake_name', 'position', 'rank', 'current_age', 'peak_age',
  'height', 'weight', 'nationality', ...POS_FIT_COLS,
  ...Array.from({ length: 10 }, (_, i) => [
    `growth_${i + 1}_speed`, `growth_${i + 1}_power`, `growth_${i + 1}_technique`,
  ]).flat(),
  'speed', 'power', 'technique', 'pk_ability', 'fk_ability', 'ck_ability',
  'leadership', 'intelligence_sense', 'individual_organization',
  'detail_position', 'comment', 'shooting', 'passing', 'defense', 'stamina',
  'goalkeeper', 'recommend_key_positions', 'portrait_url', 'seed_names',
];

function defaultFit(): Record<string, number> {
  const fit: Record<string, number> = {};
  for (let i = 1; i <= 13; i++) fit[String(i)] = 0;
  return fit;
}

function parseFit(row: Record<string, string>): Record<string, number> {
  const fit = defaultFit();
  POS_FIT_COLS.forEach((col, idx) => {
    const slotMap = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    const v = clampStat(row[col]);
    const slot = String(slotMap[idx]);
    fit[slot] = Math.max(fit[slot] ?? 0, v);
  });
  for (let i = 1; i <= 13; i++) {
    const legacy = row[`pos_${i}`];
    if (legacy) fit[String(i)] = clampStat(legacy);
  }
  return fit;
}

function parseGrowth(row: Record<string, string>): PlayerGrowth[] {
  return Array.from({ length: 10 }, (_, i) => ({
    speed: clampStat(row[`growth_${i + 1}_speed`]),
    power: clampStat(row[`growth_${i + 1}_power`]),
    technique: clampStat(row[`growth_${i + 1}_technique`]),
  }));
}

function parseSeeds(raw: string): string[] {
  if (!raw?.trim()) return [];
  return raw.split(/[;；|]/).map((s) => s.trim()).filter(Boolean);
}

export function parsePlayersCsv(content: string): Player[] {
  const parsed = Papa.parse<Record<string, string>>(content, {
    header: true,
    skipEmptyLines: true,
  });
  if (parsed.errors.length) throw new Error(parsed.errors[0]?.message ?? 'CSV 파싱 오류');

  return (parsed.data ?? [])
    .filter((row) => row.name?.trim())
    .map((row) => ({
      id: row.id?.trim() ?? '',
      name: row.name?.trim() ?? '',
      fake_name: row.fake_name?.trim() || null,
      position: (row.position?.trim().toLowerCase() || 'mf') as PlayerPosition,
      position_fit: parseFit(row),
      rank: row.rank ? parseInt(row.rank, 10) : null,
      age_stage: row.current_age?.trim() || row.age_stage?.trim() || null,
      peak_age: row.peak_age ? parseInt(row.peak_age, 10) : null,
      detail_position: row.detail_position?.trim() || null,
      comment: row.comment?.trim() || null,
      height: row.height ? parseInt(row.height, 10) : null,
      weight: row.weight ? parseInt(row.weight, 10) : null,
      nationality: row.nationality?.trim() || null,
      growth_type: parseGrowth(row),
      speed: clampStat(row.speed),
      power: clampStat(row.power),
      technique: clampStat(row.technique),
      shooting: clampStat(row.shooting),
      passing: clampStat(row.passing),
      defense: clampStat(row.defense),
      stamina: clampStat(row.stamina),
      goalkeeper: clampStat(row.goalkeeper),
      pk_ability: clampStat(row.pk_ability),
      fk_ability: clampStat(row.fk_ability),
      ck_ability: clampStat(row.ck_ability),
      leadership: clampStat(row.leadership),
      intelligence_sense: clampStat(row.intelligence_sense, 5),
      individual_organization: clampStat(row.individual_organization, 5),
      recommend_key_positions: row.recommend_key_positions?.trim() || null,
      portrait_url: row.portrait_url?.trim() || null,
      seed_names: parseSeeds(row.seed_names ?? ''),
    }));
}

function fitToCols(fit: Record<string, number>): string[] {
  const slotMap = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
  return slotMap.map((s) => String(fit[String(s)] ?? 0));
}

export function exportPlayersCsv(players: Player[]): string {
  const rows = players.map((p) => ({
    id: p.id,
    name: p.name,
    fake_name: p.fake_name ?? '',
    position: p.position,
    rank: p.rank ?? '',
    current_age: p.age_stage ?? '',
    peak_age: p.peak_age ?? '',
    height: p.height ?? '',
    weight: p.weight ?? '',
    nationality: p.nationality ?? '',
    ...Object.fromEntries(POS_FIT_COLS.map((col, i) => [col, fitToCols(p.position_fit)[i]])),
    ...Object.fromEntries(
      p.growth_type.flatMap((g, i) => [
        [`growth_${i + 1}_speed`, g.speed],
        [`growth_${i + 1}_power`, g.power],
        [`growth_${i + 1}_technique`, g.technique],
      ]),
    ),
    speed: p.speed,
    power: p.power,
    technique: p.technique,
    pk_ability: p.pk_ability,
    fk_ability: p.fk_ability,
    ck_ability: p.ck_ability,
    leadership: p.leadership,
    intelligence_sense: p.intelligence_sense,
    individual_organization: p.individual_organization,
    detail_position: p.detail_position ?? '',
    comment: p.comment ?? '',
    shooting: p.shooting,
    passing: p.passing,
    defense: p.defense,
    stamina: p.stamina,
    goalkeeper: p.goalkeeper,
    recommend_key_positions: p.recommend_key_positions ?? '',
    portrait_url: p.portrait_url ?? '',
    seed_names: (p.seed_names ?? []).join(';'),
  }));
  return Papa.unparse(rows, { columns: PLAYER_CSV_HEADERS });
}

export const FORMATION_HEADERS = [
  'formation_id', 'name', 'formation_type', 'possession', 'attack', 'stability',
  'key_pos_1', 'key_pos_1_slot', 'key_pos_2', 'key_pos_2_slot', 'key_pos_3', 'key_pos_3_slot', 'comment',
];

export function parseFormationsCsv(content: string) {
  const parsed = Papa.parse<Record<string, string>>(content, { header: true, skipEmptyLines: true });
  return (parsed.data ?? []).filter((r) => r.formation_id || r.name).map((r) => ({
    id: r.formation_id?.trim() ?? '',
    name: r.name?.trim() ?? '',
    formation_type: r.formation_type?.trim() || null,
    possession: clampStat(r.possession, 5),
    attack: clampStat(r.attack, 5),
    stability: clampStat(r.stability, 5),
    key_pos_1: r.key_pos_1?.trim() || null,
    key_pos_1_slot: r.key_pos_1_slot ? parseInt(r.key_pos_1_slot, 10) : null,
    key_pos_2: r.key_pos_2?.trim() || null,
    key_pos_2_slot: r.key_pos_2_slot ? parseInt(r.key_pos_2_slot, 10) : null,
    key_pos_3: r.key_pos_3?.trim() || null,
    key_pos_3_slot: r.key_pos_3_slot ? parseInt(r.key_pos_3_slot, 10) : null,
    comment: r.comment?.trim() || null,
  }));
}

export function exportFormationsCsv(items: Formation[]): string {
  const rows = items.map((f) => ({
    formation_id: f.id,
    name: f.name,
    formation_type: f.formation_type ?? '',
    possession: f.possession,
    attack: f.attack,
    stability: f.stability,
    key_pos_1: f.key_pos_1 ?? '',
    key_pos_1_slot: f.key_pos_1_slot ?? '',
    key_pos_2: f.key_pos_2 ?? '',
    key_pos_2_slot: f.key_pos_2_slot ?? '',
    key_pos_3: f.key_pos_3 ?? '',
    key_pos_3_slot: f.key_pos_3_slot ?? '',
    comment: f.comment ?? '',
  }));
  return Papa.unparse(rows, { columns: FORMATION_HEADERS });
}

export const KEY_POS_HEADERS = [
  'key_position_id', 'name', 'simple_position', 'main_stat', 'sub_stat', 'mental_pref', 'team_pref', 'description',
];

export function parseKeyPositionsCsv(content: string) {
  const parsed = Papa.parse<Record<string, string>>(content, { header: true, skipEmptyLines: true });
  return (parsed.data ?? []).filter((r) => r.key_position_id || r.name).map((r) => ({
    id: r.key_position_id?.trim() ?? '',
    name: r.name?.trim() ?? '',
    simple_position: (r.simple_position?.trim().toLowerCase() || 'mf') as PlayerPosition,
    main_stat: r.main_stat?.trim() ?? '',
    sub_stat: r.sub_stat?.trim() ?? '',
    mental_pref: r.mental_pref?.trim() || 'intelligence',
    team_pref: r.team_pref?.trim() || 'organization',
    description: r.description?.trim() || null,
    comment: null,
  }));
}

export function exportKeyPositionsCsv(items: KeyPosition[]): string {
  const rows = items.map((k) => ({
    key_position_id: k.id,
    name: k.name,
    simple_position: k.simple_position,
    main_stat: k.main_stat,
    sub_stat: k.sub_stat,
    mental_pref: k.mental_pref,
    team_pref: k.team_pref,
    description: k.description ?? '',
  }));
  return Papa.unparse(rows, { columns: KEY_POS_HEADERS });
}
