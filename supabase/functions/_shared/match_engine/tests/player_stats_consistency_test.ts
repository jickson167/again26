import {
  assertEquals,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { simulateMatch } from "../match_simulator.ts";
import { makeInput } from "./fixtures.ts";
import { countAssistsFromEvents, countGoalsFromEvents } from "../statistics.ts";

Deno.test("team shot sums match player shot sums", () => {
  const r = simulateMatch(makeInput(101, 7, 6));
  const homeShots = r.playerMatchStats
    .filter((p) => p.teamId === r.homeClubId)
    .reduce((s, p) => s + p.shots, 0);
  const awayShots = r.playerMatchStats
    .filter((p) => p.teamId === r.awayClubId)
    .reduce((s, p) => s + p.shots, 0);
  assertEquals(r.statistics.homeShots, homeShots);
  assertEquals(r.statistics.awayShots, awayShots);
});

Deno.test("team SoT / corners / cards / fouls / saves match player sums", () => {
  for (let s = 0; s < 20; s++) {
    const r = simulateMatch(makeInput(200 + s, 7, 7));
    const home = r.playerMatchStats.filter((p) => p.teamId === r.homeClubId);
    const away = r.playerMatchStats.filter((p) => p.teamId === r.awayClubId);
    const sum = <K extends keyof (typeof home)[0]>(
      list: typeof home,
      key: K,
    ) => list.reduce((a, p) => a + Number(p[key]), 0);

    assertEquals(r.statistics.homeShotsOnTarget, sum(home, "shotsOnTarget"));
    assertEquals(r.statistics.awayShotsOnTarget, sum(away, "shotsOnTarget"));
    assertEquals(r.statistics.homeCorners, sum(home, "cornersTaken"));
    assertEquals(r.statistics.awayCorners, sum(away, "cornersTaken"));
    assertEquals(r.statistics.homeFouls, sum(home, "foulsCommitted"));
    assertEquals(r.statistics.awayFouls, sum(away, "foulsCommitted"));
    assertEquals(r.statistics.homeYellowCards, sum(home, "yellowCards"));
    assertEquals(r.statistics.awayYellowCards, sum(away, "yellowCards"));
    assertEquals(r.statistics.homeRedCards, sum(home, "redCards"));
    assertEquals(r.statistics.awayRedCards, sum(away, "redCards"));
    assertEquals(r.statistics.homeSaves, sum(home, "saves"));
    assertEquals(r.statistics.awaySaves, sum(away, "saves"));
    assertEquals(r.statistics.homeAssists, sum(home, "assists"));
    assertEquals(r.statistics.awayAssists, sum(away, "assists"));
  }
});

Deno.test("goal and assist events match player and score totals", () => {
  for (let s = 0; s < 30; s++) {
    const r = simulateMatch(makeInput(300 + s, 8, 6));
    assertEquals(
      countGoalsFromEvents(r.events, r.homeClubId),
      r.homeScore,
    );
    assertEquals(
      countGoalsFromEvents(r.events, r.awayClubId),
      r.awayScore,
    );
    assertEquals(r.statistics.homeGoals, r.homeScore);
    assertEquals(r.statistics.awayGoals, r.awayScore);

    const homeAssists = r.playerMatchStats
      .filter((p) => p.teamId === r.homeClubId)
      .reduce((a, p) => a + p.assists, 0);
    assertEquals(countAssistsFromEvents(r.events, r.homeClubId), homeAssists);
    assert(homeAssists <= r.homeScore);
  }
});

Deno.test("corner events equal cornersTaken sum", () => {
  const r = simulateMatch(makeInput(400, 7, 7));
  const cornerEvents = r.events.filter((e) => e.type === "corner").length;
  const taken = r.playerMatchStats.reduce((s, p) => s + p.cornersTaken, 0);
  assertEquals(cornerEvents, taken);
});

Deno.test("same seed yields identical playerMatchStats", () => {
  const input = makeInput(777, 7, 7);
  const a = simulateMatch(input);
  const b = simulateMatch(input);
  assertEquals(
    JSON.stringify(a.playerMatchStats),
    JSON.stringify(b.playerMatchStats),
  );
});

Deno.test("sent-off player is not primary on later goals", () => {
  const harsh = { yellowCardPerTick: 0.3, redFromYellowChance: 0.95, straightRedChance: 0.08 };
  for (let s = 0; s < 30; s++) {
    const r = simulateMatch(makeInput(500 + s, 7, 7), harsh);
    for (const p of r.playerMatchStats) {
      if (!p.sentOff) continue;
      const redMin = r.events.find(
        (e) => e.type === "red_card" && e.primaryPlayerId === p.playerId,
      )?.matchMinute ?? 999;
      const laterGoal = r.events.find(
        (e) =>
          e.type === "goal" &&
          e.primaryPlayerId === p.playerId &&
          e.matchMinute > redMin,
      );
      assertEquals(laterGoal, undefined);
    }
  }
});

Deno.test("events carry scoreline and result has playerMatchStats alias", () => {
  const r = simulateMatch(makeInput(42, 7, 6));
  assert(r.playerMatchStats.length > 0);
  assertEquals(r.playerMatchStats, r.playerResults);
  for (const e of r.events) {
    assert(typeof e.currentHomeScore === "number");
    assert(typeof e.currentAwayScore === "number");
  }
  const ft = r.events.find((e) => e.type === "fulltime");
  assert(ft);
  assertEquals(ft!.currentHomeScore, r.homeScore);
  assertEquals(ft!.currentAwayScore, r.awayScore);
});
