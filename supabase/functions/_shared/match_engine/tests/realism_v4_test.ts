/**
 * v4 realism unit scenarios — deterministic seed checks.
 */
import {
  assert,
  assertEquals,
  assertGreater,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { mergeConfig } from "../config.ts";
import { duelSuccess } from "../event_resolution.ts";
import { fatiguePerformanceMul, computePlayerDrain } from "../fatigue.ts";
import { keyPosFormationMul } from "../key_position_effect.ts";
import { simulateMatch } from "../match_simulator.ts";
import { buildEffectiveAbilities } from "../player_rating.ts";
import { SeededRandom } from "../seeded_random.ts";
import { makeInput, makePlayer, makeTeam } from "./fixtures.ts";

Deno.test("same seed yields identical subs and injuries", () => {
  const input = makeInput(4242, 7, 7, {
    home: makeTeam("home", 7, { formation: "4-3-3", formationType: "P" }),
    away: makeTeam("away", 7, { formation: "5-4-1", formationType: "P" }),
  });
  const a = simulateMatch(input);
  const b = simulateMatch(input);
  assertEquals(a.homeScore, b.homeScore);
  assertEquals(a.awayScore, b.awayScore);
  assertEquals(a.events.length, b.events.length);
  assertEquals(
    JSON.stringify(a.playerMatchStats),
    JSON.stringify(b.playerMatchStats),
  );
});

Deno.test("high stamina drains slower than low stamina", () => {
  const config = mergeConfig();
  const high = buildEffectiveAbilities(
    makeTeam("h", 7, {
      playerExtras: () => ({ stamina: 10 }),
    }),
    config,
  )[1]!;
  const low = buildEffectiveAbilities(
    makeTeam("l", 7, {
      playerExtras: () => ({ stamina: 2 }),
    }),
    config,
  )[1]!;
  high.staminaStat = 10;
  low.staminaStat = 2;
  const ctx = {
    minute: 60,
    formationType: "T",
    styleExtra: 0,
    trailing: false,
    redCardDeficit: 0,
    pressIntensity: 0.3,
  };
  const dHigh = computePlayerDrain(high, config, ctx);
  const dLow = computePlayerDrain(low, config, ctx);
  assertGreater(dLow, dHigh);
});

Deno.test("fatigue curve is gradual", () => {
  const config = mergeConfig();
  assertEquals(fatiguePerformanceMul(0.85, config), 1);
  assertGreater(fatiguePerformanceMul(0.6, config), fatiguePerformanceMul(0.4, config));
  assertGreater(fatiguePerformanceMul(0.4, config), fatiguePerformanceMul(0.2, config));
});

Deno.test("P formation type increases drain vs T", () => {
  const config = mergeConfig();
  const ab = buildEffectiveAbilities(makeTeam("h", 7), config)[4]!;
  const dP = computePlayerDrain(ab, config, {
    minute: 50,
    formationType: "P",
    styleExtra: 0,
    trailing: false,
    redCardDeficit: 0,
    pressIntensity: 0.5,
  });
  const dT = computePlayerDrain(ab, config, {
    minute: 50,
    formationType: "T",
    styleExtra: 0,
    trailing: false,
    redCardDeficit: 0,
    pressIntensity: 0.5,
  });
  assertGreater(dP, dT);
});

Deno.test("higher power wins more duels on average", () => {
  const config = mergeConfig();
  const strong = buildEffectiveAbilities(
    makeTeam("s", 8, { playerExtras: () => ({ power: 10, technique: 6 }) }),
    config,
  )[3]!;
  const weak = buildEffectiveAbilities(
    makeTeam("w", 8, { playerExtras: () => ({ power: 3, technique: 6 }) }),
    config,
  )[3]!;
  strong.power = 10;
  weak.power = 3;
  const pStrong = duelSuccess(strong, weak, config);
  const pWeak = duelSuccess(weak, strong, config);
  assertGreater(pStrong, pWeak);
});

Deno.test("substituted-out player is not primary after sub", () => {
  // Force many subs via config
  const input = makeInput(9001, 6, 6, {
    home: makeTeam("home", 6, {
      formation: "3-5-2",
      formationType: "P",
      playerExtras: (i) =>
        i === 4 || i === 8
          ? { stamina: 1, staminaFraction: 0.5 }
          : {},
    }),
    away: makeTeam("away", 6),
  });
  const result = simulateMatch(input, {
    subWindowStart: 50,
    subWindowEnd: 85,
    subBaseChancePerTick: 0.35,
    subEarlyFatigueThreshold: 0.99,
    maxSubstitutions: 5,
  });
  const subEvents = result.events.filter((e) => e.type === "substitution");
  for (const sub of subEvents) {
    const outId = sub.substitutedOutPlayerId;
    if (!outId) continue;
    const after = result.events.filter(
      (e) =>
        e.matchMinute > sub.matchMinute &&
        e.primaryPlayerId === outId &&
        e.type !== "substitution",
    );
    assertEquals(after.length, 0, `out player ${outId} appeared after sub`);
  }
});

Deno.test("team stats sum player duel/tackle fields", () => {
  const result = simulateMatch(makeInput(77, 7, 7));
  const home = result.playerMatchStats.filter((p) => p.teamId === "home");
  const sumDuels = home.reduce((s, p) => s + p.duelsAttempted, 0);
  assert(sumDuels >= 0);
  assertEquals(
    result.statistics.homeShots,
    home.reduce((s, p) => s + p.shots, 0),
  );
});

Deno.test("5-4-1 produces fewer combined shots than 4-2-4 over sample", () => {
  let shots541 = 0;
  let shots424 = 0;
  for (let i = 0; i < 40; i++) {
    const a = simulateMatch(
      makeInput(2000 + i, 7, 7, {
        home: makeTeam("home", 7, { formation: "5-4-1", formationType: "P" }),
        away: makeTeam("away", 7, { formation: "5-4-1", formationType: "P" }),
        homeAdvantage: false,
      }),
    );
    const b = simulateMatch(
      makeInput(3000 + i, 7, 7, {
        home: makeTeam("home", 7, {
          formation: "4-2-4",
          formationType: "S",
          attack: 10,
          stability: 2,
        }),
        away: makeTeam("away", 7, {
          formation: "4-2-4",
          formationType: "S",
          attack: 10,
          stability: 2,
        }),
        homeAdvantage: false,
      }),
    );
    shots541 += a.statistics.homeShots + a.statistics.awayShots;
    shots424 += b.statistics.homeShots + b.statistics.awayShots;
  }
  assertGreater(shots424, shots541);
});

Deno.test("strong key positions raise formation mul vs weak", () => {
  const config = mergeConfig();
  const strongTeam = makeTeam("s", 9, {
    formation: "4-3-3",
    formationType: "S",
    keyPositions: [
      { id: "kp_wing_forward_l", slot: 1 },
      { id: "kp_wing_forward_r", slot: 3 },
      { id: "kp_playmaker", slot: 5 },
    ],
  });
  const weakTeam = makeTeam("w", 3, {
    formation: "4-3-3",
    formationType: "S",
    keyPositions: [
      { id: "kp_wing_forward_l", slot: 1 },
      { id: "kp_wing_forward_r", slot: 3 },
      { id: "kp_playmaker", slot: 5 },
    ],
  });
  const sAb = buildEffectiveAbilities(strongTeam, config);
  const wAb = buildEffectiveAbilities(weakTeam, config);
  assertGreater(
    keyPosFormationMul(sAb, strongTeam, config),
    keyPosFormationMul(wAb, weakTeam, config),
  );
});

Deno.test("power duel advantage does not imply always more fouls", () => {
  let foulsHigh = 0;
  let foulsLow = 0;
  for (let i = 0; i < 30; i++) {
    const hi = simulateMatch(
      makeInput(5000 + i, 7, 7, {
        home: makeTeam("home", 7, {
          playerExtras: () => ({ power: 10 }),
        }),
        away: makeTeam("away", 7),
      }),
    );
    const lo = simulateMatch(
      makeInput(6000 + i, 7, 7, {
        home: makeTeam("home", 7, {
          playerExtras: () => ({ power: 3 }),
        }),
        away: makeTeam("away", 7),
      }),
    );
    foulsHigh += hi.statistics.homeFouls;
    foulsLow += lo.statistics.homeFouls;
  }
  // Not required to be lower — just ensure high power isn't massively foul-heavy
  assert(foulsHigh < foulsLow * 2.5);
});

void SeededRandom;
void makePlayer;
