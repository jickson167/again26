import type { SimulationConfig } from "./config.ts";
import type { EffectiveAbilities, FormationType } from "./types.ts";

/** Performance multiplier from current staminaFraction (gradual curve). */
export function fatiguePerformanceMul(
  staminaFraction: number,
  config: SimulationConfig,
): number {
  const s = staminaFraction;
  if (s >= config.fatigueIgnoreAbove) return 1;
  if (s >= config.fatigueMildAbove) {
    const t = (config.fatigueIgnoreAbove - s) /
      (config.fatigueIgnoreAbove - config.fatigueMildAbove);
    return 1 - (1 - config.fatigueMildMul) * t;
  }
  if (s >= config.fatigueSevereBelow) {
    const t = (config.fatigueMildAbove - s) /
      (config.fatigueMildAbove - config.fatigueSevereBelow);
    return config.fatigueMildMul -
      (config.fatigueMildMul - config.fatigueModerateMul) * t;
  }
  const t = Math.min(1, (config.fatigueSevereBelow - s) / config.fatigueSevereBelow);
  return config.fatigueModerateMul -
    (config.fatigueModerateMul - config.fatigueSevereMul) * t;
}

export interface DrainContext {
  minute: number;
  formationType?: string;
  styleExtra: number;
  trailing: boolean;
  redCardDeficit: number;
  pressIntensity: number;
}

/** Differential stamina drain for one player this tick. */
export function computePlayerDrain(
  a: EffectiveAbilities,
  config: SimulationConfig,
  ctx: DrainContext,
): number {
  if (!a.onPitch || a.sentOff || a.injuredOut) return 0;

  let drain = config.staminaDrainPerTick * config.tickMinutes;
  drain += ctx.styleExtra;

  const roleMul = config.roleDrainMul[a.fitSlot] ?? 1;
  drain *= roleMul;

  const typeKey = (ctx.formationType ?? "T").toUpperCase();
  const typeMod = config.formationTypeMods[typeKey];
  if (typeMod) drain *= typeMod.staminaDrainMul;

  // Activity
  drain *= 1 +
    a.sprintActions * 0.0009 +
    a.pressingActions * 0.0007 +
    a.tackleActions * 0.0006 +
    a.duelActions * 0.0005 +
    a.attackInvolvements * 0.0004;

  drain *= 1 + ctx.pressIntensity * 0.08;

  if (ctx.minute >= 45) {
    drain *= config.lateFatigueCurve;
  }
  if (ctx.trailing && ctx.minute >= 45) {
    drain *= config.trailingDrainMul;
  }
  if (ctx.redCardDeficit > 0) {
    drain *= Math.pow(config.redCardDrainMul, ctx.redCardDeficit);
  }

  // High stamina stat reduces drain
  const relief = 1 -
    (Math.max(0, Math.min(10, a.staminaStat)) / 10) *
      config.staminaStatDrainRelief;
  drain *= Math.max(0.55, relief);

  return drain;
}

export function applyDrain(
  a: EffectiveAbilities,
  drain: number,
  config: SimulationConfig,
): void {
  if (!a.onPitch || a.sentOff || a.injuredOut) return;
  a.staminaFraction = Math.max(
    config.staminaFloor,
    a.staminaFraction - drain,
  );
  a.fatigue = 1 - a.staminaFraction;
}

/** Apply fatigue curve to combat axes (mutates abilities in place for this tick view). */
export function applyFatigueToAxes(
  abilities: EffectiveAbilities[],
  config: SimulationConfig,
): void {
  for (const a of abilities) {
    if (!a.onPitch || a.sentOff) continue;
    const mul = fatiguePerformanceMul(a.staminaFraction, config);
    if (mul >= 0.999) continue;
    a.attack *= mul;
    a.creation *= mul;
    a.midfield *= mul;
    a.press *= mul;
    a.defense *= mul;
    a.aerial *= mul;
    a.physical *= mul;
    a.goalkeeping *= Math.sqrt(mul); // GK less sensitive
  }
}

export function normalizeFormationType(
  raw?: string,
): FormationType | undefined {
  if (!raw) return undefined;
  const u = raw.trim().toUpperCase();
  if (u === "P" || u === "S" || u === "T") return u;
  return undefined;
}
