import type { SimulationConfig } from "./config.ts";
import type { SeededRandom } from "./seeded_random.ts";
import { makeEvent } from "./event_generator.ts";
import type {
  EffectiveAbilities,
  InjurySeverity,
  MatchEvent,
  PlayerMatchStats,
  Side,
  TeamSimulationSnapshot,
} from "./types.ts";

export type ContactKind = "tackle" | "duel" | "aerial" | "sprint";

export function rollInjury(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  victim: EffectiveAbilities,
  aggressor: EffectiveAbilities | undefined,
  kind: ContactKind,
  wasFoul: boolean,
): InjurySeverity | undefined {
  if (!victim.onPitch || victim.sentOff || victim.injuredOut) return undefined;

  let p = config.injuryBaseChance;
  if (kind === "tackle") p *= 1.4;
  if (kind === "aerial") p *= 1.2;
  if (kind === "sprint") p *= 0.7;
  if (wasFoul) p *= 1.5;

  const fatigue = victim.fatigue;
  p += fatigue * config.injuryFatigueFactor;

  if (minute >= 70) p *= config.injuryLateFactor;

  if (aggressor) {
    p += (aggressor.power / 10) * config.injuryPowerFactor;
  }
  // Victim power resists
  p *= 1 - (victim.power / 10) * config.injuryVictimPowerRelief;
  // Low stamina amplifies
  if (victim.staminaFraction < 0.4) p *= 1.4;

  p = Math.min(0.04, Math.max(0, p));
  if (!rng.bool(p)) return undefined;

  const r = rng.next();
  if (r < config.injurySevereShare) return "severe";
  if (r < config.injurySevereShare + config.injuryModerateShare) {
    return "moderate";
  }
  return "mild";
}

export function applyInjury(
  severity: InjurySeverity,
  victim: EffectiveAbilities,
  team: TeamSimulationSnapshot,
  side: Side,
  minute: number,
  events: MatchEvent[],
  playerAcc: Map<string, PlayerMatchStats>,
  homeScore: number,
  awayScore: number,
): void {
  const acc = playerAcc.get(victim.playerId);
  if (acc) {
    acc.injuries++;
    acc.injuryOccurred = true;
  }

  events.push(
    makeEvent({
      minute,
      second: 0,
      type: "injury",
      teamId: team.clubId,
      side,
      primaryPlayerId: victim.playerId,
      commentaryKey: "injury",
      metadata: { severity },
      success: false,
      currentHomeScore: homeScore,
      currentAwayScore: awayScore,
    }),
  );

  if (severity === "mild") {
    // Performance hit only
    victim.attack *= 0.92;
    victim.defense *= 0.92;
    victim.speed *= 0.9;
    return;
  }

  // Moderate / severe: leave pitch
  victim.injuredOut = true;
  victim.onPitch = false;
  if (acc) {
    acc.substitutedOut = true;
    acc.substitutionReason = "injury";
    acc.fatigueAtSubstitution = Math.round(victim.fatigue * 100) / 100;
  }
}
