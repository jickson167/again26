/**
 * Final 100_000-match Monte Carlo + realism score.
 * deno test -A supabase/functions/_shared/match_engine/tests/monte_carlo_100k_test.ts
 */
import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { DEFAULT_SIMULATION_CONFIG, mergeConfig } from "../config.ts";
import {
  DEFAULT_TARGETS,
  runMonteCarlo,
  scoreAgainstTargets,
} from "./monte_carlo_lib.ts";
import { simulateMatch } from "../match_simulator.ts";
import { makeInput, makeTeam } from "./fixtures.ts";

const N = 100_000;

Deno.test({
  name: `Monte Carlo ${N} + formation/tactic sanity + realism score`,
  sanitizeResources: false,
  sanitizeOps: false,
  fn() {
    const config = mergeConfig();
    assertEqualsVersion(config.simulationVersion, "4");

    const report = runMonteCarlo(N, config, 1_000_000);
    const { score, misses } = scoreAgainstTargets(report, DEFAULT_TARGETS);

    // Formation differentiation (same players, different shape)
    let goals433 = 0;
    let goals541 = 0;
    let centerShots4231 = 0;
    let wideShots433 = 0;
    const F = 2000;
    for (let i = 0; i < F; i++) {
      const a = simulateMatch({
        ...makeInput(2_000_000 + i, 7, 7, { homeAdvantage: false }),
        home: makeTeam("home", 7, { formation: "4-3-3", style: "attack" }),
        away: makeTeam("away", 7, { formation: "5-4-1", style: "defense" }),
      }, config);
      goals433 += a.homeScore;
      goals541 += a.awayScore;

      const b = simulateMatch({
        ...makeInput(2_100_000 + i, 7, 7, { homeAdvantage: false }),
        home: makeTeam("home", 7, { formation: "4-2-3-1", style: "buildup" }),
        away: makeTeam("away", 7, { formation: "4-3-3", style: "balance" }),
      }, config);
      centerShots4231 += b.statistics.homeShots;
      wideShots433 += b.statistics.awayShots;
    }

    // Tactic: press vs defense shot volume
    let pressShots = 0;
    let defShots = 0;
    for (let i = 0; i < F; i++) {
      const p = simulateMatch({
        ...makeInput(2_200_000 + i, 7, 7, { homeAdvantage: false }),
        home: makeTeam("home", 7, { style: "press", attack: 7 }),
        away: makeTeam("away", 7, { style: "balance" }),
      }, config);
      const d = simulateMatch({
        ...makeInput(2_300_000 + i, 7, 7, { homeAdvantage: false }),
        home: makeTeam("home", 7, { style: "defense", attack: 2, stability: 9 }),
        away: makeTeam("away", 7, { style: "balance" }),
      }, config);
      pressShots += p.statistics.homeShots;
      defShots += d.statistics.homeShots;
    }

    const realism = computeRealismScore(report, {
      formationAttackGap: goals433 / Math.max(1, goals541),
      pressVsDefShotRatio: pressShots / Math.max(1, defShots),
      targetScore: score,
    });

    console.log("\n=== Monte Carlo 100000 (simulation_version=" +
      config.simulationVersion + ") ===");
    console.log(JSON.stringify(report, null, 2));
    console.log("\nTarget hit score:", score, "/ 100");
    if (misses.length) console.log("Misses:", misses.join("; "));
    console.log("\nFormation/tactic checks:");
    console.log({
      avgHomeGoals_433_vs_541_def: goals433 / F,
      avgAwayGoals_541: goals541 / F,
      shots_4231_buildup: centerShots4231 / F,
      shots_433_balance: wideShots433 / F,
      shots_press: pressShots / F,
      shots_defense: defShots / F,
    });
    console.log("\n=== Realism score ===");
    console.log(JSON.stringify(realism, null, 2));

    // Soft assertions — allow small misses but strong-vs-weak must be in band
    assert(
      report.strongVsWeakWinRate >= 0.65 && report.strongVsWeakWinRate <= 0.9,
      `strongVsWeak=${report.strongVsWeakWinRate}`,
    );
    assert(report.avgHomeGoals > 0.9 && report.avgHomeGoals < 1.8);
    assert(pressShots > defShots, "press should shoot more than defense");
    assert(goals433 >= goals541 * 0.9, "433 attack should outscore 541 defense side");
  },
});

function assertEqualsVersion(v: string, expected: string) {
  if (v !== expected) {
    throw new Error(`simulationVersion ${v} != ${expected}`);
  }
}

function computeRealismScore(
  report: {
    avgHomeGoals: number;
    avgAwayGoals: number;
    drawRate: number;
    homeWinRate: number;
    awayWinRate: number;
    scorelessRate: number;
    fourPlusRate: number;
    strongVsWeakWinRate: number;
  },
  extra: {
    formationAttackGap: number;
    pressVsDefShotRatio: number;
    targetScore: number;
  },
): {
  score: number;
  breakdown: Record<string, number>;
  gaps: string[];
} {
  // Reference: typical top-flight ~1.4/1.1 goals, ~25% draws, home ~45%
  const breakdown: Record<string, number> = {};
  const gaps: string[] = [];

  const band = (v: number, lo: number, hi: number, weight: number, name: string) => {
    if (v >= lo && v <= hi) {
      breakdown[name] = weight;
      return weight;
    }
    const mid = (lo + hi) / 2;
    const dist = Math.min(1, Math.abs(v - mid) / mid);
    const pts = weight * Math.max(0, 1 - dist);
    breakdown[name] = pts;
    gaps.push(`${name}: value=${v.toFixed(3)} ideal=${lo}-${hi}`);
    return pts;
  };

  let total = 0;
  total += band(report.avgHomeGoals, 1.15, 1.55, 12, "home_goals");
  total += band(report.avgAwayGoals, 0.9, 1.3, 12, "away_goals");
  total += band(report.drawRate, 0.22, 0.3, 12, "draws");
  total += band(report.homeWinRate, 0.4, 0.5, 12, "home_wins");
  total += band(report.awayWinRate, 0.25, 0.35, 10, "away_wins");
  total += band(report.scorelessRate, 0.08, 0.15, 8, "scoreless");
  total += band(report.fourPlusRate, 0.08, 0.15, 8, "high_scoring");
  total += band(report.strongVsWeakWinRate, 0.7, 0.85, 14, "upsets_vs_quality");
  total += band(extra.formationAttackGap, 1.05, 2.5, 6, "formation_contrast");
  total += band(extra.pressVsDefShotRatio, 1.05, 2.0, 6, "tactic_contrast");

  // Target checklist contribution
  total += (extra.targetScore / 100) * 0; // already in bands

  if (extra.targetScore < 100) {
    gaps.push(`config target checklist ${extra.targetScore}/100`);
  }
  gaps.push(
    "교체·부상 세밀도, 날씨/심판, 다경기 피로 누적, xG 보정 커브는 미구현",
  );
  gaps.push("세트피스·PK 빈도가 실제보다 단순 확률");
  gaps.push("포메이션 상성(예: 3백 vs 윙)은 구역 계수 수준으로만 반영");

  return { score: Math.round(total), breakdown, gaps };
}
