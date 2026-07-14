import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { mergeConfig } from "../config.ts";
import { runMonteCarlo, scoreAgainstTargets } from "./monte_carlo_lib.ts";

const N = 10_000;

Deno.test({
  name: `Monte Carlo ${N} smoke (targets soft)`,
  sanitizeResources: false,
  sanitizeOps: false,
  fn() {
    const report = runMonteCarlo(N, mergeConfig(), 10_000);
    console.log(JSON.stringify(report, null, 2));
    assert(report.strongVsWeakWinRate >= 0.65 && report.strongVsWeakWinRate <= 0.9);
    assert(report.avgHomeGoals > 1.0 && report.avgHomeGoals < 1.6);
    const { score } = scoreAgainstTargets(report);
    assert(score >= 70, `target score ${score}`);
  },
});
