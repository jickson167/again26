import { mergeConfig, type SimulationConfig } from "../config.ts";
import { simulateMatch } from "../match_simulator.ts";
import { makeInput } from "./fixtures.ts";

export interface BalanceReport {
  avgHomeGoals: number;
  avgAwayGoals: number;
  scorelessRate: number;
  drawRate: number;
  fourPlusRate: number;
  homeWinRate: number;
  awayWinRate: number;
  strongVsWeakWinRate: number;
  equalHomeShare: number;
  avgShots: number;
  avgShotsOnTarget: number;
  avgYellowCards: number;
  avgRedCards: number;
}

export interface BalanceTargets {
  avgHomeGoals: [number, number];
  avgAwayGoals: [number, number];
  drawRate: [number, number];
  homeWinRate: [number, number];
  awayWinRate: [number, number];
  strongVsWeakWinRate: [number, number];
  equalHomeShare: [number, number];
  scorelessRate: [number, number];
  fourPlusRate: [number, number];
}

export const DEFAULT_TARGETS: BalanceTargets = {
  avgHomeGoals: [1.2, 1.5],
  avgAwayGoals: [0.9, 1.3],
  drawRate: [0.22, 0.3],
  homeWinRate: [0.4, 0.5],
  awayWinRate: [0.25, 0.35],
  strongVsWeakWinRate: [0.7, 0.85],
  equalHomeShare: [0.48, 0.52],
  scorelessRate: [0.08, 0.15],
  fourPlusRate: [0.08, 0.15],
};

export function runMonteCarlo(
  n: number,
  config: SimulationConfig = mergeConfig(),
  seedBase = 10_000,
): BalanceReport {
  let homeGoals = 0;
  let awayGoals = 0;
  let draws = 0;
  let homeWins = 0;
  let awayWins = 0;
  let scoreless = 0;
  let fourPlus = 0;
  let shots = 0;
  let sot = 0;
  let cards = 0;
  let reds = 0;
  let strongBeatsWeak = 0;
  let equalHomeWins = 0;
  let equalAwayWins = 0;

  for (let i = 0; i < n; i++) {
    const r = simulateMatch(makeInput(seedBase + i, 6, 6), config);
    homeGoals += r.homeScore;
    awayGoals += r.awayScore;
    const total = r.homeScore + r.awayScore;
    if (total === 0) scoreless++;
    if (total >= 4) fourPlus++;
    if (r.homeScore === r.awayScore) draws++;
    else if (r.homeScore > r.awayScore) homeWins++;
    else awayWins++;
    shots += r.statistics.homeShots + r.statistics.awayShots;
    sot += r.statistics.homeShotsOnTarget + r.statistics.awayShotsOnTarget;
    cards += r.statistics.homeYellowCards + r.statistics.awayYellowCards;
    reds += r.statistics.homeRedCards + r.statistics.awayRedCards;

    const sw = simulateMatch(
      makeInput(seedBase + 100_000 + i, 9, 3, { homeAdvantage: false }),
      config,
    );
    if (sw.homeScore > sw.awayScore) strongBeatsWeak++;

    const eq = simulateMatch(
      makeInput(seedBase + 200_000 + i, 6, 6, { homeAdvantage: false }),
      config,
    );
    if (eq.homeScore > eq.awayScore) equalHomeWins++;
    else if (eq.awayScore > eq.homeScore) equalAwayWins++;
  }

  const equalDecided = equalHomeWins + equalAwayWins;
  return {
    avgHomeGoals: homeGoals / n,
    avgAwayGoals: awayGoals / n,
    scorelessRate: scoreless / n,
    drawRate: draws / n,
    fourPlusRate: fourPlus / n,
    homeWinRate: homeWins / n,
    awayWinRate: awayWins / n,
    strongVsWeakWinRate: strongBeatsWeak / n,
    equalHomeShare: equalDecided === 0
      ? 0.5
      : equalHomeWins / equalDecided,
    avgShots: shots / n,
    avgShotsOnTarget: sot / n,
    avgYellowCards: cards / n,
    avgRedCards: reds / n,
  };
}

export function scoreAgainstTargets(
  report: BalanceReport,
  targets: BalanceTargets = DEFAULT_TARGETS,
): { score: number; misses: string[] } {
  const misses: string[] = [];
  let ok = 0;
  const checks: Array<[keyof BalanceReport, [number, number]]> = [
    ["avgHomeGoals", targets.avgHomeGoals],
    ["avgAwayGoals", targets.avgAwayGoals],
    ["drawRate", targets.drawRate],
    ["homeWinRate", targets.homeWinRate],
    ["awayWinRate", targets.awayWinRate],
    ["strongVsWeakWinRate", targets.strongVsWeakWinRate],
    ["equalHomeShare", targets.equalHomeShare],
    ["scorelessRate", targets.scorelessRate],
    ["fourPlusRate", targets.fourPlusRate],
  ];
  for (const [key, [lo, hi]] of checks) {
    const v = report[key];
    if (v >= lo && v <= hi) ok++;
    else misses.push(`${key}=${v.toFixed(4)} (want ${lo}-${hi})`);
  }
  return { score: (ok / checks.length) * 100, misses };
}

/** Distance penalty for auto-balance (0 = perfect). */
export function targetLoss(
  report: BalanceReport,
  targets: BalanceTargets = DEFAULT_TARGETS,
): number {
  const keys: Array<keyof BalanceReport> = [
    "avgHomeGoals",
    "avgAwayGoals",
    "drawRate",
    "homeWinRate",
    "awayWinRate",
    "strongVsWeakWinRate",
    "equalHomeShare",
    "scorelessRate",
    "fourPlusRate",
  ];
  let loss = 0;
  for (const key of keys) {
    const [lo, hi] = targets[key as keyof BalanceTargets];
    const v = report[key];
    const mid = (lo + hi) / 2;
    const half = (hi - lo) / 2;
    if (v < lo) loss += ((lo - v) / Math.max(0.01, mid)) ** 2;
    else if (v > hi) loss += ((v - hi) / Math.max(0.01, mid)) ** 2;
    else loss += 0.05 * ((v - mid) / Math.max(0.01, half)) ** 2;
  }
  return loss;
}
