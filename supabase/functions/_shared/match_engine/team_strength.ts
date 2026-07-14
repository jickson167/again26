import {
  normalizeFormationKey,
  type SimulationConfig,
  type TacticStyleMod,
  type ZoneMul,
} from "./config.ts";
import { applyFormationTypeToZones } from "./formation_profile.ts";
import { applyKeyPosToZones } from "./key_position_effect.ts";
import type {
  EffectiveAbilities,
  Lane,
  Side,
  TeamSimulationSnapshot,
  ZoneStrength,
} from "./types.ts";

function sumLane(
  abilities: EffectiveAbilities[],
  lane: Lane,
  lines: Array<EffectiveAbilities["line"]>,
  axis: keyof Pick<
    EffectiveAbilities,
    "attack" | "midfield" | "defense" | "press" | "creation"
  >,
): number {
  let total = 0;
  let n = 0;
  for (const a of abilities) {
    if (!a.onPitch || a.sentOff || a.injuredOut) continue;
    if (a.lane !== lane) continue;
    if (!lines.includes(a.line)) continue;
    total += a[axis] * a.staminaFraction;
    n++;
  }
  return n === 0 ? 1 : total;
}

function compress(value: number, exponent: number): number {
  if (value <= 0) return 0.01;
  return Math.pow(value, exponent);
}

function applyZoneMul(z: ZoneStrength, mul: Partial<ZoneMul>): void {
  z.leftAttack *= mul.leftAttack ?? 1;
  z.centerAttack *= mul.centerAttack ?? 1;
  z.rightAttack *= mul.rightAttack ?? 1;
  z.leftMid *= mul.leftMid ?? 1;
  z.centerMid *= mul.centerMid ?? 1;
  z.rightMid *= mul.rightMid ?? 1;
  z.leftDefense *= mul.leftDefense ?? 1;
  z.centerDefense *= mul.centerDefense ?? 1;
  z.rightDefense *= mul.rightDefense ?? 1;
  z.goalkeeping *= mul.goalkeeping ?? 1;
}

export function resolveTacticMod(
  style: string,
  config: SimulationConfig,
): TacticStyleMod {
  const key = style.trim().toLowerCase();
  return (
    config.tacticStyleModifiers[key] ??
      config.tacticStyleModifiers["balance"] ?? {
      zones: {},
      chanceMul: 1,
      finishMul: 1,
      possessionBias: 0,
      staminaDrainExtra: 0,
      counterMul: 1,
    }
  );
}

export function computeZoneStrength(
  abilities: EffectiveAbilities[],
  team: TeamSimulationSnapshot,
  side: Side,
  config: SimulationConfig,
  opts: {
    homeAdvantage: boolean;
    redCardCount: number;
    scoreDiff?: number;
  },
): ZoneStrength {
  const attLines: Array<EffectiveAbilities["line"]> = ["attack", "midfield"];
  const midLines: Array<EffectiveAbilities["line"]> = [
    "midfield",
    "attack",
    "defense",
  ];
  const defLines: Array<EffectiveAbilities["line"]> = ["defense", "midfield"];
  const exp = config.abilityCompressionExponent;

  let leftAttack = compress(
    sumLane(abilities, "left", attLines, "attack") +
      sumLane(abilities, "left", attLines, "creation") * 0.3,
    exp,
  );
  let centerAttack = compress(
    sumLane(abilities, "center", attLines, "attack") +
      sumLane(abilities, "center", attLines, "creation") * 0.35,
    exp,
  );
  let rightAttack = compress(
    sumLane(abilities, "right", attLines, "attack") +
      sumLane(abilities, "right", attLines, "creation") * 0.3,
    exp,
  );

  let leftMid = compress(
    sumLane(abilities, "left", midLines, "midfield") +
      sumLane(abilities, "left", midLines, "press") * 0.4,
    exp,
  );
  let centerMid = compress(
    sumLane(abilities, "center", midLines, "midfield") +
      sumLane(abilities, "center", midLines, "press") * 0.5,
    exp,
  );
  let rightMid = compress(
    sumLane(abilities, "right", midLines, "midfield") +
      sumLane(abilities, "right", midLines, "press") * 0.4,
    exp,
  );

  let leftDefense = compress(
    sumLane(abilities, "left", defLines, "defense"),
    exp,
  );
  let centerDefense = compress(
    sumLane(abilities, "center", defLines, "defense"),
    exp,
  );
  let rightDefense = compress(
    sumLane(abilities, "right", defLines, "defense"),
    exp,
  );

  const gk = abilities.find((a) =>
    a.line === "gk" && a.onPitch && !a.sentOff && !a.injuredOut
  );
  let goalkeeping = compress(
    gk ? gk.goalkeeping * gk.staminaFraction : 5,
    exp,
  );

  const tac = team.tactic;
  const attackMul = 0.88 + tac.attack * 0.024;
  const possMul = 0.92 + tac.possession * 0.016;
  const stabMul = 0.88 + tac.stability * 0.024;

  leftAttack *= attackMul;
  centerAttack *= attackMul;
  rightAttack *= attackMul;
  leftMid *= possMul;
  centerMid *= possMul;
  rightMid *= possMul;
  leftDefense *= stabMul;
  centerDefense *= stabMul;
  rightDefense *= stabMul;

  const zones: ZoneStrength = {
    leftAttack,
    centerAttack,
    rightAttack,
    leftMid,
    centerMid,
    rightMid,
    leftDefense,
    centerDefense,
    rightDefense,
    goalkeeping,
  };

  const formKey = normalizeFormationKey(team.formationName);
  const formMul = config.formationModifiers[formKey];
  if (formMul) applyZoneMul(zones, formMul);

  const styleMod = resolveTacticMod(tac.coachStyle, config);
  applyZoneMul(zones, styleMod.zones);
  const bias = 1 + styleMod.possessionBias;
  zones.leftMid *= bias;
  zones.centerMid *= bias;
  zones.rightMid *= bias;

  applyFormationTypeToZones(
    zones,
    team,
    abilities,
    config,
    opts.scoreDiff ?? 0,
  );
  applyKeyPosToZones(zones, abilities, team, config);

  if (opts.homeAdvantage && side === "home") {
    zones.leftAttack *= config.homeAdvantageAttack;
    zones.centerAttack *= config.homeAdvantageAttack;
    zones.rightAttack *= config.homeAdvantageAttack;
    zones.leftMid *= config.homeAdvantageMid;
    zones.centerMid *= config.homeAdvantageMid;
    zones.rightMid *= config.homeAdvantageMid;
  }

  if (opts.redCardCount > 0) {
    const pen = Math.pow(config.redCardStrengthPenalty, opts.redCardCount);
    zones.leftAttack *= pen;
    zones.centerAttack *= pen;
    zones.rightAttack *= pen;
    zones.leftMid *= pen;
    zones.centerMid *= pen;
    zones.rightMid *= pen;
    zones.leftDefense *= pen;
    zones.centerDefense *= pen;
    zones.rightDefense *= pen;
  }

  const outfield = abilities.filter((a) =>
    a.onPitch && !a.sentOff && !a.injuredOut && a.line !== "gk"
  );
  if (outfield.length > 0) {
    const avgSt =
      outfield.reduce((s, a) => s + a.staminaFraction, 0) / outfield.length;
    if (avgSt < 0.7) {
      const pen = config.lowStaminaDefensePenalty +
        (1 - config.lowStaminaDefensePenalty) * (avgSt / 0.7);
      zones.leftDefense *= pen;
      zones.centerDefense *= pen;
      zones.rightDefense *= pen;
    }
  }

  return zones;
}

export function softContestShare(
  attackValue: number,
  defenseValue: number,
  config: SimulationConfig,
): number {
  const soft = config.contestSoftness;
  const a = Math.pow(Math.max(0.01, attackValue), soft);
  const d = Math.pow(Math.max(0.01, defenseValue), soft);
  const share = a / (a + d);
  const floor = config.underdogFloor;
  return Math.min(1 - floor, Math.max(floor, share));
}

export function attackAxis(z: ZoneStrength, lane: Lane): number {
  switch (lane) {
    case "left":
      return z.leftAttack;
    case "right":
      return z.rightAttack;
    default:
      return z.centerAttack;
  }
}

export function midAxis(z: ZoneStrength, lane: Lane): number {
  switch (lane) {
    case "left":
      return z.leftMid;
    case "right":
      return z.rightMid;
    default:
      return z.centerMid;
  }
}

export function defenseAxis(z: ZoneStrength, lane: Lane): number {
  switch (lane) {
    case "left":
      return z.leftDefense;
    case "right":
      return z.rightDefense;
    default:
      return z.centerDefense;
  }
}

export function possessionShare(
  homeMid: number,
  awayMid: number,
): { home: number; away: number } {
  const total = homeMid + awayMid;
  if (total <= 0) return { home: 50, away: 50 };
  const home = Math.round((100 * homeMid) / total);
  return { home, away: 100 - home };
}
