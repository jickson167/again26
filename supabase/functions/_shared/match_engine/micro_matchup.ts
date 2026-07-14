import type { SimulationConfig } from "./config.ts";
import { softContestShare } from "./team_strength.ts";
import type { Lane, ZoneStrength } from "./types.ts";

/**
 * Micro matchup bonus in [-cap, +cap] applied to attacker chance.
 * Zone-vs-zone contests — not a fixed rock-paper-scissors table.
 */
export function microMatchupBonus(
  attZones: ZoneStrength,
  defZones: ZoneStrength,
  lane: Lane,
  config: SimulationConfig,
): number {
  const cap = config.formationMatchupCap;

  const laneAtt = lane === "left"
    ? attZones.leftAttack
    : lane === "right"
    ? attZones.rightAttack
    : attZones.centerAttack;
  // Opposite flank defense
  const laneDef = lane === "left"
    ? defZones.rightDefense
    : lane === "right"
    ? defZones.leftDefense
    : defZones.centerDefense;

  const flank = softContestShare(laneAtt, laneDef, config) - 0.5;
  const mid = softContestShare(attZones.centerMid, defZones.centerMid, config) -
    0.5;
  const width = softContestShare(
    (attZones.leftAttack + attZones.rightAttack) / 2,
    (defZones.leftDefense + defZones.rightDefense) / 2,
    config,
  ) - 0.5;
  const buildup = softContestShare(
    (attZones.leftMid + attZones.centerMid + attZones.rightMid) / 3,
    (defZones.leftMid + defZones.centerMid + defZones.rightMid) / 3 *
      0.9 +
      (defZones.leftDefense + defZones.centerDefense + defZones.rightDefense) /
        3 * 0.1,
    config,
  ) - 0.5;
  const aerial = softContestShare(
    attZones.centerAttack,
    defZones.centerDefense * 0.7 + defZones.goalkeeping * 0.3,
    config,
  ) - 0.5;

  const raw = flank * 0.28 + mid * 0.22 + width * 0.2 + buildup * 0.18 +
    aerial * 0.12;
  // Scale soft contest delta (~±0.28) into ±cap
  return Math.max(-cap, Math.min(cap, raw * 2 * cap / 0.28));
}

/** Prefer lanes where micro matchup is favorable. */
export function matchupLaneWeights(
  attZones: ZoneStrength,
  defZones: ZoneStrength,
  config: SimulationConfig,
): Record<Lane, number> {
  const lanes: Lane[] = ["left", "center", "right"];
  const out: Record<Lane, number> = { left: 1, center: 1, right: 1 };
  for (const lane of lanes) {
    const b = microMatchupBonus(attZones, defZones, lane, config);
    out[lane] = Math.max(0.15, 1 + b * 3);
  }
  return out;
}
