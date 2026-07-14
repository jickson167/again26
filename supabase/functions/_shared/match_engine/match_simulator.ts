import { mergeConfig, type SimulationConfig } from "./config.ts";
import {
  attackX,
  ballPosition,
  laneToY,
  makeEvent,
  progressionEvent,
} from "./event_generator.ts";
import {
  buildCardPayload,
  buildCornerPayload,
  buildFoulPayload,
  buildGoalAndShotFlavor,
  envelope,
  type FoulType,
} from "./event_metadata.ts";
import {
  aggressiveFoulChance,
  aerialSuccess,
  duelSuccess,
  personalPassSuccess,
  personalShotFactor,
  tackleSuccess,
} from "./event_resolution.ts";
import { applyDrain, computePlayerDrain } from "./fatigue.ts";
import { applyInjury, rollInjury } from "./injury.ts";
import { matchupLaneWeights, microMatchupBonus } from "./micro_matchup.ts";
import {
  buildEffectiveAbilities,
  pickAttacker,
  pickCreator,
  pickDefender,
} from "./player_rating.ts";
import { SeededRandom } from "./seeded_random.ts";
import {
  buildStatisticsFromPlayers,
  countGoalsFromEvents,
  emptyPlayerAcc,
  finalizePlayerResults,
  type PlayerAcc,
} from "./statistics.ts";
import {
  applySubstitutionSafe,
  maybeDecideSubstitution,
} from "./substitution_ai.ts";
import {
  attackAxis,
  computeZoneStrength,
  defenseAxis,
  midAxis,
  possessionShare,
  resolveTacticMod,
  softContestShare,
} from "./team_strength.ts";
import type {
  EffectiveAbilities,
  Lane,
  MatchEvent,
  MatchSimulationInput,
  MatchSimulationResult,
  Side,
  TeamSimulationSnapshot,
  ZoneStrength,
} from "./types.ts";

const LANES: Lane[] = ["left", "center", "right"];

type LiveScore = { home: number; away: number };

function setpieceChance(
  config: SimulationConfig,
  minute: number,
  baseMul = 1,
): number {
  let p = config.setpieceChanceOnFailedAttack * baseMul;
  if (minute < config.earlySetpieceUntilMinute) {
    p *= config.earlySetpieceChanceMul;
  }
  return p;
}

function fitSlotLabel(fitSlot: number): string {
  const m: Record<number, string> = {
    1: "LW",
    2: "ST",
    3: "RW",
    4: "LM",
    5: "CAM",
    6: "RM",
    7: "LB",
    8: "CDM",
    9: "RB",
    10: "LWB",
    11: "CB",
    12: "RWB",
    13: "GK",
  };
  return m[fitSlot] ?? "UNK";
}

/**
 * Pure match simulation — no DB, no network.
 * Deterministic for the same input + config.simulationVersion + seed.
 */
export function simulateMatch(
  input: MatchSimulationInput,
  configOverrides?: Partial<SimulationConfig>,
): MatchSimulationResult {
  const config = mergeConfig({
    ...configOverrides,
    simulationVersion:
      configOverrides?.simulationVersion ??
      input.simulationVersion ??
      undefined,
  });
  // Prefer input.simulationVersion as source of truth when set
  if (input.simulationVersion) {
    config.simulationVersion = input.simulationVersion;
  }

  const rng = new SeededRandom(input.seed);
  const useHomeAdv = input.homeAdvantage !== false;

  const homeAb = buildEffectiveAbilities(input.home, config);
  const awayAb = buildEffectiveAbilities(input.away, config);

  const playerAcc = new Map<string, PlayerAcc>();
  initPlayers(playerAcc, input.home, "home");
  initPlayers(playerAcc, input.away, "away");

  const events: MatchEvent[] = [];
  const score: LiveScore = { home: 0, away: 0 };
  let homeReds = 0;
  let awayReds = 0;
  const possessionTicks = { home: 0, away: 0 };
  const xg = { home: 0, away: 0 };
  const yellows = new Map<string, number>();
  let homeSubsUsed = 0;
  let awaySubsUsed = 0;

  let possession: Side = rng.bool(0.55) ? "home" : "away";

  const ticks = Math.floor(config.matchMinutes / config.tickMinutes);

  for (let t = 0; t < ticks; t++) {
    const minute = t * config.tickMinutes;

    if (minute === 45) {
      events.push(
        makeEvent({
          minute: 45,
          type: "halftime",
          teamId: input.home.clubId,
          side: "home",
          commentaryKey: "halftime",
          currentHomeScore: score.home,
          currentAwayScore: score.away,
        }),
      );
    }

    syncSentOff(homeAb, awayAb, playerAcc);

    const homeStyleExtra =
      resolveTacticMod(input.home.tactic.coachStyle, config).staminaDrainExtra;
    const awayStyleExtra =
      resolveTacticMod(input.away.tactic.coachStyle, config).staminaDrainExtra;
    const homeTrailing = score.home < score.away;
    const awayTrailing = score.away < score.home;
    drainTeam(
      homeAb,
      config,
      {
        minute,
        formationType: input.home.formationType,
        styleExtra: homeStyleExtra,
        trailing: homeTrailing,
        redCardDeficit: Math.max(0, homeReds - awayReds),
        pressIntensity: (input.home.formationType ?? "").toUpperCase() === "P"
          ? 0.6
          : 0.25,
      },
    );
    drainTeam(
      awayAb,
      config,
      {
        minute,
        formationType: input.away.formationType,
        styleExtra: awayStyleExtra,
        trailing: awayTrailing,
        redCardDeficit: Math.max(0, awayReds - homeReds),
        pressIntensity: (input.away.formationType ?? "").toUpperCase() === "P"
          ? 0.6
          : 0.25,
      },
    );

    // Reset per-tick activity counters after drain consumed them
    for (const a of [...homeAb, ...awayAb]) {
      a.sprintActions = 0;
      a.pressingActions = 0;
      a.tackleActions = 0;
      a.duelActions = 0;
      a.attackInvolvements = 0;
    }

    const homeZones = computeZoneStrength(homeAb, input.home, "home", config, {
      homeAdvantage: useHomeAdv,
      redCardCount: homeReds,
      scoreDiff: score.home - score.away,
    });
    const awayZones = computeZoneStrength(awayAb, input.away, "away", config, {
      homeAdvantage: false,
      redCardCount: awayReds,
      scoreDiff: score.away - score.home,
    });

    // Possession contest
    const homeMid =
      homeZones.leftMid + homeZones.centerMid + homeZones.rightMid;
    const awayMid =
      awayZones.leftMid + awayZones.centerMid + awayZones.rightMid;
    const share = possessionShare(homeMid, awayMid);
    const homePossChance = share.home / 100;
    possession = rng.bool(homePossChance) ? "home" : "away";
    if (possession === "home") possessionTicks.home++;
    else possessionTicks.away++;

    const attacking: Side = possession;
    const defending: Side = attacking === "home" ? "away" : "home";
    const attTeam = attacking === "home" ? input.home : input.away;
    const defTeam = defending === "home" ? input.home : input.away;
    const attAb = attacking === "home" ? homeAb : awayAb;
    const defAb = defending === "home" ? homeAb : awayAb;
    const attZones = attacking === "home" ? homeZones : awayZones;
    const defZones = defending === "home" ? homeZones : awayZones;
    const attScore = attacking === "home" ? score.home : score.away;
    const defScore = attacking === "home" ? score.away : score.home;

    // Background progression
    const laneWeights = matchupLaneWeights(attZones, defZones, config);
    const lane = pickLaneWeighted(rng, attZones, defZones, laneWeights);
    for (let p = 0; p < config.progressionEventsPerTick; p++) {
      events.push(
        progressionEvent(
          rng,
          minute,
          attTeam.clubId,
          attacking,
          lane,
          0.25 + rng.next() * 0.2,
          0.45 + rng.next() * 0.25,
          score.home,
          score.away,
        ),
      );
    }

    // Dynamic chance
    let chance = config.baseChancePerTick;
    if (minute >= 75) chance *= config.lateGameChanceBoost;
    if (attScore < defScore) chance *= config.trailingAttackBoost;
    if (attScore > defScore) {
      chance *= config.leadingTempoDrop;
      if (attScore >= defScore + 2) chance *= config.twoGoalLeadTempoMul;
    }
    if (score.home + score.away >= 3) {
      chance *= config.highScoringDampMul;
    }

    const attStyle = resolveTacticMod(attTeam.tactic.coachStyle, config);
    const defStyle = resolveTacticMod(defTeam.tactic.coachStyle, config);
    chance *= attStyle.chanceMul;
    if (useHomeAdv) {
      chance *= attacking === "home"
        ? config.homeAttackChanceMul
        : config.awayAttackChanceMul;
    }

    const attPower = attackAxis(attZones, lane);
    const midPower = midAxis(attZones, lane);
    const defPower = defenseAxis(defZones, lane);
    const progressShare = softContestShare(
      attPower + midPower,
      defPower,
      config,
    );
    chance *= 0.7 + progressShare;
    chance *= 1 + microMatchupBonus(attZones, defZones, lane, config);
    // Counter teams get a bump when they just won possession from low mid
    if (possession === attacking && defStyle.counterMul > 1) {
      // defending team was set before flip — use attStyle for counter finish later
    }
    if (attStyle.counterMul > 1.05 && progressShare > 0.45) {
      chance *= 0.92 + attStyle.counterMul * 0.08;
    }
    // Soft tactic attack slider
    chance *= 1 + attTeam.tactic.attack * config.tacticAttackChanceExtra * 0.5;
    chance = Math.min(config.maxTickChance, chance);

    // Cards / fouls
    maybeCards(
      rng,
      config,
      minute,
      defending,
      defTeam,
      defAb,
      attAb,
      events,
      playerAcc,
      yellows,
      score,
      (side) => {
        if (side === "home") homeReds++;
        else awayReds++;
      },
    );

    if (!rng.bool(Math.min(config.maxTickChance, chance))) {
      // Failed / no chance — maybe set piece for defending clearance
      if (rng.bool(setpieceChance(config, minute, 0.5))) {
        events.push(
          makeEvent({
            minute,
            second: rng.int(0, 59),
            type: "possession_change",
            teamId: defTeam.clubId,
            side: defending,
            commentaryKey: "turnover",
            currentHomeScore: score.home,
            currentAwayScore: score.away,
          }),
        );
      }
      tickMinutes(playerAcc, homeAb, awayAb, config.tickMinutes);
      addLightPassVolume(rng, playerAcc, homeAb, awayAb, config);
      trySubs(
        rng,
        config,
        minute,
        input,
        homeAb,
        awayAb,
        playerAcc,
        events,
        score,
        () => homeSubsUsed++,
        () => awaySubsUsed++,
        homeSubsUsed,
        awaySubsUsed,
      );
      continue;
    }

    // Attack develops
    const creator = pickCreator(attAb, lane);
    const shooter = pickAttacker(attAb, lane);
    if (!shooter) {
      tickMinutes(playerAcc, homeAb, awayAb, config.tickMinutes);
      addLightPassVolume(rng, playerAcc, homeAb, awayAb, config);
      trySubs(
        rng,
        config,
        minute,
        input,
        homeAb,
        awayAb,
        playerAcc,
        events,
        score,
        () => homeSubsUsed++,
        () => awaySubsUsed++,
        homeSubsUsed,
        awaySubsUsed,
      );
      continue;
    }

    const y = laneToY(lane, rng);
    const buildCarrier = creator ?? shooter;
    events.push(
      makeEvent({
        minute,
        second: rng.int(0, 59),
        type: "attack_build",
        teamId: attTeam.clubId,
        side: attacking,
        primaryPlayerId: buildCarrier.playerId,
        secondaryPlayerId: creator && shooter.playerId !== creator.playerId
          ? shooter.playerId
          : undefined,
        from: ballPosition(attackX(attacking, 0.4), y),
        to: ballPosition(attackX(attacking, 0.7), y),
        success: true,
        commentaryKey: "attack_build",
        metadata: envelope("attack_build", { lane }, {
          primaryStyleIds: buildCarrier.styleIds,
          secondaryStyleIds: shooter.styleIds,
        }),
        currentHomeScore: score.home,
        currentAwayScore: score.away,
      }),
    );

    // Breakthrough check (softened contest)
    const breakShare = softContestShare(attPower, defPower, config);
    const breakChance = Math.min(
      config.maxBreakChance,
      0.28 + breakShare * 0.55 * attStyle.counterMul,
    );
    if (!rng.bool(breakChance)) {
      // Defensive tackle chance
      const defender = pickDefender(defAb, lane);
      if (defender && rng.bool(config.tackleChanceOnDefend)) {
        resolveTackleContact(
          rng,
          config,
          minute,
          defending,
          defTeam,
          attTeam,
          defender,
          shooter,
          events,
          playerAcc,
          score,
        );
      }
      if (rng.bool(setpieceChance(config, minute))) {
        resolveSetpiece(
          rng,
          config,
          minute,
          attacking,
          attTeam,
          defTeam,
          attAb,
          defAb,
          defZones,
          lane,
          events,
          playerAcc,
          xg,
          score,
        );
      }
      tickMinutes(playerAcc, homeAb, awayAb, config.tickMinutes);
      addLightPassVolume(rng, playerAcc, homeAb, awayAb, config);
      trySubs(
        rng,
        config,
        minute,
        input,
        homeAb,
        awayAb,
        playerAcc,
        events,
        score,
        () => homeSubsUsed++,
        () => awaySubsUsed++,
        homeSubsUsed,
        awaySubsUsed,
      );
      continue;
    }

    // Shot sequence
    shooter.attackInvolvements++;
    shooter.sprintActions++;
    if (creator) creator.attackInvolvements++;

    maybeContactEvents(
      rng,
      config,
      minute,
      attacking,
      defending,
      attTeam,
      defTeam,
      attAb,
      defAb,
      shooter,
      lane,
      events,
      playerAcc,
      score,
    );

    const shotXg = estimateXg(
      attPower,
      defZones.goalkeeping,
      config,
      attStyle.finishMul,
      rng,
      shooter,
    );
    if (attacking === "home") xg.home += shotXg;
    else xg.away += shotXg;

    resolveShot(
      rng,
      config,
      minute,
      attacking,
      attTeam,
      defTeam,
      shooter,
      creator,
      defZones,
      lane,
      events,
      playerAcc,
      shotXg,
      score,
      {
        counterAttackHint: attStyle.counterMul > 1.05,
        fromSetPiece: undefined,
      },
    );

    tickMinutes(playerAcc, homeAb, awayAb, config.tickMinutes);
    addLightPassVolume(rng, playerAcc, homeAb, awayAb, config);
    trySubs(
      rng,
      config,
      minute,
      input,
      homeAb,
      awayAb,
      playerAcc,
      events,
      score,
      () => homeSubsUsed++,
      () => awaySubsUsed++,
      homeSubsUsed,
      awaySubsUsed,
    );
  }

  // Ensure score matches goal events (authoritative from events)
  score.home = countGoalsFromEvents(events, input.home.clubId);
  score.away = countGoalsFromEvents(events, input.away.clubId);

  events.push(
    makeEvent({
      minute: 90,
      type: "fulltime",
      teamId: input.home.clubId,
      side: "home",
      commentaryKey: "fulltime",
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );

  // Goals conceded on each team's GK
  const homeGkId = findGoalkeeperId(input.home);
  const awayGkId = findGoalkeeperId(input.away);
  if (homeGkId) {
    const g = playerAcc.get(homeGkId);
    if (g) g.goalsConceded += score.away;
  }
  if (awayGkId) {
    const g = playerAcc.get(awayGkId);
    if (g) g.goalsConceded += score.home;
  }

  const { results, mvpPlayerId } = finalizePlayerResults(playerAcc, config);
  const statistics = buildStatisticsFromPlayers(
    results,
    input.home.clubId,
    possessionTicks,
    xg,
    score.home,
    score.away,
  );

  return {
    matchId: input.matchId,
    seed: input.seed,
    simulationVersion: config.simulationVersion,
    homeScore: score.home,
    awayScore: score.away,
    homeClubId: input.home.clubId,
    awayClubId: input.away.clubId,
    homeClubName: input.home.clubName,
    awayClubName: input.away.clubName,
    events,
    statistics,
    playerMatchStats: results,
    playerResults: results,
    mvpPlayerId,
  };
}

function initPlayers(
  map: Map<string, PlayerAcc>,
  team: TeamSimulationSnapshot,
  side: Side,
): void {
  for (let i = 0; i < team.starters.length; i++) {
    const p = team.starters[i];
    const asg = team.assignments.find((a) => a.pitchSlot === i + 1) ??
      team.assignments[i];
    const fitSlot = asg?.fitSlot ?? p.assignedFit ?? 7;
    map.set(
      p.playerId,
      emptyPlayerAcc(
        p.playerId,
        team.clubId,
        side,
        p.staminaFraction ?? 1,
        {
          name: p.name,
          position: fitSlotLabel(fitSlot),
          positionFit: p.assignedFit,
          userPlayerId: p.userPlayerId,
          started: true,
        },
      ),
    );
  }
}

function findGoalkeeperId(team: TeamSimulationSnapshot): string | undefined {
  for (let i = 0; i < team.starters.length; i++) {
    const asg = team.assignments.find((a) => a.pitchSlot === i + 1) ??
      team.assignments[i];
    if (asg && (asg.line === "gk" || asg.fitSlot === 13)) {
      return team.starters[i]?.playerId;
    }
  }
  return team.starters[0]?.playerId;
}

function drainTeam(
  abilities: EffectiveAbilities[],
  config: SimulationConfig,
  ctx: {
    minute: number;
    formationType?: string;
    styleExtra: number;
    trailing: boolean;
    redCardDeficit: number;
    pressIntensity: number;
  },
): void {
  for (const a of abilities) {
    const drain = computePlayerDrain(a, config, ctx);
    applyDrain(a, drain, config);
  }
}

function trySubs(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  input: MatchSimulationInput,
  homeAb: EffectiveAbilities[],
  awayAb: EffectiveAbilities[],
  playerAcc: Map<string, PlayerAcc>,
  events: MatchEvent[],
  score: LiveScore,
  onHomeSub: () => void,
  onAwaySub: () => void,
  homeSubsUsed: number,
  awaySubsUsed: number,
): void {
  const homeDec = maybeDecideSubstitution(
    rng,
    config,
    minute,
    "home",
    input.home,
    homeAb,
    playerAcc,
    score.home,
    score.away,
    homeSubsUsed,
  );
  if (homeDec) {
    applySubstitutionSafe(
      homeDec,
      homeAb,
      input.home,
      config,
      playerAcc,
      "home",
      minute,
      events,
      score.home,
      score.away,
      emptyPlayerAcc,
    );
    onHomeSub();
  }
  const awayDec = maybeDecideSubstitution(
    rng,
    config,
    minute,
    "away",
    input.away,
    awayAb,
    playerAcc,
    score.home,
    score.away,
    awaySubsUsed,
  );
  if (awayDec) {
    applySubstitutionSafe(
      awayDec,
      awayAb,
      input.away,
      config,
      playerAcc,
      "away",
      minute,
      events,
      score.home,
      score.away,
      emptyPlayerAcc,
    );
    onAwaySub();
  }
}

function maybeContactEvents(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  attacking: Side,
  defending: Side,
  attTeam: TeamSimulationSnapshot,
  defTeam: TeamSimulationSnapshot,
  attAb: EffectiveAbilities[],
  defAb: EffectiveAbilities[],
  shooter: EffectiveAbilities,
  lane: Lane,
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  score: LiveScore,
): void {
  const defender = pickDefender(defAb, lane);
  if (defender && rng.bool(config.duelChancePerAttack)) {
    const win = rng.bool(duelSuccess(shooter, defender, config));
    shooter.duelActions++;
    defender.duelActions++;
    const sAcc = playerAcc.get(shooter.playerId);
    const dAcc = playerAcc.get(defender.playerId);
    if (sAcc) {
      sAcc.duelsAttempted++;
      if (win) sAcc.duelsWon++;
    }
    if (dAcc) {
      dAcc.duelsAttempted++;
      if (!win) dAcc.duelsWon++;
    }
    events.push(
      makeEvent({
        minute,
        second: rng.int(0, 59),
        type: "duel",
        teamId: win ? attTeam.clubId : defTeam.clubId,
        side: win ? attacking : defending,
        primaryPlayerId: win ? shooter.playerId : defender.playerId,
        secondaryPlayerId: win ? defender.playerId : shooter.playerId,
        success: win,
        commentaryKey: "duel",
        currentHomeScore: score.home,
        currentAwayScore: score.away,
      }),
    );
    const inj = rollInjury(
      rng,
      config,
      minute,
      win ? defender : shooter,
      win ? shooter : defender,
      "duel",
      false,
    );
    if (inj) {
      applyInjury(
        inj,
        win ? defender : shooter,
        win ? defTeam : attTeam,
        win ? defending : attacking,
        minute,
        events,
        playerAcc,
        score.home,
        score.away,
      );
    }
  }

  if (defender && rng.bool(config.aerialChancePerAttack)) {
    const win = rng.bool(aerialSuccess(shooter, defender, config));
    const sAcc = playerAcc.get(shooter.playerId);
    const dAcc = playerAcc.get(defender.playerId);
    if (sAcc) {
      sAcc.aerialDuelsAttempted++;
      if (win) sAcc.aerialDuelsWon++;
    }
    if (dAcc) {
      dAcc.aerialDuelsAttempted++;
      if (!win) dAcc.aerialDuelsWon++;
    }
    events.push(
      makeEvent({
        minute,
        second: rng.int(0, 59),
        type: "aerial_duel",
        teamId: win ? attTeam.clubId : defTeam.clubId,
        side: win ? attacking : defending,
        primaryPlayerId: win ? shooter.playerId : defender.playerId,
        secondaryPlayerId: win ? defender.playerId : shooter.playerId,
        success: win,
        commentaryKey: "aerial",
        currentHomeScore: score.home,
        currentAwayScore: score.away,
      }),
    );
  }
}

function resolveTackleContact(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  defending: Side,
  defTeam: TeamSimulationSnapshot,
  attTeam: TeamSimulationSnapshot,
  tackler: EffectiveAbilities,
  carrier: EffectiveAbilities,
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  score: LiveScore,
): void {
  const success = rng.bool(tackleSuccess(tackler, carrier, config));
  tackler.tackleActions++;
  tackler.pressingActions++;
  const tAcc = playerAcc.get(tackler.playerId);
  if (tAcc) {
    tAcc.tacklesAttempted++;
    if (success) tAcc.tacklesWon++;
    tAcc.pressingActions++;
  }
  events.push(
    makeEvent({
      minute,
      second: rng.int(0, 59),
      type: "tackle",
      teamId: defTeam.clubId,
      side: defending,
      primaryPlayerId: tackler.playerId,
      secondaryPlayerId: carrier.playerId,
      success,
      commentaryKey: "tackle",
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );

  const foul = rng.bool(aggressiveFoulChance(tackler, success, config));
  if (foul) {
    emitFoulWithFouler(
      rng,
      minute,
      defending,
      defTeam,
      tackler.playerId,
      [carrier],
      events,
      playerAcc,
      score,
    );
  }

  const victim = foul || !success ? carrier : carrier;
  const inj = rollInjury(
    rng,
    config,
    minute,
    victim,
    tackler,
    "tackle",
    foul,
  );
  if (inj) {
    applyInjury(
      inj,
      victim,
      attTeam,
      defending === "home" ? "away" : "home",
      minute,
      events,
      playerAcc,
      score.home,
      score.away,
    );
  }
}

function syncSentOff(
  home: EffectiveAbilities[],
  away: EffectiveAbilities[],
  acc: Map<string, PlayerAcc>,
): void {
  for (const a of [...home, ...away]) {
    const p = acc.get(a.playerId);
    if (p?.sentOff) {
      a.sentOff = true;
      a.onPitch = false;
    }
  if (p?.substitutedOut) {
      a.onPitch = false;
    }
  }
}

function tickMinutes(
  acc: Map<string, PlayerAcc>,
  home: EffectiveAbilities[],
  away: EffectiveAbilities[],
  minutes: number,
): void {
  for (const a of [...home, ...away]) {
    if (!a.onPitch || a.sentOff || a.injuredOut) continue;
    const p = acc.get(a.playerId);
    if (!p) continue;
    p.minutesPlayed += minutes;
    p.staminaRemaining = a.staminaFraction;
    p.sprintActions += a.sprintActions;
    p.pressingActions += a.pressingActions;
  }
}

/** Light synthetic pass volume with personal passing skill. */
function addLightPassVolume(
  rng: SeededRandom,
  acc: Map<string, PlayerAcc>,
  home: EffectiveAbilities[],
  away: EffectiveAbilities[],
  config: SimulationConfig,
): void {
  for (const a of [...home, ...away]) {
    if (!a.onPitch || a.sentOff || a.injuredOut) continue;
    const p = acc.get(a.playerId);
    if (!p) continue;
    if (!rng.bool(0.4)) continue;
    const rate = personalPassSuccess(a, 0.3, config);
    p.passesAttempted += 2;
    p.passesCompleted += rng.bool(rate) ? 2 : 1;
  }
}

function pickLaneWeighted(
  rng: SeededRandom,
  att: ZoneStrength,
  def: ZoneStrength,
  weights: Record<Lane, number>,
): Lane {
  const scores = LANES.map((lane) => {
    const a = attackAxis(att, lane) - defenseAxis(def, lane) * 0.8;
    return { lane, w: Math.max(0.1, a) * (weights[lane] ?? 1) };
  });
  const total = scores.reduce((s, x) => s + x.w, 0);
  let r = rng.next() * total;
  for (const s of scores) {
    r -= s.w;
    if (r <= 0) return s.lane;
  }
  return "center";
}

function estimateXg(
  attPower: number,
  gk: number,
  config: SimulationConfig,
  finishMul: number,
  rng: SeededRandom,
  shooter?: EffectiveAbilities,
): number {
  const noise = 1 + (rng.next() - 0.5) * config.finishNoiseAmplitude;
  let raw = config.baseFinishRate *
    finishMul *
    noise *
    (0.45 + softContestShare(attPower, Math.max(1, gk), config)) *
    (1 - Math.min(0.5, gk * config.gkSaveFactor));
  if (shooter) {
    const personal = personalShotFactor(shooter, config);
    const blend = config.personalShotBlend;
    raw *= (1 - blend) + blend * personal;
  }
  return Math.max(0.03, Math.min(0.5, raw));
}

function resolveShot(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  side: Side,
  attTeam: TeamSimulationSnapshot,
  defTeam: TeamSimulationSnapshot,
  shooter: EffectiveAbilities,
  creator: EffectiveAbilities | undefined,
  defZones: ZoneStrength,
  lane: Lane,
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  shotXg: number,
  score: LiveScore,
  flavorOpts?: {
    counterAttackHint?: boolean;
    fromSetPiece?: "corner" | "free_kick";
  },
): void {
  const y = laneToY(lane, rng);
  const from = ballPosition(attackX(side, 0.78), y);
  const to = ballPosition(attackX(side, 0.95), 0.5);

  const assistId = creator && creator.playerId !== shooter.playerId
    ? creator.playerId
    : undefined;
  const styleContext = {
    primaryStyleIds: shooter.styleIds,
    secondaryStyleIds: creator?.styleIds ?? [],
  };
  const { goal: goalFlavor, shared: shotShared } = buildGoalAndShotFlavor(
    rng,
    {
      lane,
      hasAssist: !!assistId,
      counterAttackHint: flavorOpts?.counterAttackHint ?? false,
      fromSetPiece: flavorOpts?.fromSetPiece,
      primaryStyles: shooter.styleIds,
      secondaryStyles: creator?.styleIds ?? [],
      attackProgressX: 0.78,
    },
    from,
  );

  const shooterAcc = playerAcc.get(shooter.playerId);
  if (shooterAcc) shooterAcc.shots++;

  const shotEvent = makeEvent({
    minute,
    second: rng.int(0, 59),
    type: "shot",
    teamId: attTeam.clubId,
    side,
    primaryPlayerId: shooter.playerId,
    secondaryPlayerId: assistId,
    from,
    to,
    value: shotXg,
    commentaryKey: "shot",
    metadata: envelope("shot", {
      ...shotShared,
      blocked: false,
      saved: false,
      offTarget: false,
      hitPost: false,
    }, styleContext),
    currentHomeScore: score.home,
    currentAwayScore: score.away,
  });
  events.push(shotEvent);

  const onTargetRate = Math.min(
    0.72,
    config.shotOnTargetRate + shotXg * 0.3 +
      (personalShotFactor(shooter, config) - 1) * 0.15,
  );
  const onTarget = rng.bool(onTargetRate);
  if (!onTarget) {
    if (shooterAcc) shooterAcc.shotsOffTarget++;
    const hitPost = rng.bool(config.woodworkRate);
    if (shotEvent.metadata) {
      const meta = shotEvent.metadata as Record<string, unknown>;
      const payload = (meta.payload as Record<string, unknown>) ?? {};
      payload.offTarget = !hitPost;
      payload.hitPost = hitPost;
      payload.blocked = false;
      payload.saved = false;
      meta.payload = payload;
    }
    if (hitPost) {
      events.push(
        makeEvent({
          minute,
          second: rng.int(0, 59),
          type: "shot_woodwork",
          teamId: attTeam.clubId,
          side,
          primaryPlayerId: shooter.playerId,
          from,
          to,
          success: false,
          commentaryKey: "woodwork",
          metadata: envelope("shot", {
            ...shotShared,
            blocked: false,
            saved: false,
            offTarget: false,
            hitPost: true,
          }, styleContext),
          currentHomeScore: score.home,
          currentAwayScore: score.away,
        }),
      );
    }
    return;
  }

  if (shooterAcc) shooterAcc.shotsOnTarget++;
  const onTargetEvent = makeEvent({
    minute,
    second: rng.int(0, 59),
    type: "shot_on_target",
    teamId: attTeam.clubId,
    side,
    primaryPlayerId: shooter.playerId,
    from,
    to,
    success: true,
    value: shotXg,
    metadata: envelope("shot", {
      ...shotShared,
      blocked: false,
      saved: false,
      offTarget: false,
      hitPost: false,
    }, styleContext),
    currentHomeScore: score.home,
    currentAwayScore: score.away,
  });
  events.push(onTargetEvent);

  const finish = shotXg *
    (1 - Math.min(0.6, defZones.goalkeeping * config.gkSaveFactor)) *
    ((1 - config.personalShotBlend) +
      config.personalShotBlend * personalShotFactor(shooter, config));
  if (rng.bool(Math.min(0.85, finish))) {
    if (side === "home") score.home++;
    else score.away++;

    events.push(
      makeEvent({
        minute,
        second: rng.int(0, 59),
        type: "goal",
        teamId: attTeam.clubId,
        side,
        primaryPlayerId: shooter.playerId,
        secondaryPlayerId: assistId,
        from,
        to,
        success: true,
        value: shotXg,
        commentaryKey: "goal",
        metadata: envelope("goal", { ...goalFlavor }, styleContext),
        currentHomeScore: score.home,
        currentAwayScore: score.away,
      }),
    );
    if (shooterAcc) shooterAcc.goals++;
    if (assistId) {
      const c = playerAcc.get(assistId);
      if (c) c.assists++;
    }
    return;
  }

  // Prefer explicit GK from starters by assignment index
  let goalkeeperId = defTeam.starters[0]?.playerId;
  for (let i = 0; i < defTeam.starters.length; i++) {
    const asg = defTeam.assignments.find((a) => a.pitchSlot === i + 1) ??
      defTeam.assignments[i];
    if (asg && (asg.line === "gk" || asg.fitSlot === 13)) {
      goalkeeperId = defTeam.starters[i]?.playerId;
      break;
    }
  }
  goalkeeperId = goalkeeperId ?? findGoalkeeperId(defTeam);

  const markSaved = (ev: MatchEvent) => {
    if (!ev.metadata) return;
    const meta = ev.metadata as Record<string, unknown>;
    const payload = (meta.payload as Record<string, unknown>) ?? {};
    payload.saved = true;
    meta.payload = payload;
  };
  markSaved(shotEvent);
  markSaved(onTargetEvent);

  events.push(
    makeEvent({
      minute,
      second: rng.int(0, 59),
      type: "save",
      teamId: defTeam.clubId,
      side: side === "home" ? "away" : "home",
      primaryPlayerId: goalkeeperId,
      secondaryPlayerId: shooter.playerId,
      goalkeeperId,
      from: to,
      to: ballPosition(attackX(side, 0.88), y),
      success: true,
      commentaryKey: "save",
      metadata: envelope("shot", {
        ...shotShared,
        blocked: false,
        saved: true,
        offTarget: false,
        hitPost: false,
      }, styleContext),
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );
  if (goalkeeperId) {
    const g = playerAcc.get(goalkeeperId);
    if (g) g.saves++;
  }
}

function resolveSetpiece(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  side: Side,
  attTeam: TeamSimulationSnapshot,
  defTeam: TeamSimulationSnapshot,
  attAb: EffectiveAbilities[],
  defAb: EffectiveAbilities[],
  defZones: ZoneStrength,
  lane: Lane,
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  xg: { home: number; away: number },
  score: LiveScore,
): void {
  const isCorner = rng.bool(0.55);
  const type = isCorner ? "corner" : "free_kick";
  const preferredId = isCorner
    ? (attTeam.ckPlayerId ?? pickCreator(attAb, lane)?.playerId)
    : (attTeam.fkPlayerId ?? pickCreator(attAb, lane)?.playerId);
  const preferred = preferredId
    ? attAb.find((a) =>
      a.playerId === preferredId && a.onPitch && !a.sentOff && !a.injuredOut
    )
    : undefined;
  const takerId = preferred?.playerId ?? pickCreator(attAb, lane)?.playerId;

  events.push(
    makeEvent({
      minute,
      second: rng.int(0, 59),
      type,
      teamId: attTeam.clubId,
      side,
      primaryPlayerId: takerId,
      commentaryKey: type,
      metadata: isCorner
        ? envelope("corner", { ...buildCornerPayload(rng) }, {
          primaryStyleIds: preferred?.styleIds ??
            (takerId
              ? attAb.find((a) => a.playerId === takerId)?.styleIds ?? []
              : []),
        })
        : undefined,
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );

  if (takerId) {
    const takerAcc = playerAcc.get(takerId);
    if (takerAcc) {
      if (isCorner) takerAcc.cornersTaken++;
      else takerAcc.freeKicksTaken++;
    }
  }

  if (isCorner && !rng.bool(config.cornerToShotChance)) return;

  const shooter = pickAttacker(attAb, "center") ?? pickAttacker(attAb, lane);
  if (!shooter) return;

  let shotXg = estimateXg(
    attackAxis(
      computeZoneStrength(attAb, attTeam, side, config, {
        homeAdvantage: false,
        redCardCount: 0,
        scoreDiff: 0,
      }),
      "center",
    ),
    defZones.goalkeeping,
    config,
    resolveTacticMod(attTeam.tactic.coachStyle, config).finishMul,
    rng,
    shooter,
  );
  if (!isCorner) shotXg += config.freeKickOnTargetBonus * 0.5;
  // Strong setpiece taker boost
  const taker = attAb.find((a) => a.playerId === takerId);
  if (taker) shotXg *= 0.9 + taker.setpiece / 50;

  if (side === "home") xg.home += shotXg;
  else xg.away += shotXg;

  const creator = takerId
    ? attAb.find((a) => a.playerId === takerId)
    : undefined;

  resolveShot(
    rng,
    config,
    minute,
    side,
    attTeam,
    defTeam,
    shooter,
    creator,
    defZones,
    lane,
    events,
    playerAcc,
    shotXg,
    score,
    {
      counterAttackHint: false,
      fromSetPiece: isCorner ? "corner" : "free_kick",
    },
  );

  // Rare penalty
  if (rng.bool(config.penaltyChanceFromFoul)) {
    const pkPreferred = attTeam.pkPlayerId
      ? attAb.find((a) =>
        a.playerId === attTeam.pkPlayerId && a.onPitch && !a.sentOff &&
        !a.injuredOut
      )
      : undefined;
    const pkId = pkPreferred?.playerId ?? shooter.playerId;
    events.push(
      makeEvent({
        minute,
        second: rng.int(0, 59),
        type: "penalty",
        teamId: attTeam.clubId,
        side,
        primaryPlayerId: pkId,
        commentaryKey: "penalty",
        currentHomeScore: score.home,
        currentAwayScore: score.away,
      }),
    );
    const pkPlayer = attAb.find((a) => a.playerId === pkId);
    const convert = config.penaltyConvertBase +
      (pkPlayer ? pkPlayer.setpiece / 100 : 0);
    if (rng.bool(Math.min(0.95, convert))) {
      if (side === "home") score.home++;
      else score.away++;
      events.push(
        makeEvent({
          minute,
          second: rng.int(0, 59),
          type: "penalty_scored",
          teamId: attTeam.clubId,
          side,
          primaryPlayerId: pkId,
          success: true,
          commentaryKey: "penalty_goal",
          currentHomeScore: score.home,
          currentAwayScore: score.away,
        }),
      );
      const acc = playerAcc.get(pkId);
      if (acc) {
        acc.goals++;
        acc.shots++;
        acc.shotsOnTarget++;
        acc.penaltiesTaken++;
        acc.penaltiesScored++;
      }
      if (side === "home") xg.home += 0.75;
      else xg.away += 0.75;
    } else {
      events.push(
        makeEvent({
          minute,
          second: rng.int(0, 59),
          type: "penalty_missed",
          teamId: attTeam.clubId,
          side,
          primaryPlayerId: pkId,
          success: false,
          currentHomeScore: score.home,
          currentAwayScore: score.away,
        }),
      );
      const acc = playerAcc.get(pkId);
      if (acc) {
        acc.penaltiesTaken++;
        acc.penaltiesMissed++;
      }
    }
  }
  void defAb;
}

function maybeCards(
  rng: SeededRandom,
  config: SimulationConfig,
  minute: number,
  side: Side,
  team: TeamSimulationSnapshot,
  abilities: EffectiveAbilities[],
  oppAbilities: EffectiveAbilities[],
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  yellows: Map<string, number>,
  score: LiveScore,
  onRed: (side: Side) => void,
): void {
  // Occasional foul (with or without card)
  if (rng.bool(config.yellowCardPerTick * 2.5)) {
    emitFoul(
      rng,
      minute,
      side,
      team,
      abilities,
      oppAbilities,
      events,
      playerAcc,
      score,
    );
  }

  if (!rng.bool(config.yellowCardPerTick)) {
    if (rng.bool(config.straightRedChance)) {
      const pool = abilities.filter((a) =>
        a.onPitch && !a.sentOff && !a.injuredOut && a.line !== "gk"
      );
      if (pool.length === 0) return;
      const offender = rng.pick(pool);
      const foulType = emitFoulWithFouler(
        rng,
        minute,
        side,
        team,
        offender.playerId,
        oppAbilities,
        events,
        playerAcc,
        score,
      );
      issueRed(
        offender.playerId,
        side,
        team,
        minute,
        events,
        playerAcc,
        score,
        onRed,
        {
          yellowCount: yellows.get(offender.playerId) ?? 0,
          linkedFoulType: foulType,
          styles: offender.styleIds,
          rng,
        },
      );
    }
    return;
  }

  const pool = abilities.filter((a) =>
    a.onPitch && !a.sentOff && !a.injuredOut && a.line !== "gk"
  );
  if (pool.length === 0) return;
  const fouler = rng.pick(pool);

  // Foul accompanying the card
  const foulType = emitFoulWithFouler(
    rng,
    minute,
    side,
    team,
    fouler.playerId,
    oppAbilities,
    events,
    playerAcc,
    score,
  );

  const y = (yellows.get(fouler.playerId) ?? 0) + 1;
  yellows.set(fouler.playerId, y);
  const acc = playerAcc.get(fouler.playerId);
  if (acc) acc.yellowCards++;

  const cardMeta = buildCardPayload(rng, {
    isRed: false,
    yellowCount: y,
    foulsCommitted: acc?.foulsCommitted ?? 1,
    linkedFoulType: foulType,
  });

  events.push(
    makeEvent({
      minute,
      second: rng.int(0, 59),
      type: "yellow_card",
      teamId: team.clubId,
      side,
      primaryPlayerId: fouler.playerId,
      fouledPlayerId: events[events.length - 1]?.fouledPlayerId,
      commentaryKey: "yellow",
      metadata: envelope("card", { ...cardMeta }, {
        primaryStyleIds: fouler.styleIds,
      }),
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );

  if (y >= 2 && rng.bool(config.redFromYellowChance * 2)) {
    issueRed(
      fouler.playerId,
      side,
      team,
      minute,
      events,
      playerAcc,
      score,
      onRed,
      {
        yellowCount: y,
        linkedFoulType: foulType,
        styles: fouler.styleIds,
        rng,
      },
    );
  }
}

function emitFoul(
  rng: SeededRandom,
  minute: number,
  side: Side,
  team: TeamSimulationSnapshot,
  abilities: EffectiveAbilities[],
  oppAbilities: EffectiveAbilities[],
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  score: LiveScore,
): void {
  const pool = abilities.filter((a) =>
    a.onPitch && !a.sentOff && !a.injuredOut && a.line !== "gk"
  );
  if (pool.length === 0) return;
  const fouler = rng.pick(pool);
  emitFoulWithFouler(
    rng,
    minute,
    side,
    team,
    fouler.playerId,
    oppAbilities,
    events,
    playerAcc,
    score,
  );
}

function emitFoulWithFouler(
  rng: SeededRandom,
  minute: number,
  side: Side,
  team: TeamSimulationSnapshot,
  foulerId: string,
  oppAbilities: EffectiveAbilities[],
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  score: LiveScore,
): FoulType {
  const victims = oppAbilities.filter((a) =>
    a.onPitch && !a.sentOff && !a.injuredOut
  );
  const victim = victims.length > 0 ? rng.pick(victims) : undefined;
  const foulerAb = oppAbilities.find((a) => a.playerId === foulerId);
  // Fouler is on `team` side — look up from playerAcc is not enough for styles.
  // Prefer team starters/bench via a scan of all abilities passed incorrectly:
  // callers pass fouler's team abilities as first pool in emitFoul; here we only
  // have oppAbilities. Resolve styles from team snapshot.
  const foulerStyles =
    [...team.starters, ...team.bench].find((p) => p.playerId === foulerId)
      ?.styleIds ?? foulerAb?.styleIds ?? [];
  const foulPayload = buildFoulPayload(rng, foulerStyles);

  events.push(
    makeEvent({
      minute,
      second: rng.int(0, 59),
      type: "foul",
      teamId: team.clubId,
      side,
      primaryPlayerId: foulerId,
      fouledPlayerId: victim?.playerId,
      commentaryKey: "foul",
      metadata: envelope("foul", { ...foulPayload }, {
        primaryStyleIds: foulerStyles,
      }),
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );

  const foulerAcc = playerAcc.get(foulerId);
  if (foulerAcc) foulerAcc.foulsCommitted++;
  if (victim) {
    const v = playerAcc.get(victim.playerId);
    if (v) v.foulsSuffered++;
  }
  return foulPayload.foulType;
}

function issueRed(
  playerId: string,
  side: Side,
  team: TeamSimulationSnapshot,
  minute: number,
  events: MatchEvent[],
  playerAcc: Map<string, PlayerAcc>,
  score: LiveScore,
  onRed: (side: Side) => void,
  cardOpts?: {
    yellowCount: number;
    linkedFoulType?: FoulType;
    styles: string[];
    rng: SeededRandom;
  },
): void {
  const acc = playerAcc.get(playerId);
  if (acc?.sentOff) return;
  if (acc) {
    acc.redCards++;
    acc.sentOff = true;
  }
  onRed(side);
  const styles = cardOpts?.styles ??
    [...team.starters, ...team.bench].find((p) => p.playerId === playerId)
      ?.styleIds ?? [];
  const rng = cardOpts?.rng ?? new SeededRandom((minute + 1) * 9973);
  const cardMeta = buildCardPayload(rng, {
    isRed: true,
    yellowCount: cardOpts?.yellowCount ?? 0,
    linkedFoulType: cardOpts?.linkedFoulType,
  });
  // Find last fouled player if any
  const lastFoul = [...events].reverse().find((e) =>
    e.type === "foul" && e.primaryPlayerId === playerId
  );
  events.push(
    makeEvent({
      minute,
      second: 0,
      type: "red_card",
      teamId: team.clubId,
      side,
      primaryPlayerId: playerId,
      fouledPlayerId: lastFoul?.fouledPlayerId,
      commentaryKey: "red",
      metadata: envelope("card", { ...cardMeta }, {
        primaryStyleIds: styles,
      }),
      currentHomeScore: score.home,
      currentAwayScore: score.away,
    }),
  );
}
