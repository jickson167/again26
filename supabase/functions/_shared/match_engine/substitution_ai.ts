import type { SimulationConfig } from "./config.ts";
import { makeEvent } from "./event_generator.ts";
import { buildEffectiveAbilities } from "./player_rating.ts";
import type { SeededRandom } from "./seeded_random.ts";
import type {
  EffectiveAbilities,
  MatchEvent,
  PlayerMatchStats,
  Side,
  SubstitutionReason,
  TeamSimulationSnapshot,
} from "./types.ts";

export interface SubDecision {
  outId: string;
  inId: string;
  reason: SubstitutionReason;
}

function onPitchOutfield(abilities: EffectiveAbilities[]): EffectiveAbilities[] {
  return abilities.filter(
    (a) => a.onPitch && !a.sentOff && !a.injuredOut && a.line !== "gk",
  );
}

function scoreDiff(side: Side, home: number, away: number): number {
  return side === "home" ? home - away : away - home;
}

function estimateLiveRating(acc: PlayerMatchStats | undefined): number {
  if (!acc) return 6.2;
  let r = 6.2;
  r += acc.goals * 0.9;
  r += acc.assists * 0.55;
  r -= acc.yellowCards * 0.35;
  r -= acc.redCards * 0.7;
  return r;
}

export function maybeDecideSubstitution(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  side: Side,
  team: TeamSimulationSnapshot,
  abilities: EffectiveAbilities[],
  playerAcc: Map<string, PlayerMatchStats>,
  homeScore: number,
  awayScore: number,
  subsUsed: number,
): SubDecision | undefined {
  if (subsUsed >= config.maxSubstitutions) return undefined;

  const bench = abilities.filter(
    (a) => !a.onPitch && !a.sentOff && !a.injuredOut,
  );
  // Also allow team.bench players not yet in abilities array
  const benchIds = new Set(bench.map((b) => b.playerId));
  for (const p of team.bench) {
    if (!benchIds.has(p.playerId) && !playerAcc.get(p.playerId)?.substitutedOut) {
      // will be materialized on apply
      benchIds.add(p.playerId);
    }
  }
  if (benchIds.size === 0) return undefined;

  const outfield = onPitchOutfield(abilities);
  if (outfield.length === 0) return undefined;

  const diff = scoreDiff(side, homeScore, awayScore);

  const injured = outfield.find((a) => playerAcc.get(a.playerId)?.injuryOccurred);
  if (injured && playerAcc.get(injured.playerId)?.substitutionReason !== "injury") {
    // already handled by injury apply leaving pitch — skip
  }

  // Force sub if someone is injuredOut but still counted (safety)
  const needCover = abilities.find((a) => a.injuredOut && a.onPitch);
  void needCover;

  const earlyFatigue = outfield.find(
    (a) => a.staminaFraction < config.subEarlyFatigueThreshold,
  );
  if (earlyFatigue && minute >= 40 && rng.bool(0.4)) {
    const inn = pickBenchPlayerId(rng, team, abilities, earlyFatigue, diff, "fatigue");
    if (inn) {
      return { outId: earlyFatigue.playerId, inId: inn, reason: "fatigue" };
    }
  }

  const yellowRisk = outfield.find((a) => {
    const acc = playerAcc.get(a.playerId);
    return (acc?.yellowCards ?? 0) >= 1 &&
      (a.line === "defense" || a.fitSlot === 8) &&
      minute >= 50;
  });
  if (yellowRisk && rng.bool(0.22)) {
    const inn = pickBenchPlayerId(
      rng,
      team,
      abilities,
      yellowRisk,
      diff,
      "yellow_card_risk",
    );
    if (inn) {
      return {
        outId: yellowRisk.playerId,
        inId: inn,
        reason: "yellow_card_risk",
      };
    }
  }

  const inWindow = minute >= config.subWindowStart &&
    minute <= config.subWindowEnd;
  const late = minute > config.subWindowEnd && minute < 88;
  if (!inWindow && !late) return undefined;

  let chance = config.subBaseChancePerTick;
  if (late) chance *= 0.55;
  if (Math.abs(diff) >= 2) chance *= 1.12;
  if (!rng.bool(chance)) return undefined;

  const candidates = outfield.map((a) => {
    const acc = playerAcc.get(a.playerId);
    const rating = estimateLiveRating(acc);
    let priority = (1 - a.staminaFraction) * 2;
    if (rating < config.subPoorRatingThreshold) priority += 0.8;
    if ((acc?.yellowCards ?? 0) >= 1 && a.line === "defense") priority += 0.6;
    if (diff < 0 && a.line === "defense") priority += 0.35;
    if (diff > 0 && a.line === "attack") priority += 0.3;
    return { a, priority, rating };
  });
  candidates.sort((x, y) => y.priority - x.priority);
  const out = candidates[0]?.a;
  if (!out) return undefined;

  let reason: SubstitutionReason = "fatigue";
  if (out.staminaFraction < config.subFatigueThreshold) reason = "fatigue";
  else if (
    estimateLiveRating(playerAcc.get(out.playerId)) < config.subPoorRatingThreshold
  ) {
    reason = "poor_performance";
  } else if (diff < 0) reason = "tactical_attack";
  else if (diff > 0) reason = "tactical_defense";
  else {
    const ft = (team.formationType ?? "T").toUpperCase();
    reason = ft === "S" || (ft === "P" && diff <= 0)
      ? "tactical_attack"
      : "tactical_defense";
  }

  const inn = pickBenchPlayerId(rng, team, abilities, out, diff, reason);
  if (!inn) return undefined;
  return { outId: out.playerId, inId: inn, reason };
}

function pickBenchPlayerId(
  rng: SeededRandom,
  team: TeamSimulationSnapshot,
  abilities: EffectiveAbilities[],
  out: EffectiveAbilities,
  scoreDiffVal: number,
  reason: SubstitutionReason,
): string | undefined {
  const used = new Set(
    abilities.filter((a) => a.onPitch || a.sentOff).map((a) => a.playerId),
  );
  // Anyone already substituted out
  for (const a of abilities) {
    if (!a.onPitch && a.playerId !== out.playerId) {
      // still eligible if never came on — bench entries in abilities
    }
  }

  type Cand = { id: string; ab?: EffectiveAbilities; score: number };
  const cands: Cand[] = [];

  for (const ab of abilities) {
    if (ab.onPitch || ab.sentOff || ab.injuredOut) continue;
    if (used.has(ab.playerId) && ab.onPitch) continue;
    let s = scoreBench(ab, out, scoreDiffVal, reason);
    s += rng.next() * 0.4;
    cands.push({ id: ab.playerId, ab, score: s });
  }
  for (const p of team.bench) {
    if (cands.some((c) => c.id === p.playerId)) continue;
    if (abilities.some((a) => a.playerId === p.playerId && a.onPitch)) continue;
    // Approximate score from raw stats
    let s = 1;
    if (reason === "tactical_attack" || scoreDiffVal < 0) {
      s += p.shooting + p.speed * 0.5;
    } else if (reason === "tactical_defense" || scoreDiffVal > 0) {
      s += p.power + p.stamina * 0.4;
    } else {
      s += p.stamina + p.passing * 0.3;
    }
    s += rng.next() * 0.4;
    cands.push({ id: p.playerId, score: s });
  }

  if (cands.length === 0) return undefined;
  cands.sort((a, b) => b.score - a.score);
  return cands[0]?.id;
}

function scoreBench(
  b: EffectiveAbilities,
  out: EffectiveAbilities,
  scoreDiffVal: number,
  reason: SubstitutionReason,
): number {
  let s = 1;
  if (b.line === out.line) s += 1.2;
  if (Math.abs(b.fitSlot - out.fitSlot) <= 2) s += 0.5;
  if (reason === "tactical_attack" || scoreDiffVal < 0) {
    s += b.attack + b.shooting * 0.5 + b.speed * 0.3;
  } else if (reason === "tactical_defense" || scoreDiffVal > 0) {
    s += b.defense + b.staminaStat * 0.4 + b.power * 0.2;
  } else if (reason === "fatigue") {
    s += b.staminaStat + b.midfield * 0.3;
  } else if (reason === "yellow_card_risk") {
    s += b.defense + b.staminaStat * 0.2;
  } else {
    s += b.attack + b.midfield;
  }
  return s;
}

export function applySubstitutionSafe(
  decision: SubDecision,
  abilities: EffectiveAbilities[],
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
  playerAcc: Map<string, PlayerMatchStats>,
  side: Side,
  minute: number,
  events: MatchEvent[],
  homeScore: number,
  awayScore: number,
  emptyPlayerAcc: (
    playerId: string,
    clubId: string,
    side: Side,
    stamina: number,
    extras?: {
      userPlayerId?: string;
      name?: string;
      started?: boolean;
      position?: string;
      positionFit?: number;
    },
  ) => PlayerMatchStats,
): void {
  const outAb = abilities.find((a) => a.playerId === decision.outId);
  if (!outAb || !outAb.onPitch) return;

  let inAb = abilities.find((a) => a.playerId === decision.inId);
  if (!inAb) {
    const benchPlayer = team.bench.find((p) => p.playerId === decision.inId);
    if (!benchPlayer) return;
    const built = buildEffectiveAbilities(
      {
        ...team,
        starters: [benchPlayer],
        assignments: [{
          pitchSlot: outAb.pitchSlot,
          fitSlot: outAb.fitSlot,
          lane: outAb.lane,
          line: outAb.line,
        }],
      },
      config,
    );
    inAb = built[0];
    if (!inAb) return;
    abilities.push(inAb);
  }

  outAb.onPitch = false;
  inAb.onPitch = true;
  inAb.injuredOut = false;
  inAb.sentOff = false;
  inAb.staminaFraction = 1;
  inAb.fatigue = 0;
  inAb.fitSlot = outAb.fitSlot;
  inAb.lane = outAb.lane;
  inAb.line = outAb.line;
  inAb.pitchSlot = outAb.pitchSlot;

  const outAcc = playerAcc.get(decision.outId);
  if (outAcc) {
    outAcc.substitutedOut = true;
    outAcc.fatigueAtSubstitution =
      Math.round((1 - outAb.staminaFraction) * 100) / 100;
    outAcc.substitutionReason = decision.reason;
  }

  let inAcc = playerAcc.get(decision.inId);
  if (!inAcc) {
    const benchP = team.bench.find((p) => p.playerId === decision.inId);
    inAcc = emptyPlayerAcc(decision.inId, team.clubId, side, 1, {
      name: benchP?.name,
      started: false,
      position: outAcc?.position ?? "SUB",
      positionFit: benchP?.assignedFit ?? 5,
      userPlayerId: benchP?.userPlayerId,
    });
    playerAcc.set(decision.inId, inAcc);
  }
  inAcc.substitutedIn = true;

  events.push(
    makeEvent({
      minute,
      second: 0,
      type: "substitution",
      teamId: team.clubId,
      side,
      primaryPlayerId: decision.inId,
      substitutedOutPlayerId: decision.outId,
      substitutedInPlayerId: decision.inId,
      commentaryKey: "substitution",
      metadata: { reason: decision.reason },
      currentHomeScore: homeScore,
      currentAwayScore: awayScore,
    }),
  );
}
