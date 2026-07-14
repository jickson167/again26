import type { SeededRandom } from "./seeded_random.ts";
import type {
  BallPosition,
  Lane,
  MatchEvent,
  MatchEventType,
  Side,
} from "./types.ts";

/** Map normalized coords to 10×9 zone (col 0..9, row 0..8). */
export function ballPosition(x: number, y: number): BallPosition {
  const cx = Math.max(0, Math.min(1, x));
  const cy = Math.max(0, Math.min(1, y));
  const col = Math.min(9, Math.floor(cx * 10));
  const row = Math.min(8, Math.floor(cy * 9));
  return { x: cx, y: cy, zone: col + row * 10 };
}

export function laneToY(lane: Lane, rng: SeededRandom): number {
  switch (lane) {
    case "left":
      return 0.15 + rng.next() * 0.2;
    case "right":
      return 0.65 + rng.next() * 0.2;
    default:
      return 0.4 + rng.next() * 0.2;
  }
}

/** Attacking X for side: home attacks toward x→1, away toward x→0. */
export function attackX(side: Side, depth: number): number {
  const d = Math.max(0, Math.min(1, depth));
  return side === "home" ? d : 1 - d;
}

export function makeEvent(partial: {
  minute: number;
  second?: number;
  type: MatchEventType;
  teamId: string;
  side: Side;
  primaryPlayerId?: string;
  secondaryPlayerId?: string;
  goalkeeperId?: string;
  fouledPlayerId?: string;
  substitutedOutPlayerId?: string;
  substitutedInPlayerId?: string;
  from?: BallPosition;
  to?: BallPosition;
  success?: boolean;
  value?: number;
  commentaryKey?: string;
  metadata?: Record<string, unknown>;
  currentHomeScore?: number;
  currentAwayScore?: number;
}): MatchEvent {
  return {
    matchMinute: partial.minute,
    matchSecond: partial.second ?? 0,
    type: partial.type,
    teamId: partial.teamId,
    side: partial.side,
    primaryPlayerId: partial.primaryPlayerId,
    secondaryPlayerId: partial.secondaryPlayerId,
    goalkeeperId: partial.goalkeeperId,
    fouledPlayerId: partial.fouledPlayerId,
    substitutedOutPlayerId: partial.substitutedOutPlayerId,
    substitutedInPlayerId: partial.substitutedInPlayerId,
    startPosition: partial.from,
    endPosition: partial.to,
    success: partial.success,
    value: partial.value,
    commentaryKey: partial.commentaryKey,
    metadata: partial.metadata,
    currentHomeScore: partial.currentHomeScore ?? 0,
    currentAwayScore: partial.currentAwayScore ?? 0,
  };
}

export function progressionEvent(
  rng: SeededRandom,
  minute: number,
  teamId: string,
  side: Side,
  lane: Lane,
  depthFrom: number,
  depthTo: number,
  currentHomeScore = 0,
  currentAwayScore = 0,
): MatchEvent {
  const y = laneToY(lane, rng);
  return makeEvent({
    minute,
    second: rng.int(0, 59),
    type: "progression",
    teamId,
    side,
    from: ballPosition(attackX(side, depthFrom), y),
    to: ballPosition(attackX(side, depthTo), y + (rng.next() - 0.5) * 0.1),
    success: true,
    commentaryKey: "bg_progression",
    metadata: { durationMs: 1500 + rng.int(0, 1500), lane },
    currentHomeScore,
    currentAwayScore,
  });
}
