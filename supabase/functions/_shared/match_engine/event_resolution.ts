import type { EventAbilityWeights, SimulationConfig } from "./config.ts";
import { fatiguePerformanceMul } from "./fatigue.ts";
import type { EffectiveAbilities } from "./types.ts";

function clamp01(n: number): number {
  return Math.max(0, Math.min(1, n));
}

/** Weighted ability score in ~0..10 space, then fatigue-adjusted. */
export function abilityScore(
  a: EffectiveAbilities,
  w: EventAbilityWeights,
  config: SimulationConfig,
): number {
  const raw =
    a.speed * w.speed +
    a.power * w.power +
    a.technique * w.technique +
    a.shooting * w.shooting +
    a.passing * w.passing +
    a.staminaStat * w.stamina +
    a.leadership * w.leadership;
  const weightSum =
    w.speed + w.power + w.technique + w.shooting + w.passing + w.stamina +
    w.leadership;
  const base = weightSum > 0 ? raw / weightSum : 5;
  const fatMul = fatiguePerformanceMul(a.staminaFraction, config);
  const fatigueHit = 1 - (1 - fatMul) * w.fatiguePenalty;
  return base * fatigueHit;
}

export function contestProb(
  attackerScore: number,
  defenderScore: number,
  config: SimulationConfig,
): number {
  const soft = config.contestSoftness;
  const a = Math.pow(Math.max(0.01, attackerScore), soft);
  const d = Math.pow(Math.max(0.01, defenderScore), soft);
  let share = a / (a + d);
  const floor = config.underdogFloor;
  return Math.min(1 - floor, Math.max(floor, share));
}

export function personalShotFactor(
  shooter: EffectiveAbilities,
  config: SimulationConfig,
): number {
  const score = abilityScore(shooter, config.shotAbilityWeights, config);
  // Map ~3..9 → ~0.85..1.15
  return 0.85 + (score / 10) * 0.3;
}

export function personalPassSuccess(
  passer: EffectiveAbilities,
  pressure: number,
  config: SimulationConfig,
): number {
  const score = abilityScore(passer, config.passAbilityWeights, config);
  const base = 0.42 + (score / 10) * 0.45;
  const pressPen = Math.min(0.2, pressure * 0.15);
  return clamp01(base - pressPen);
}

export function dribbleSuccess(
  attacker: EffectiveAbilities,
  defender: EffectiveAbilities | undefined,
  config: SimulationConfig,
): number {
  const att = abilityScore(attacker, config.dribbleAbilityWeights, config);
  const def = defender
    ? abilityScore(defender, config.tackleAbilityWeights, config)
    : 5;
  return contestProb(att, def, config);
}

export function duelSuccess(
  a: EffectiveAbilities,
  b: EffectiveAbilities,
  config: SimulationConfig,
): number {
  return contestProb(
    abilityScore(a, config.duelAbilityWeights, config),
    abilityScore(b, config.duelAbilityWeights, config),
    config,
  );
}

export function aerialSuccess(
  a: EffectiveAbilities,
  b: EffectiveAbilities,
  config: SimulationConfig,
): number {
  return contestProb(
    abilityScore(a, config.aerialAbilityWeights, config) + a.aerial * 0.15,
    abilityScore(b, config.aerialAbilityWeights, config) + b.aerial * 0.15,
    config,
  );
}

export function tackleSuccess(
  tackler: EffectiveAbilities,
  ballCarrier: EffectiveAbilities,
  config: SimulationConfig,
): number {
  return contestProb(
    abilityScore(tackler, config.tackleAbilityWeights, config),
    abilityScore(ballCarrier, config.dribbleAbilityWeights, config),
    config,
  );
}

/** Aggressive collision foul chance — only when tackle is aggressive. */
export function aggressiveFoulChance(
  tackler: EffectiveAbilities,
  success: boolean,
  config: SimulationConfig,
): number {
  const power = Math.max(0, Math.min(10, tackler.power));
  let p = config.aggressiveFoulPowerFactor * (power / 10);
  if (!success) p *= 1.6;
  return Math.min(0.12, p);
}
