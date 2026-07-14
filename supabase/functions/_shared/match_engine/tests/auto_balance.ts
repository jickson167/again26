/**
 * Auto-tune SimulationConfig toward balance targets (config knobs only).
 *
 * deno run -A supabase/functions/_shared/match_engine/tests/auto_balance.ts
 *
 * Writes suggested overrides to stdout; apply manually into config.ts defaults
 * (this script prints a JSON patch — we also persist best values into
 * calibrated_config_snapshot.json for the session).
 */
import { DEFAULT_SIMULATION_CONFIG, mergeConfig } from "../config.ts";
import {
  DEFAULT_TARGETS,
  runMonteCarlo,
  scoreAgainstTargets,
  targetLoss,
  type BalanceReport,
} from "./monte_carlo_lib.ts";

const SAMPLE = 5000;
const MAX_ITERS = 28;

type Knobs = {
  abilityCompressionExponent: number;
  underdogFloor: number;
  contestSoftness: number;
  finishNoiseAmplitude: number;
  baseChancePerTick: number;
  baseFinishRate: number;
  shotOnTargetRate: number;
  homeAdvantageAttack: number;
  homeAdvantageMid: number;
  gkSaveFactor: number;
  maxBreakChance: number;
  maxTickChance: number;
  trailingAttackBoost: number;
  leadingTempoDrop: number;
};

function knobsFrom(c: typeof DEFAULT_SIMULATION_CONFIG): Knobs {
  return {
    abilityCompressionExponent: c.abilityCompressionExponent,
    underdogFloor: c.underdogFloor,
    contestSoftness: c.contestSoftness,
    finishNoiseAmplitude: c.finishNoiseAmplitude,
    baseChancePerTick: c.baseChancePerTick,
    baseFinishRate: c.baseFinishRate,
    shotOnTargetRate: c.shotOnTargetRate,
    homeAdvantageAttack: c.homeAdvantageAttack,
    homeAdvantageMid: c.homeAdvantageMid,
    gkSaveFactor: c.gkSaveFactor,
    maxBreakChance: c.maxBreakChance,
    maxTickChance: c.maxTickChance,
    trailingAttackBoost: c.trailingAttackBoost,
    leadingTempoDrop: c.leadingTempoDrop,
  };
}

function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}

function adjust(k: Knobs, report: BalanceReport): Knobs {
  const next = { ...k };
  const t = DEFAULT_TARGETS;

  // Strong vs weak
  if (report.strongVsWeakWinRate > t.strongVsWeakWinRate[1]) {
    next.abilityCompressionExponent = clamp(
      next.abilityCompressionExponent - 0.04,
      0.45,
      0.9,
    );
    next.underdogFloor = clamp(next.underdogFloor + 0.02, 0.12, 0.38);
    next.finishNoiseAmplitude = clamp(
      next.finishNoiseAmplitude + 0.02,
      0.1,
      0.4,
    );
    next.contestSoftness = clamp(next.contestSoftness - 0.03, 0.5, 0.95);
  } else if (report.strongVsWeakWinRate < t.strongVsWeakWinRate[0]) {
    next.abilityCompressionExponent = clamp(
      next.abilityCompressionExponent + 0.03,
      0.45,
      0.9,
    );
    next.underdogFloor = clamp(next.underdogFloor - 0.015, 0.12, 0.38);
  }

  // Goals
  const homeMid = (t.avgHomeGoals[0] + t.avgHomeGoals[1]) / 2;
  if (report.avgHomeGoals < t.avgHomeGoals[0]) {
    next.baseChancePerTick = clamp(next.baseChancePerTick + 0.012, 0.12, 0.32);
    next.baseFinishRate = clamp(next.baseFinishRate + 0.015, 0.2, 0.45);
  } else if (report.avgHomeGoals > t.avgHomeGoals[1]) {
    next.baseChancePerTick = clamp(next.baseChancePerTick - 0.01, 0.12, 0.32);
    next.baseFinishRate = clamp(next.baseFinishRate - 0.012, 0.2, 0.45);
  }
  if (report.avgAwayGoals < t.avgAwayGoals[0]) {
    next.homeAdvantageAttack = clamp(next.homeAdvantageAttack - 0.01, 1.0, 1.12);
    next.baseChancePerTick = clamp(next.baseChancePerTick + 0.006, 0.12, 0.32);
  } else if (report.avgAwayGoals > t.avgAwayGoals[1]) {
    next.homeAdvantageAttack = clamp(next.homeAdvantageAttack + 0.008, 1.0, 1.12);
    next.gkSaveFactor = clamp(next.gkSaveFactor + 0.002, 0.02, 0.06);
  }
  void homeMid;

  // Draws / wins
  if (report.drawRate > t.drawRate[1]) {
    next.baseFinishRate = clamp(next.baseFinishRate + 0.01, 0.2, 0.45);
    next.finishNoiseAmplitude = clamp(next.finishNoiseAmplitude + 0.01, 0.1, 0.4);
  } else if (report.drawRate < t.drawRate[0]) {
    next.baseFinishRate = clamp(next.baseFinishRate - 0.01, 0.2, 0.45);
    next.gkSaveFactor = clamp(next.gkSaveFactor + 0.002, 0.02, 0.06);
  }

  if (report.homeWinRate < t.homeWinRate[0]) {
    next.homeAdvantageAttack = clamp(next.homeAdvantageAttack + 0.01, 1.0, 1.12);
    next.homeAdvantageMid = clamp(next.homeAdvantageMid + 0.008, 1.0, 1.1);
  } else if (report.homeWinRate > t.homeWinRate[1]) {
    next.homeAdvantageAttack = clamp(next.homeAdvantageAttack - 0.01, 1.0, 1.12);
    next.homeAdvantageMid = clamp(next.homeAdvantageMid - 0.008, 1.0, 1.1);
  }

  if (report.awayWinRate < t.awayWinRate[0]) {
    next.homeAdvantageAttack = clamp(next.homeAdvantageAttack - 0.008, 1.0, 1.12);
    next.underdogFloor = clamp(next.underdogFloor + 0.01, 0.12, 0.38);
  } else if (report.awayWinRate > t.awayWinRate[1]) {
    next.homeAdvantageAttack = clamp(next.homeAdvantageAttack + 0.008, 1.0, 1.12);
  }

  // Scoreless / 4+
  if (report.scorelessRate > t.scorelessRate[1]) {
    next.baseChancePerTick = clamp(next.baseChancePerTick + 0.01, 0.12, 0.32);
    next.baseFinishRate = clamp(next.baseFinishRate + 0.01, 0.2, 0.45);
  } else if (report.scorelessRate < t.scorelessRate[0]) {
    next.baseFinishRate = clamp(next.baseFinishRate - 0.008, 0.2, 0.45);
  }

  if (report.fourPlusRate > t.fourPlusRate[1]) {
    next.baseFinishRate = clamp(next.baseFinishRate - 0.012, 0.2, 0.45);
    next.maxTickChance = clamp(next.maxTickChance - 0.02, 0.4, 0.7);
  } else if (report.fourPlusRate < t.fourPlusRate[0]) {
    next.baseChancePerTick = clamp(next.baseChancePerTick + 0.008, 0.12, 0.32);
    next.maxTickChance = clamp(next.maxTickChance + 0.015, 0.4, 0.7);
  }

  return next;
}

let bestKnobs = knobsFrom(DEFAULT_SIMULATION_CONFIG);
let bestLoss = Infinity;
let bestReport: BalanceReport | null = null;

console.log(`Auto-balance SAMPLE=${SAMPLE} MAX_ITERS=${MAX_ITERS}`);

for (let iter = 0; iter < MAX_ITERS; iter++) {
  const cfg = mergeConfig(bestKnobs);
  const report = runMonteCarlo(SAMPLE, cfg, 300_000 + iter * 10_000);
  const loss = targetLoss(report);
  const { score, misses } = scoreAgainstTargets(report);
  console.log(
    `\n[iter ${iter}] loss=${loss.toFixed(4)} targetScore=${score.toFixed(0)} strong=${
      (report.strongVsWeakWinRate * 100).toFixed(1)
    }% homeG=${report.avgHomeGoals.toFixed(2)} draw=${
      (report.drawRate * 100).toFixed(1)
    }%`,
  );
  if (misses.length) console.log("  misses:", misses.join("; "));

  if (loss < bestLoss) {
    bestLoss = loss;
    bestReport = report;
    // keep current bestKnobs as evaluated
  }

  if (score === 100) {
    console.log("All targets hit on sample.");
    break;
  }

  bestKnobs = adjust(bestKnobs, report);
}

const finalCfg = mergeConfig(bestKnobs);
const verify = runMonteCarlo(SAMPLE * 2, finalCfg, 900_000);
const verified = scoreAgainstTargets(verify);
console.log("\n=== Best knobs ===");
console.log(JSON.stringify(bestKnobs, null, 2));
console.log("\n=== Verify sample ===");
console.log(JSON.stringify(verify, null, 2));
console.log(`verify target score: ${verified.score}`);
console.log(verified.misses);

await Deno.writeTextFile(
  new URL("./calibrated_knobs.json", import.meta.url),
  JSON.stringify({ knobs: bestKnobs, verify, misses: verified.misses }, null, 2),
);
console.log("Wrote calibrated_knobs.json");
