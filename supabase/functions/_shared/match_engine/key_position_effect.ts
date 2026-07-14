import { positionFitMultiplier } from "./position_fit.ts";
import type { SimulationConfig } from "./config.ts";
import type {
  EffectiveAbilities,
  KeyPositionRef,
  TeamSimulationSnapshot,
  ZoneStrength,
} from "./types.ts";

function roleAxisScore(a: EffectiveAbilities, keyId: string): number {
  const id = keyId.toLowerCase();
  if (id.includes("wing") || id.includes("wingback")) {
    return (a.speed + a.staminaStat + a.technique) / 3;
  }
  if (id.includes("box_to_box") || id.includes("anchor") || id.includes("ball_winning")) {
    return (a.staminaStat + a.power + a.defense / 2) / 2.5;
  }
  if (
    id.includes("playmaker") || id.includes("trequartista") ||
    id.includes("false_nine")
  ) {
    return (a.passing + a.technique + a.creation / 2) / 2.5;
  }
  if (
    id.includes("poacher") || id.includes("target_forward") ||
    id.includes("striker")
  ) {
    return (a.shooting + a.power + a.attack / 2) / 2.5;
  }
  if (
    id.includes("center_back") || id.includes("sweeper") ||
    id.includes("ball_playing_cb")
  ) {
    return (a.defense + a.power + a.aerial / 2) / 2.5;
  }
  if (id.includes("shot_stopper") || id.includes("keeper")) {
    return a.goalkeeping;
  }
  return (a.midfield + a.physical) / 2;
}

/** Average key-pos quality in ~0..1 (0.5 = average). */
export function keyPositionQuality(
  abilities: EffectiveAbilities[],
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): number {
  const keys: KeyPositionRef[] = team.keyPositions ?? [];
  if (keys.length === 0) return 0.5;

  let sum = 0;
  let n = 0;
  for (const kp of keys) {
    const player = abilities.find(
      (a) => a.onPitch && !a.sentOff && a.fitSlot === kp.slot,
    ) ?? abilities.find((a) => a.onPitch && !a.sentOff && a.pitchSlot === kp.slot);
    if (!player) {
      sum += 0.35;
      n++;
      continue;
    }
    const fitMul = positionFitMultiplier(player.fitSlot >= 1 ? 5 : 5, config);
    // Use assignedFit via staminaStat proxy — fit already baked into axes; use raw role
    const role = roleAxisScore(player, kp.id) / 10;
    const stamina = player.staminaFraction;
    const score = Math.max(0, Math.min(1, role * 0.7 + stamina * 0.2 + 0.1));
    sum += score * (0.85 + fitMul * 0.15);
    n++;
    void fitMul;
  }
  return n === 0 ? 0.5 : sum / n;
}

/**
 * Multiplier for formation strengths based on key positions.
 * Capped by keyPosBonusCap; weakness floored by keyPosWeaknessFloor.
 */
export function keyPosFormationMul(
  abilities: EffectiveAbilities[],
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): number {
  const q = keyPositionQuality(abilities, team, config);
  // q 0.5 → 1.0; above → bonus up to cap; below → down to floor
  if (q >= 0.5) {
    const t = (q - 0.5) / 0.5;
    return 1 + t * config.keyPosBonusCap;
  }
  const t = (0.5 - q) / 0.5;
  return 1 - t * (1 - config.keyPosWeaknessFloor);
}

export function applyKeyPosToZones(
  zones: ZoneStrength,
  abilities: EffectiveAbilities[],
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): void {
  const mul = keyPosFormationMul(abilities, team, config);
  zones.leftAttack *= mul;
  zones.centerAttack *= mul;
  zones.rightAttack *= mul;
  zones.leftMid *= mul;
  zones.centerMid *= mul;
  zones.rightMid *= mul;
  // Defense slightly less sensitive
  const defMul = Math.sqrt(mul);
  zones.leftDefense *= defMul;
  zones.centerDefense *= defMul;
  zones.rightDefense *= defMul;
}
