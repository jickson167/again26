import Papa from 'papaparse';
import type { Formation, KeyPosition, Player, PlayerGrowth, PlayerPosition } from '../types';
import { clampStat } from '../lib/utils';

/** Flutter `playerPositionFitCsvColumns` 와 동일 순서 */
const POS_FIT_COLS = [
  'pos_gk', 'pos_lb', 'pos_cb', 'pos_rb', 'pos_lwb', 'pos_cdm', 'pos_cm',
  'pos_cam', 'pos_rwb', 'pos_lm', 'pos_rm', 'pos_lw', 'pos_rw', 'pos_st',
];

/** pos_* → 필드 슬롯 1(LW)…13(GK) — FieldPositionLayout과 동일 */
const POS_FIT_COL_TO_SLOT: Record<string, number> = {
  pos_gk: 13,
  pos_lb: 7,
  pos_cb: 11,
  pos_rb: 9,
  pos_lwb: 10,
  pos_cdm: 8,
  pos_dm: 8, // legacy alias
  pos_cm: 5,
  pos_cam: 5,
  pos_rwb: 12,
  pos_lm: 4,
  pos_rm: 6,
  pos_lw: 1,
  pos_rw: 3,
  pos_st: 2,
};

export const PLAYER_CSV_HEADERS = [
  'id', 'name', 'fake_name', 'position', 'rank', 'current_age', 'peak_age',
  'height', 'weight', 'nationality', ...POS_FIT_COLS,
  ...Array.from({ length: 10 }, (_, i) => [
    `growth_${i + 1}_speed`, `growth_${i + 1}_power`, `growth_${i + 1}_technique`,
  ]).flat(),
  'speed', 'power', 'technique', 'pk_ability', 'fk_ability', 'ck_ability',
  'leadership',
  'detail_position', 'comment', 'shooting', 'passing', 'stamina',
  'recommend_key_positions', 'portrait_url', 'seed_names',
];

function defaultFit(): Record<string, number> {
  const fit: Record<string, number> = {};
  for (let i = 1; i <= 13; i++) fit[String(i)] = 0;
  return fit;
}

function parseFit(row: Record<string, string>): Record<string, number> {
  const fit = defaultFit();
  for (const [col, slot] of Object.entries(POS_FIT_COL_TO_SLOT)) {
    const raw = row[col];
    if (raw === undefined || raw === '') continue;
    const v = clampStat(raw);
    const key = String(slot);
    fit[key] = Math.max(fit[key] ?? 0, v);
  }
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
  const items = raw.split(/[;；|]/).map((s) => s.trim()).filter(Boolean);
  if (items.length <= 1) return items;
  const nonGeneral = items.filter(
    (s) => s !== '일반시드' && s !== '일반 시드',
  );
  return [nonGeneral[0] ?? items[0]];
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
      stamina: clampStat(row.stamina),
      pk_ability: clampStat(row.pk_ability),
      fk_ability: clampStat(row.fk_ability),
      ck_ability: clampStat(row.ck_ability),
      leadership: clampStat(row.leadership),
      recommend_key_positions: row.recommend_key_positions?.trim() || null,
      portrait_url: row.portrait_url?.trim() || null,
      seed_names: parseSeeds(row.seed_names ?? ''),
    }));
}

function fitToCols(fit: Record<string, number>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const col of POS_FIT_COLS) {
    const slot = POS_FIT_COL_TO_SLOT[col];
    out[col] = String(fit[String(slot)] ?? 0);
  }
  return out;
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
    ...fitToCols(p.position_fit),
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
    detail_position: p.detail_position ?? '',
    comment: p.comment ?? '',
    shooting: p.shooting,
    passing: p.passing,
    stamina: p.stamina,
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
