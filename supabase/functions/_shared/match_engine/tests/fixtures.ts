import type {
  Lane,
  PitchLine,
  PlayerSimulationSnapshot,
  PositionAssignment,
  TeamSimulationSnapshot,
  MatchSimulationInput,
} from "../types.ts";

type Slot = { fitSlot: number; lane: Lane; line: PitchLine };

const FORMATIONS: Record<string, Slot[]> = {
  "4-4-2": [
    { fitSlot: 13, lane: "center", line: "gk" },
    { fitSlot: 7, lane: "left", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 9, lane: "right", line: "defense" },
    { fitSlot: 4, lane: "left", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 6, lane: "right", line: "midfield" },
    { fitSlot: 2, lane: "center", line: "attack" },
    { fitSlot: 2, lane: "center", line: "attack" },
  ],
  "4-3-3": [
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
  ],
  "4-2-3-1": [
    { fitSlot: 13, lane: "center", line: "gk" },
    { fitSlot: 7, lane: "left", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 9, lane: "right", line: "defense" },
    { fitSlot: 8, lane: "center", line: "midfield" },
    { fitSlot: 8, lane: "center", line: "midfield" },
    { fitSlot: 4, lane: "left", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 6, lane: "right", line: "midfield" },
    { fitSlot: 2, lane: "center", line: "attack" },
  ],
  "3-5-2": [
    { fitSlot: 13, lane: "center", line: "gk" },
    { fitSlot: 11, lane: "left", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 11, lane: "right", line: "defense" },
    { fitSlot: 10, lane: "left", line: "midfield" },
    { fitSlot: 8, lane: "center", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 12, lane: "right", line: "midfield" },
    { fitSlot: 2, lane: "center", line: "attack" },
    { fitSlot: 2, lane: "center", line: "attack" },
  ],
  "5-4-1": [
    { fitSlot: 13, lane: "center", line: "gk" },
    { fitSlot: 10, lane: "left", line: "defense" },
    { fitSlot: 11, lane: "left", line: "defense" },
    { fitSlot: 11, lane: "center", line: "defense" },
    { fitSlot: 11, lane: "right", line: "defense" },
    { fitSlot: 12, lane: "right", line: "defense" },
    { fitSlot: 4, lane: "left", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 5, lane: "center", line: "midfield" },
    { fitSlot: 6, lane: "right", line: "midfield" },
    { fitSlot: 2, lane: "center", line: "attack" },
  ],
};

export function makePlayer(
  id: string,
  level: number,
  fit = 7,
  extras: Partial<PlayerSimulationSnapshot> = {},
): PlayerSimulationSnapshot {
  const v = Math.max(0, Math.min(10, level));
  return {
    playerId: id,
    name: id,
    speed: v,
    power: v,
    technique: v,
    shooting: v,
    passing: v,
    stamina: v,
    pkAbility: v,
    fkAbility: v,
    ckAbility: v,
    leadership: v,
    assignedFit: fit,
    staminaFraction: 1,
    ...extras,
  };
}

export function makeTeam(
  clubId: string,
  level: number,
  opts: {
    fit?: number;
    style?: string;
    formation?: string;
    formationType?: string;
    attack?: number;
    possession?: number;
    stability?: number;
    staminaFraction?: number;
    keyPositions?: { id: string; slot: number }[];
    playerExtras?: (i: number) => Partial<PlayerSimulationSnapshot>;
  } = {},
): TeamSimulationSnapshot {
  const fit = opts.fit ?? 7;
  const formationName = opts.formation ?? "4-3-3";
  const layout = FORMATIONS[formationName] ?? FORMATIONS["4-3-3"]!;
  const starters = Array.from({ length: 11 }, (_, i) =>
    makePlayer(`${clubId}_p${i + 1}`, level, fit, {
      staminaFraction: opts.staminaFraction ?? 1,
      ...(opts.playerExtras?.(i) ?? {}),
    })
  );
  const bench = Array.from({ length: 5 }, (_, i) =>
    makePlayer(`${clubId}_b${i + 1}`, level, fit, {
      staminaFraction: 1,
    })
  );
  const assignments: PositionAssignment[] = layout.map((a, i) => ({
    pitchSlot: i + 1,
    ...a,
  }));
  return {
    clubId,
    clubName: clubId,
    formationName,
    formationType: opts.formationType ?? "T",
    tactic: {
      possession: opts.possession ?? 5,
      attack: opts.attack ?? 5,
      stability: opts.stability ?? 5,
      lineHeight: 5,
      coachStyle: opts.style ?? "balance",
    },
    starters,
    bench,
    assignments,
    keyPositions: opts.keyPositions,
    pkPlayerId: starters[starters.length - 1]!.playerId,
    fkPlayerId: starters[6]!.playerId,
    ckPlayerId: starters[7]!.playerId,
    captainPlayerId: starters[5]!.playerId,
  };
}

export function makeInput(
  seed: number,
  homeLevel: number,
  awayLevel: number,
  extras: Partial<MatchSimulationInput> = {},
): MatchSimulationInput {
  return {
    matchId: `match_${seed}`,
    seed,
    simulationVersion: "4",
    home: makeTeam("home", homeLevel),
    away: makeTeam("away", awayLevel),
    homeAdvantage: true,
    ...extras,
  };
}
