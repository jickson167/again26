import type { SimulationConfig } from "./config.ts";
import type {
  MatchEvent,
  MatchStatistics,
  PlayerMatchStats,
  Side,
} from "./types.ts";
import { emptyPlayerMatchStats } from "./types.ts";

export type PlayerAcc = PlayerMatchStats;

export function emptyPlayerAcc(
  playerId: string,
  clubId: string,
  side: Side,
  stamina: number,
  extras: {
    userPlayerId?: string;
    name?: string;
    started?: boolean;
    position?: string;
    positionFit?: number;
  } = {},
): PlayerAcc {
  const sheet = emptyPlayerMatchStats({
    playerId,
    userPlayerId: extras.userPlayerId,
    teamId: clubId,
    side,
    name: extras.name,
    started: extras.started ?? true,
    position: extras.position ?? "UNK",
    positionFit: extras.positionFit ?? 7,
  });
  sheet.staminaRemaining = stamina;
  return sheet;
}

/** Build team statistics primarily from player sheets; possession/xG stay team-level. */
export function buildStatisticsFromPlayers(
  players: PlayerMatchStats[],
  homeClubId: string,
  possessionTicks: { home: number; away: number },
  xg: { home: number; away: number },
  homeGoals: number,
  awayGoals: number,
): MatchStatistics {
  const home = players.filter((p) => p.teamId === homeClubId);
  const away = players.filter((p) => p.teamId !== homeClubId);

  const sum = (list: PlayerMatchStats[], key: keyof PlayerMatchStats) =>
    list.reduce((s, p) => s + (Number(p[key]) || 0), 0);

  const homePassA = sum(home, "passesAttempted");
  const awayPassA = sum(away, "passesAttempted");
  const homePassC = sum(home, "passesCompleted");
  const awayPassC = sum(away, "passesCompleted");

  const totalPoss = possessionTicks.home + possessionTicks.away;
  const homePossession = totalPoss === 0
    ? 50
    : Math.round((100 * possessionTicks.home) / totalPoss);

  return {
    homePossession,
    awayPossession: 100 - homePossession,
    homeShots: sum(home, "shots"),
    awayShots: sum(away, "shots"),
    homeShotsOnTarget: sum(home, "shotsOnTarget"),
    awayShotsOnTarget: sum(away, "shotsOnTarget"),
    homeGoals,
    awayGoals,
    homeAssists: sum(home, "assists"),
    awayAssists: sum(away, "assists"),
    homeCorners: sum(home, "cornersTaken"),
    awayCorners: sum(away, "cornersTaken"),
    homeFreeKicks: sum(home, "freeKicksTaken"),
    awayFreeKicks: sum(away, "freeKicksTaken"),
    homeOffsides: sum(home, "offsides"),
    awayOffsides: sum(away, "offsides"),
    homeFouls: sum(home, "foulsCommitted"),
    awayFouls: sum(away, "foulsCommitted"),
    homeYellowCards: sum(home, "yellowCards"),
    awayYellowCards: sum(away, "yellowCards"),
    homeRedCards: sum(home, "redCards"),
    awayRedCards: sum(away, "redCards"),
    homeSaves: sum(home, "saves"),
    awaySaves: sum(away, "saves"),
    homePassesAttempted: homePassA,
    awayPassesAttempted: awayPassA,
    homePassesCompleted: homePassC,
    awayPassesCompleted: awayPassC,
    homePassCompletionRate: homePassA === 0
      ? 0
      : round2((100 * homePassC) / homePassA),
    awayPassCompletionRate: awayPassA === 0
      ? 0
      : round2((100 * awayPassC) / awayPassA),
    homeExpectedGoals: round2(xg.home),
    awayExpectedGoals: round2(xg.away),
  };
}

export function finalizePlayerResults(
  accs: Map<string, PlayerAcc>,
  config: SimulationConfig,
): { results: PlayerMatchStats[]; mvpPlayerId?: string } {
  const results: PlayerMatchStats[] = [];
  let bestId: string | undefined;
  let bestRating = -1;

  for (const acc of accs.values()) {
    if (acc.minutesPlayed <= 0 && !acc.sentOff && !acc.started) continue;
    let rating = config.ratingBase;
    rating += acc.goals * config.ratingGoal;
    rating += acc.assists * config.ratingAssist;
    rating += acc.saves * config.ratingSave;
    rating -= acc.yellowCards * config.ratingCardPenalty;
    rating -= acc.redCards * (config.ratingCardPenalty * 2);
    if (acc.minutesPlayed > 0) {
      rating += Math.min(0.4, acc.shotsOnTarget * 0.08);
    }
    acc.rating = Math.max(4.0, Math.min(10.0, round2(rating)));
    acc.staminaUsed = round2(Math.max(0, 1 - acc.staminaRemaining));
    results.push(acc);

    if (acc.rating > bestRating && acc.minutesPlayed >= 45) {
      bestRating = acc.rating;
      bestId = acc.playerId;
    }
  }

  return { results, mvpPlayerId: bestId };
}

export function countGoalsFromEvents(
  events: MatchEvent[],
  clubId: string,
): number {
  let n = 0;
  for (const e of events) {
    if (e.teamId !== clubId) continue;
    if (e.type === "goal" || e.type === "penalty_scored") n++;
  }
  return n;
}

export function countAssistsFromEvents(
  events: MatchEvent[],
  clubId: string,
): number {
  let n = 0;
  for (const e of events) {
    if (e.teamId !== clubId) continue;
    if (
      (e.type === "goal" || e.type === "penalty_scored") &&
      e.secondaryPlayerId
    ) {
      n++;
    }
  }
  return n;
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
