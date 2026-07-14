/** Match engine shared types — pure data, no I/O. */

export type Side = "home" | "away";

export type Lane = "left" | "center" | "right";
export type PitchLine = "attack" | "midfield" | "defense" | "gk";

export type FormationType = "P" | "S" | "T";

export type SubstitutionReason =
  | "fatigue"
  | "tactical_attack"
  | "tactical_defense"
  | "yellow_card_risk"
  | "injury"
  | "poor_performance";

export type InjurySeverity = "mild" | "moderate" | "severe";

export type MatchEventType =
  | "progression"
  | "possession_change"
  | "attack"
  | "attack_build"
  | "key_pass"
  | "through_ball"
  | "dribble"
  | "cross"
  | "shot"
  | "shot_on_target"
  | "shot_saved"
  | "save"
  | "shot_woodwork"
  | "post"
  | "goal"
  | "foul"
  | "yellow_card"
  | "red_card"
  | "injury"
  | "substitution"
  | "offside"
  | "free_kick"
  | "corner"
  | "penalty"
  | "penalty_scored"
  | "penalty_missed"
  | "penalty_miss"
  | "halftime"
  | "fulltime"
  | "duel"
  | "aerial_duel"
  | "tackle";

export interface BallPosition {
  x: number;
  y: number;
  zone?: number;
}

export interface PositionAssignment {
  pitchSlot: number;
  fitSlot: number;
  lane: Lane;
  line: PitchLine;
}

export interface KeyPositionRef {
  id: string;
  slot: number;
}

export interface PlayerSimulationSnapshot {
  playerId: string;
  /** Club-owned instance id when available (club_players.id). */
  userPlayerId?: string;
  name?: string;
  speed: number;
  power: number;
  technique: number;
  shooting: number;
  passing: number;
  stamina: number;
  pkAbility: number;
  fkAbility: number;
  ckAbility: number;
  leadership: number;
  assignedFit: number;
  positionFits?: Record<number, number>;
  staminaFraction?: number;
  /** Player style ids from DB (commentary / metadata flavor only). */
  styleIds?: string[];
}

export interface TacticalSnapshot {
  possession: number;
  attack: number;
  stability: number;
  lineHeight: number;
  coachStyle: string;
}

export interface TeamSimulationSnapshot {
  clubId: string;
  clubName?: string;
  formationName?: string;
  /** P / S / T from formations.csv */
  formationType?: FormationType | string;
  tactic: TacticalSnapshot;
  starters: PlayerSimulationSnapshot[];
  bench: PlayerSimulationSnapshot[];
  assignments: PositionAssignment[];
  keyPositions?: KeyPositionRef[];
  pkPlayerId?: string;
  fkPlayerId?: string;
  ckPlayerId?: string;
  captainPlayerId?: string;
}

export interface MatchSimulationInput {
  matchId: string;
  seed: number;
  simulationVersion: string;
  home: TeamSimulationSnapshot;
  away: TeamSimulationSnapshot;
  homeAdvantage?: boolean;
}

export interface MatchEvent {
  matchMinute: number;
  matchSecond: number;
  type: MatchEventType;
  teamId: string;
  side: Side;
  primaryPlayerId?: string;
  secondaryPlayerId?: string;
  goalkeeperId?: string;
  fouledPlayerId?: string;
  substitutedOutPlayerId?: string;
  substitutedInPlayerId?: string;
  startPosition?: BallPosition;
  endPosition?: BallPosition;
  success?: boolean;
  value?: number;
  commentaryKey?: string;
  metadata?: Record<string, unknown>;
  currentHomeScore: number;
  currentAwayScore: number;
}

/** Per-player match sheet — team stats must sum from these (except possession/xG). */
export interface PlayerMatchStats {
  playerId: string;
  userPlayerId?: string;
  teamId: string;
  side: Side;
  name?: string;
  started: boolean;
  substitutedIn: boolean;
  substitutedOut: boolean;
  minutesPlayed: number;
  position: string;
  positionFit: number;
  rating: number;

  goals: number;
  assists: number;
  shots: number;
  shotsOnTarget: number;
  shotsOffTarget: number;
  shotsBlocked: number;
  keyPasses: number;
  passesAttempted: number;
  passesCompleted: number;
  crossesAttempted: number;
  crossesCompleted: number;
  dribblesAttempted: number;
  dribblesCompleted: number;
  offsides: number;

  cornersTaken: number;
  freeKicksTaken: number;
  penaltiesTaken: number;
  penaltiesScored: number;
  penaltiesMissed: number;

  duelsAttempted: number;
  duelsWon: number;
  aerialDuelsAttempted: number;
  aerialDuelsWon: number;
  tacklesAttempted: number;
  tacklesWon: number;
  interceptions: number;
  clearances: number;
  blocks: number;
  saves: number;
  goalsConceded: number;

  foulsCommitted: number;
  foulsSuffered: number;
  yellowCards: number;
  redCards: number;
  injuries: number;
  injuryOccurred: boolean;
  staminaUsed: number;
  staminaRemaining: number;
  fatigueAtSubstitution?: number;
  substitutionReason?: SubstitutionReason;
  sprintActions: number;
  pressingActions: number;
  sentOff: boolean;
}

/** @deprecated Use PlayerMatchStats — kept as alias for older imports. */
export type PlayerMatchResult = PlayerMatchStats;

export interface MatchStatistics {
  homePossession: number;
  awayPossession: number;
  homeShots: number;
  awayShots: number;
  homeShotsOnTarget: number;
  awayShotsOnTarget: number;
  homeGoals: number;
  awayGoals: number;
  homeAssists: number;
  awayAssists: number;
  homeCorners: number;
  awayCorners: number;
  homeFreeKicks: number;
  awayFreeKicks: number;
  homeOffsides: number;
  awayOffsides: number;
  homeFouls: number;
  awayFouls: number;
  homeYellowCards: number;
  awayYellowCards: number;
  homeRedCards: number;
  awayRedCards: number;
  homeSaves: number;
  awaySaves: number;
  homePassesAttempted: number;
  awayPassesAttempted: number;
  homePassesCompleted: number;
  awayPassesCompleted: number;
  homePassCompletionRate: number;
  awayPassCompletionRate: number;
  homeExpectedGoals: number;
  awayExpectedGoals: number;
}

export interface MatchSimulationResult {
  matchId: string;
  seed: number;
  simulationVersion: string;
  homeScore: number;
  awayScore: number;
  homeClubId: string;
  awayClubId: string;
  homeClubName?: string;
  awayClubName?: string;
  events: MatchEvent[];
  statistics: MatchStatistics;
  /** Canonical player sheets */
  playerMatchStats: PlayerMatchStats[];
  /** Alias of playerMatchStats for older callers */
  playerResults: PlayerMatchStats[];
  mvpPlayerId?: string;
}

export interface EffectiveAbilities {
  playerId: string;
  attack: number;
  creation: number;
  midfield: number;
  press: number;
  defense: number;
  aerial: number;
  setpiece: number;
  goalkeeping: number;
  physical: number;
  /** Runtime remaining stamina 0..1 */
  staminaFraction: number;
  /** 1 - staminaFraction (synced) */
  fatigue: number;
  sentOff: boolean;
  /** On pitch and eligible for events */
  onPitch: boolean;
  injuredOut: boolean;
  fitSlot: number;
  pitchSlot: number;
  lane: Lane;
  line: PitchLine;
  /** Raw clamped stats for event resolution */
  speed: number;
  power: number;
  technique: number;
  shooting: number;
  passing: number;
  staminaStat: number;
  leadership: number;
  /** Activity counters for differential drain */
  sprintActions: number;
  pressingActions: number;
  tackleActions: number;
  duelActions: number;
  attackInvolvements: number;
  /** Copied from snapshot — metadata weighting only. */
  styleIds: string[];
}

export interface ZoneStrength {
  leftAttack: number;
  centerAttack: number;
  rightAttack: number;
  leftMid: number;
  centerMid: number;
  rightMid: number;
  leftDefense: number;
  centerDefense: number;
  rightDefense: number;
  goalkeeping: number;
}

export function emptyPlayerMatchStats(
  partial: Pick<
    PlayerMatchStats,
    "playerId" | "teamId" | "side" | "started" | "position" | "positionFit"
  > & { userPlayerId?: string; name?: string },
): PlayerMatchStats {
  return {
    playerId: partial.playerId,
    userPlayerId: partial.userPlayerId,
    teamId: partial.teamId,
    side: partial.side,
    name: partial.name,
    started: partial.started,
    substitutedIn: false,
    substitutedOut: false,
    minutesPlayed: 0,
    position: partial.position,
    positionFit: partial.positionFit,
    rating: 6.0,
    goals: 0,
    assists: 0,
    shots: 0,
    shotsOnTarget: 0,
    shotsOffTarget: 0,
    shotsBlocked: 0,
    keyPasses: 0,
    passesAttempted: 0,
    passesCompleted: 0,
    crossesAttempted: 0,
    crossesCompleted: 0,
    dribblesAttempted: 0,
    dribblesCompleted: 0,
    offsides: 0,
    cornersTaken: 0,
    freeKicksTaken: 0,
    penaltiesTaken: 0,
    penaltiesScored: 0,
    penaltiesMissed: 0,
    duelsAttempted: 0,
    duelsWon: 0,
    aerialDuelsAttempted: 0,
    aerialDuelsWon: 0,
    tacklesAttempted: 0,
    tacklesWon: 0,
    interceptions: 0,
    clearances: 0,
    blocks: 0,
    saves: 0,
    goalsConceded: 0,
    foulsCommitted: 0,
    foulsSuffered: 0,
    yellowCards: 0,
    redCards: 0,
    injuries: 0,
    injuryOccurred: false,
    staminaUsed: 0,
    staminaRemaining: 1,
    sprintActions: 0,
    pressingActions: 0,
    sentOff: false,
  };
}
