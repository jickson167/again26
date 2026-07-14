/** Typed MatchEvent.metadata builders — commentary flavor only (no win-rate change). */

import type { BallPosition, Lane } from "./types.ts";
import type { SeededRandom } from "./seeded_random.ts";

export type EventMetaKind =
  | "goal"
  | "shot"
  | "pass"
  | "foul"
  | "card"
  | "dribble"
  | "header"
  | "corner"
  | "injury"
  | "substitution"
  | "attack_build";

export type Foot = "left" | "right" | "both";
export type ShotType =
  | "power"
  | "placement"
  | "curler"
  | "chip"
  | "volley"
  | "header"
  | "tapin"
  | "outside_foot";
export type ShotDistance = "inside_box" | "outside_box" | "long_range";
export type BodyPart = "foot" | "head" | "other";
export type AssistType =
  | "through"
  | "cross"
  | "cutback"
  | "rebound"
  | "corner"
  | "freekick";
export type FoulType =
  | "hold"
  | "push"
  | "late_tackle"
  | "sliding"
  | "trip"
  | "handball"
  | "dangerous_play";
export type CardReason =
  | "foul_accumulation"
  | "serious_foul"
  | "dissent"
  | "professional_foul"
  | "second_yellow"
  | "violent_conduct";
export type PassType = "short" | "through" | "cross" | "long" | "cutback";
export type HeaderStyle = "standing" | "diving";
export type CornerSide = "near" | "far";

export interface StyleContext {
  primaryStyleIds: string[];
  secondaryStyleIds?: string[];
}

export interface EventMetadataEnvelope {
  schemaVersion: 1;
  kind: EventMetaKind;
  payload: Record<string, unknown>;
  styleContext?: StyleContext;
}

export interface GoalPayload {
  foot?: Foot;
  shotType: ShotType;
  distance: ShotDistance;
  bodyPart: BodyPart;
  afterDribble: boolean;
  defendersBeaten: 0 | 1 | 2 | 3;
  keeperTouched: boolean;
  assistType?: AssistType;
  counterAttack: boolean;
  oneOnOne: boolean;
}

export interface ShotPayload {
  foot?: Foot;
  shotType: ShotType;
  distance: ShotDistance;
  bodyPart: BodyPart;
  blocked: boolean;
  saved: boolean;
  offTarget: boolean;
  hitPost: boolean;
  afterDribble: boolean;
  defendersBeaten: 0 | 1 | 2 | 3;
  counterAttack: boolean;
  oneOnOne: boolean;
  assistType?: AssistType;
}

export interface FoulPayload {
  foulType: FoulType;
}

export interface CardPayload {
  reason: CardReason;
  linkedFoulType?: FoulType;
}

export interface CornerPayload {
  cornerSide: CornerSide;
}

export interface ShotFlavorContext {
  lane: Lane;
  hasAssist: boolean;
  counterAttackHint: boolean;
  fromSetPiece?: "corner" | "free_kick";
  primaryStyles: string[];
  secondaryStyles: string[];
  /** Relative pitch X of shot origin in attacking direction (0..1), if known */
  attackProgressX?: number;
}

function hasStyle(styles: string[], id: string): boolean {
  return styles.includes(id);
}

function weightPick<T>(
  rng: SeededRandom,
  items: ReadonlyArray<{ value: T; w: number }>,
): T {
  let total = 0;
  for (const it of items) total += Math.max(0, it.w);
  if (total <= 0) return items[0]!.value;
  let r = rng.next() * total;
  for (const it of items) {
    r -= Math.max(0, it.w);
    if (r <= 0) return it.value;
  }
  return items[items.length - 1]!.value;
}

export function distanceFromPosition(
  from: BallPosition | undefined,
  attackProgressX?: number,
): ShotDistance {
  const x = attackProgressX ?? from?.x ?? 0.78;
  // Engine uses absolute pitch x; attackProgressX preferred when provided.
  const progress = attackProgressX ?? (x > 0.5 ? x : 1 - x);
  if (progress >= 0.82) return "inside_box";
  if (progress >= 0.68) return "outside_box";
  return "long_range";
}

function pickShotType(
  rng: SeededRandom,
  distance: ShotDistance,
  styles: string[],
  lane: Lane,
): ShotType {
  const w: { value: ShotType; w: number }[] = [
    { value: "power", w: 1.2 },
    { value: "placement", w: 1.4 },
    { value: "curler", w: 0.9 },
    { value: "chip", w: 0.35 },
    { value: "volley", w: 0.4 },
    { value: "header", w: lane !== "center" ? 0.9 : 0.55 },
    { value: "tapin", w: distance === "inside_box" ? 1.1 : 0.05 },
    { value: "outside_foot", w: 0.35 },
  ];

  if (hasStyle(styles, "finisher") || hasStyle(styles, "poacher")) {
    bump(w, "tapin", 1.2);
    bump(w, "placement", 0.8);
  }
  if (hasStyle(styles, "target_man") || hasStyle(styles, "aerial_defender")) {
    bump(w, "header", 1.5);
  }
  if (hasStyle(styles, "technical") || hasStyle(styles, "dribbler")) {
    bump(w, "curler", 0.6);
    bump(w, "outside_foot", 0.4);
    bump(w, "chip", 0.25);
  }
  if (hasStyle(styles, "physical")) {
    bump(w, "power", 0.8);
    bump(w, "header", 0.4);
  }

  if (distance === "long_range") {
    bump(w, "power", 1.0);
    bump(w, "curler", 0.8);
    bump(w, "tapin", -10);
    bump(w, "header", -0.4);
  } else if (distance === "outside_box") {
    bump(w, "tapin", -5);
  } else {
    bump(w, "chip", 0.15);
  }

  return weightPick(rng, w.filter((x) => x.w > 0));
}

function bump<T>(
  items: { value: T; w: number }[],
  value: T,
  delta: number,
): void {
  const found = items.find((i) => i.value === value);
  if (found) found.w = Math.max(0, found.w + delta);
}

function pickFoot(rng: SeededRandom, shotType: ShotType, styles: string[]): Foot | undefined {
  if (shotType === "header") return undefined;
  // Always left or right for natural commentary (never "both")
  const rightBias =
    hasStyle(styles, "technical") || hasStyle(styles, "balanced")
      ? 0.55
      : 0.62;
  return rng.bool(rightBias) ? "right" : "left";
}

function pickAssistType(
  rng: SeededRandom,
  lane: Lane,
  stylesPrimary: string[],
  stylesSecondary: string[],
  fromSetPiece?: "corner" | "free_kick",
): AssistType {
  if (fromSetPiece === "corner") return "corner";
  if (fromSetPiece === "free_kick") {
    return rng.bool(0.7) ? "freekick" : "cross";
  }

  const w: { value: AssistType; w: number }[] = [
    { value: "through", w: 1.2 },
    { value: "cross", w: lane === "center" ? 0.6 : 1.4 },
    { value: "cutback", w: 0.7 },
    { value: "rebound", w: 0.35 },
    { value: "corner", w: 0.05 },
    { value: "freekick", w: 0.05 },
  ];

  if (
    hasStyle(stylesSecondary, "playmaker") ||
    hasStyle(stylesSecondary, "creative_midfielder") ||
    hasStyle(stylesSecondary, "deep_lying_playmaker")
  ) {
    bump(w, "through", 1.2);
    bump(w, "cutback", 0.4);
  }
  if (
    hasStyle(stylesSecondary, "speed_winger") ||
    hasStyle(stylesSecondary, "attacking_fullback") ||
    hasStyle(stylesPrimary, "target_man")
  ) {
    bump(w, "cross", 1.0);
  }
  if (hasStyle(stylesSecondary, "setpiece")) {
    bump(w, "corner", 0.4);
    bump(w, "freekick", 0.4);
  }

  return weightPick(rng, w.filter((x) => x.w > 0));
}

function sanitizeGoal(
  payload: GoalPayload,
  hasAssist: boolean,
): GoalPayload {
  let { shotType, distance, assistType, foot, bodyPart } = payload;

  if (shotType === "tapin" && distance === "long_range") {
    shotType = "power";
  }
  if (shotType === "header") {
    bodyPart = "head";
    foot = undefined;
  } else {
    bodyPart = "foot";
  }
  if (shotType === "header" && assistType === "through" && hasAssist) {
    // Headers usually from crosses/corners/fk
    assistType = "cross";
  }
  if (!hasAssist) {
    assistType = undefined;
  }

  return { ...payload, shotType, distance, assistType, foot, bodyPart };
}

export function buildGoalAndShotFlavor(
  rng: SeededRandom,
  ctx: ShotFlavorContext,
  from?: BallPosition,
): { goal: GoalPayload; shared: Omit<ShotPayload, "blocked" | "saved" | "offTarget" | "hitPost"> } {
  const distance = distanceFromPosition(from, ctx.attackProgressX ?? 0.78);
  let shotType = pickShotType(rng, distance, ctx.primaryStyles, ctx.lane);

  // Cross assist strongly prefers header / volley / tapin
  let assistType: AssistType | undefined;
  if (ctx.hasAssist) {
    assistType = pickAssistType(
      rng,
      ctx.lane,
      ctx.primaryStyles,
      ctx.secondaryStyles,
      ctx.fromSetPiece,
    );
    if (assistType === "cross" || assistType === "corner") {
      if (rng.bool(0.55)) shotType = "header";
      else if (rng.bool(0.35)) shotType = "volley";
      else shotType = "tapin";
    }
    if (assistType === "cutback") {
      shotType = rng.bool(0.7) ? "tapin" : "placement";
    }
    if (assistType === "through") {
      shotType = weightPick(rng, [
        { value: "placement" as ShotType, w: 1.4 },
        { value: "chip" as ShotType, w: 0.5 },
        { value: "power" as ShotType, w: 0.6 },
        { value: "tapin" as ShotType, w: 0.4 },
      ]);
    }
  }

  const afterDribbleBase =
    hasStyle(ctx.primaryStyles, "dribbler") ||
    hasStyle(ctx.primaryStyles, "speed_winger")
      ? 0.45
      : 0.18;
  const afterDribble = rng.bool(afterDribbleBase);

  let defendersBeaten: 0 | 1 | 2 | 3 = 0;
  if (afterDribble) {
    const maxBeat = hasStyle(ctx.primaryStyles, "dribbler") ? 3 : 2;
    defendersBeaten = rng.int(1, maxBeat) as 0 | 1 | 2 | 3;
  }

  const oneOnOne =
    ctx.hasAssist && assistType === "through"
      ? rng.bool(0.55)
      : rng.bool(
        hasStyle(ctx.primaryStyles, "counter_attacker") ||
            hasStyle(ctx.primaryStyles, "poacher")
          ? 0.35
          : 0.12,
      );

  const counterAttack =
    ctx.counterAttackHint ||
    rng.bool(
      hasStyle(ctx.primaryStyles, "counter_attacker") ? 0.4 : 0.12,
    );

  const foot = pickFoot(rng, shotType, ctx.primaryStyles);
  const bodyPart: BodyPart = shotType === "header" ? "head" : "foot";
  const keeperTouched = rng.bool(0.12);

  const goal = sanitizeGoal(
    {
      foot,
      shotType,
      distance,
      bodyPart,
      afterDribble,
      defendersBeaten,
      keeperTouched,
      assistType,
      counterAttack,
      oneOnOne,
    },
    ctx.hasAssist,
  );

  return {
    goal,
    shared: {
      foot: goal.foot,
      shotType: goal.shotType,
      distance: goal.distance,
      bodyPart: goal.bodyPart,
      afterDribble: goal.afterDribble,
      defendersBeaten: goal.defendersBeaten,
      counterAttack: goal.counterAttack,
      oneOnOne: goal.oneOnOne,
      assistType: goal.assistType,
    },
  };
}

export function envelope(
  kind: EventMetaKind,
  payload: Record<string, unknown>,
  styleContext?: StyleContext,
): Record<string, unknown> {
  const out: Record<string, unknown> = {
    schemaVersion: 1,
    kind,
    payload,
  };
  if (styleContext) out.styleContext = styleContext;
  return out;
}

export function buildFoulPayload(rng: SeededRandom, styles: string[]): FoulPayload {
  const w: { value: FoulType; w: number }[] = [
    { value: "hold", w: 1.0 },
    { value: "push", w: 1.0 },
    { value: "late_tackle", w: 0.9 },
    { value: "sliding", w: 0.8 },
    { value: "trip", w: 1.1 },
    { value: "handball", w: 0.25 },
    { value: "dangerous_play", w: 0.35 },
  ];
  if (hasStyle(styles, "pressing") || hasStyle(styles, "ball_winner") ||
    hasStyle(styles, "pressing_midfielder") || hasStyle(styles, "stopper")) {
    bump(w, "late_tackle", 0.5);
    bump(w, "sliding", 0.4);
  }
  if (hasStyle(styles, "physical") || hasStyle(styles, "physical_cb")) {
    bump(w, "push", 0.4);
    bump(w, "hold", 0.3);
  }
  return { foulType: weightPick(rng, w) };
}

export function buildCardPayload(
  rng: SeededRandom,
  opts: {
    isRed: boolean;
    yellowCount: number;
    /** Fouls by this player so far in the match (incl. the linked foul). */
    foulsCommitted?: number;
    linkedFoulType?: FoulType;
  },
): CardPayload {
  if (opts.isRed) {
    if (opts.yellowCount >= 2) {
      return { reason: "second_yellow", linkedFoulType: opts.linkedFoulType };
    }
    const w: { value: CardReason; w: number }[] = [
      { value: "serious_foul", w: 1.4 },
      { value: "professional_foul", w: 0.8 },
      { value: "violent_conduct", w: 0.35 },
    ];
    return {
      reason: weightPick(rng, w),
      linkedFoulType: opts.linkedFoulType,
    };
  }
  // Yellow: describe THIS booking. "거듭된 파울" only when the player
  // has actually fouled multiple times (not on the first foul of the match).
  const w: { value: CardReason; w: number }[] = [
    { value: "serious_foul", w: 1.0 },
    { value: "dissent", w: 0.35 },
    { value: "professional_foul", w: 0.45 },
  ];
  if ((opts.foulsCommitted ?? 0) >= 3) {
    w.push({ value: "foul_accumulation", w: 1.0 });
  }
  return {
    reason: weightPick(rng, w),
    linkedFoulType: opts.linkedFoulType,
  };
}

export function buildCornerPayload(rng: SeededRandom): CornerPayload {
  return { cornerSide: rng.bool(0.55) ? "near" : "far" };
}
