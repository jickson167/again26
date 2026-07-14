import type { SimulationConfig, StatWeights } from "./config.ts";
import { applyFitBlend, positionFitMultiplier } from "./position_fit.ts";
import type {
  EffectiveAbilities,
  Lane,
  PitchLine,
  PlayerSimulationSnapshot,
  PositionAssignment,
  TeamSimulationSnapshot,
} from "./types.ts";

function clampStat(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(10, n));
}

function weightedRaw(
  p: PlayerSimulationSnapshot,
  w: StatWeights,
): { key: number; physical: number; total: number } {
  const speed = clampStat(p.speed);
  const power = clampStat(p.power);
  const technique = clampStat(p.technique);
  const shooting = clampStat(p.shooting);
  const passing = clampStat(p.passing);
  const stamina = clampStat(p.stamina);
  const leadership = clampStat(p.leadership ?? 5);
  const pk = clampStat(p.pkAbility ?? 5);
  const fk = clampStat(p.fkAbility ?? 5);
  const ck = clampStat(p.ckAbility ?? 5);

  const physicalPart = speed * (w.speed ?? 0) + power * (w.power ?? 0);
  const keyPart =
    technique * (w.technique ?? 0) +
    shooting * (w.shooting ?? 0) +
    passing * (w.passing ?? 0) +
    stamina * (w.stamina ?? 0) +
    leadership * (w.leadership ?? 0) +
    pk * (w.pkAbility ?? 0) +
    fk * (w.fkAbility ?? 0) +
    ck * (w.ckAbility ?? 0);

  return {
    key: keyPart,
    physical: physicalPart,
    total: keyPart + physicalPart,
  };
}

function composeAxis(
  p: PlayerSimulationSnapshot,
  w: StatWeights,
  fitMul: number,
  config: SimulationConfig,
): number {
  const parts = weightedRaw(p, w);
  const key = applyFitBlend(parts.key, fitMul, config.keyStatFitBlend);
  const phys = applyFitBlend(parts.physical, fitMul, config.physicalFitBlend);
  return key + phys;
}

function toEffective(
  player: PlayerSimulationSnapshot,
  assignment: PositionAssignment,
  config: SimulationConfig,
  onPitch: boolean,
): EffectiveAbilities {
  const fitMul = positionFitMultiplier(player.assignedFit, config);
  const staminaFraction = player.staminaFraction ?? 1;
  return {
    playerId: player.playerId,
    attack: composeAxis(player, config.attackWeights, fitMul, config),
    creation: composeAxis(player, config.creationWeights, fitMul, config),
    midfield: composeAxis(player, config.midfieldWeights, fitMul, config),
    press: composeAxis(player, config.pressWeights, fitMul, config),
    defense: composeAxis(player, config.defenseWeights, fitMul, config),
    aerial: composeAxis(player, config.aerialWeights, fitMul, config),
    setpiece: composeAxis(player, config.setpieceWeights, fitMul, config),
    goalkeeping: composeAxis(player, config.goalkeepingWeights, fitMul, config),
    physical:
      applyFitBlend(clampStat(player.speed), fitMul, config.physicalFitBlend) +
      applyFitBlend(clampStat(player.power), fitMul, config.physicalFitBlend),
    staminaFraction,
    fatigue: 1 - staminaFraction,
    sentOff: false,
    onPitch,
    injuredOut: false,
    fitSlot: assignment.fitSlot,
    pitchSlot: assignment.pitchSlot,
    lane: assignment.lane,
    line: assignment.line,
    speed: clampStat(player.speed),
    power: clampStat(player.power),
    technique: clampStat(player.technique),
    shooting: clampStat(player.shooting),
    passing: clampStat(player.passing),
    staminaStat: clampStat(player.stamina),
    leadership: clampStat(player.leadership ?? 5),
    sprintActions: 0,
    pressingActions: 0,
    tackleActions: 0,
    duelActions: 0,
    attackInvolvements: 0,
    styleIds: player.styleIds ? [...player.styleIds] : [],
  };
}

export function buildEffectiveAbilities(
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): EffectiveAbilities[] {
  const bySlot = new Map<number, PositionAssignment>();
  for (const a of team.assignments) {
    bySlot.set(a.pitchSlot, a);
  }

  const result: EffectiveAbilities[] = [];
  for (let i = 0; i < team.starters.length; i++) {
    const player = team.starters[i]!;
    const assignment =
      bySlot.get(i + 1) ??
      team.assignments[i] ??
      defaultAssignment(i + 1);
    result.push(toEffective(player, assignment, config, true));
  }

  // Bench: off pitch, default midfield slot placeholders
  for (let i = 0; i < team.bench.length; i++) {
    const player = team.bench[i]!;
    if (result.some((r) => r.playerId === player.playerId)) continue;
    const assignment: PositionAssignment = {
      pitchSlot: 100 + i,
      fitSlot: 5,
      lane: "center",
      line: "midfield",
    };
    result.push(toEffective(player, assignment, config, false));
  }
  return result;
}

function defaultAssignment(pitchSlot: number): PositionAssignment {
  const table: Array<{ fitSlot: number; lane: Lane; line: PitchLine }> = [
    { fitSlot: 13, lane: "center", line: "gk" },
    { fitSlot: 7, lane: "left", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 9, lane: "right", line: "defense" },
    { fitSlot: 8, lane: "center", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 1, lane: "left", line: "attack" },
    { fitSlot: 2, lane: "center", line: "attack" },
    { fitSlot: 3, lane: "right", line: "attack" },
  ];
  const t = table[pitchSlot - 1] ?? table[0]!;
  return { pitchSlot, ...t };
}

function eligible(a: EffectiveAbilities): boolean {
  return a.onPitch && !a.sentOff && !a.injuredOut;
}

export function pickAttacker(
  abilities: EffectiveAbilities[],
  lane: Lane,
): EffectiveAbilities | undefined {
  const alive = abilities.filter((a) => eligible(a) && a.line !== "gk");
  const preferred = alive.filter(
    (a) =>
      a.lane === lane &&
      (a.line === "attack" || a.line === "midfield"),
  );
  const pool = preferred.length > 0 ? preferred : alive;
  if (pool.length === 0) return undefined;
  return pool.reduce((best, cur) =>
    cur.attack + cur.creation > best.attack + best.creation ? cur : best
  );
}

export function pickCreator(
  abilities: EffectiveAbilities[],
  lane: Lane,
): EffectiveAbilities | undefined {
  const alive = abilities.filter((a) => eligible(a) && a.line !== "gk");
  const preferred = alive.filter((a) => a.lane === lane || a.line === "midfield");
  const pool = preferred.length > 0 ? preferred : alive;
  if (pool.length === 0) return undefined;
  return pool.reduce((best, cur) =>
    cur.creation > best.creation ? cur : best
  );
}

export function pickGoalkeeper(
  abilities: EffectiveAbilities[],
): EffectiveAbilities | undefined {
  const gk = abilities.find((a) => eligible(a) && a.line === "gk");
  if (gk) return gk;
  return abilities.find((a) => eligible(a));
}

export function pickDefender(
  abilities: EffectiveAbilities[],
  lane: Lane,
): EffectiveAbilities | undefined {
  const alive = abilities.filter((a) => eligible(a) && a.line !== "gk");
  const preferred = alive.filter(
    (a) => a.lane === lane && (a.line === "defense" || a.line === "midfield"),
  );
  const pool = preferred.length > 0 ? preferred : alive.filter((a) =>
    a.line === "defense"
  );
  if (pool.length === 0) return alive[0];
  return pool.reduce((best, cur) =>
    cur.defense + cur.power > best.defense + best.power ? cur : best
  );
}
