/**
 * Monte Carlo v4 report sections A–D (sample sizes configurable).
 * Run: deno run -A tests/monte_carlo_v4_report.ts
 */
import { simulateMatch } from "../match_simulator.ts";
import { makeInput, makeTeam } from "./fixtures.ts";

const N = Number(Deno.env.get("MC_N") ?? "2000");

function runBatch(
  n: number,
  build: (i: number) => ReturnType<typeof makeInput>,
) {
  let homeGoals = 0;
  let awayGoals = 0;
  let draws = 0;
  let homeWins = 0;
  let awayWins = 0;
  let zeroZero = 0;
  let shots = 0;
  let sot = 0;
  let fouls = 0;
  let yellows = 0;
  let reds = 0;
  let injuries = 0;
  let subs = 0;
  let duels = 0;
  let duelWins = 0;
  let aerials = 0;
  let aerialWins = 0;
  let tackles = 0;
  let tackleWins = 0;

  for (let i = 0; i < n; i++) {
    const r = simulateMatch(build(i));
    homeGoals += r.homeScore;
    awayGoals += r.awayScore;
    if (r.homeScore === r.awayScore) draws++;
    else if (r.homeScore > r.awayScore) homeWins++;
    else awayWins++;
    if (r.homeScore === 0 && r.awayScore === 0) zeroZero++;
    shots += r.statistics.homeShots + r.statistics.awayShots;
    sot += r.statistics.homeShotsOnTarget + r.statistics.awayShotsOnTarget;
    fouls += r.statistics.homeFouls + r.statistics.awayFouls;
    yellows += r.statistics.homeYellowCards + r.statistics.awayYellowCards;
    reds += r.statistics.homeRedCards + r.statistics.awayRedCards;
    injuries += r.playerMatchStats.reduce((s, p) => s + p.injuries, 0);
    subs += r.events.filter((e) => e.type === "substitution").length;
    for (const p of r.playerMatchStats) {
      duels += p.duelsAttempted;
      duelWins += p.duelsWon;
      aerials += p.aerialDuelsAttempted;
      aerialWins += p.aerialDuelsWon;
      tackles += p.tacklesAttempted;
      tackleWins += p.tacklesWon;
    }
  }
  return {
    n,
    avgHomeGoals: homeGoals / n,
    avgAwayGoals: awayGoals / n,
    drawRate: draws / n,
    homeWinRate: homeWins / n,
    awayWinRate: awayWins / n,
    zeroZeroRate: zeroZero / n,
    avgShots: shots / n,
    avgSot: sot / n,
    avgFouls: fouls / n,
    avgYellows: yellows / n,
    avgReds: reds / n,
    avgInjuries: injuries / n,
    avgSubs: subs / n,
    duelWinRate: duels === 0 ? 0 : duelWins / duels,
    aerialWinRate: aerials === 0 ? 0 : aerialWins / aerials,
    tackleWinRate: tackles === 0 ? 0 : tackleWins / tackles,
  };
}

console.log("=== A. Overall sample ===");
console.log(
  runBatch(N, (i) => makeInput(100000 + i, 7, 7)),
);

console.log("=== B. Formation sample (equal teams) ===");
for (const form of ["4-3-3", "4-4-2", "5-4-1", "4-2-4", "3-5-2", "4-1-2-1-2"]) {
  const stats = runBatch(Math.min(400, N), (i) =>
    makeInput(200000 + i, 7, 7, {
      home: makeTeam("home", 7, { formation: form }),
      away: makeTeam("away", 7, { formation: "4-4-2" }),
      homeAdvantage: false,
    }));
  console.log(form, {
    homeWin: stats.homeWinRate,
    draw: stats.drawRate,
    avgShots: stats.avgShots,
    avgGoals: stats.avgHomeGoals + stats.avgAwayGoals,
  });
}

console.log("=== C. Stamina comparison ===");
const hiSta = runBatch(Math.min(500, N), (i) =>
  makeInput(300000 + i, 7, 7, {
    home: makeTeam("home", 7, { playerExtras: () => ({ stamina: 10 }) }),
    away: makeTeam("away", 7, { playerExtras: () => ({ stamina: 10 }) }),
  }));
const loSta = runBatch(Math.min(500, N), (i) =>
  makeInput(400000 + i, 7, 7, {
    home: makeTeam("home", 7, { playerExtras: () => ({ stamina: 2 }) }),
    away: makeTeam("away", 7, { playerExtras: () => ({ stamina: 2 }) }),
  }));
console.log({ highStamina: hiSta, lowStamina: loSta });

console.log("=== D. Power comparison ===");
const hiPow = runBatch(Math.min(500, N), (i) =>
  makeInput(500000 + i, 7, 7, {
    home: makeTeam("home", 7, { playerExtras: () => ({ power: 10 }) }),
    away: makeTeam("away", 7, { playerExtras: () => ({ power: 3 }) }),
  }));
console.log(hiPow);
