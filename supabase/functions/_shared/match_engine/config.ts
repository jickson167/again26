/** All balance knobs live here — do not hardcode multipliers elsewhere. */

export interface ZoneMul {
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

export interface TacticStyleMod {
  zones: Partial<ZoneMul>;
  chanceMul: number;
  finishMul: number;
  possessionBias: number;
  staminaDrainExtra: number;
  counterMul: number;
}

/** Per-event raw ability weights (normalized conceptually to ~1). */
export interface EventAbilityWeights {
  speed: number;
  power: number;
  technique: number;
  shooting: number;
  passing: number;
  stamina: number;
  leadership: number;
  fatiguePenalty: number;
}

export interface FormationTypeMod {
  pressMul: number;
  transitionMul: number;
  possessionMul: number;
  staminaDrainMul: number;
  /** Synergy weight for matching player stats (0..1 applied softly). */
  synergyWeight: number;
}

export interface SimulationConfig {
  simulationVersion: string;

  positionFitMultiplier: Record<number, number>;
  positionFitFallback: number;

  keyStatFitBlend: number;
  physicalFitBlend: number;

  attackWeights: StatWeights;
  creationWeights: StatWeights;
  midfieldWeights: StatWeights;
  pressWeights: StatWeights;
  defenseWeights: StatWeights;
  aerialWeights: StatWeights;
  setpieceWeights: StatWeights;
  goalkeepingWeights: StatWeights;

  homeAdvantageAttack: number;
  homeAdvantageMid: number;
  homeAttackChanceMul: number;
  awayAttackChanceMul: number;

  matchMinutes: number;
  tickMinutes: number;

  baseChancePerTick: number;
  lateGameChanceBoost: number;
  trailingAttackBoost: number;
  leadingTempoDrop: number;
  twoGoalLeadTempoMul: number;
  highScoringDampMul: number;
  redCardStrengthPenalty: number;
  lowStaminaDefensePenalty: number;

  abilityCompressionExponent: number;
  contestSoftness: number;
  underdogFloor: number;
  finishNoiseAmplitude: number;
  maxBreakChance: number;
  maxTickChance: number;

  shotOnTargetRate: number;
  baseFinishRate: number;
  gkSaveFactor: number;
  woodworkRate: number;

  yellowCardPerTick: number;
  redFromYellowChance: number;
  straightRedChance: number;

  progressionEventsPerTick: number;
  setpieceChanceOnFailedAttack: number;
  /** Minutes [0, until) use reduced setpiece chance. */
  earlySetpieceUntilMinute: number;
  /** Multiplier applied to setpiece chance before earlySetpieceUntilMinute. */
  earlySetpieceChanceMul: number;
  cornerToShotChance: number;
  freeKickOnTargetBonus: number;
  penaltyChanceFromFoul: number;
  penaltyConvertBase: number;

  staminaDrainPerTick: number;
  /** Floor for staminaFraction. */
  staminaFloor: number;
  /** High stamina stat reduces drain: drain *= 1 - (stat/10)*this */
  staminaStatDrainRelief: number;
  /** Role drain multipliers by fitSlot. */
  roleDrainMul: Record<number, number>;
  /** Extra drain when trailing after minute 45. */
  trailingDrainMul: number;
  /** Extra drain per red-card disadvantage. */
  redCardDrainMul: number;
  /** Fatigue performance curve thresholds & multipliers. */
  fatigueIgnoreAbove: number;
  fatigueMildAbove: number;
  fatigueSevereBelow: number;
  fatigueMildMul: number;
  fatigueModerateMul: number;
  fatigueSevereMul: number;
  /** Late-game fatigue curve steepness (>1 = steeper after half). */
  lateFatigueCurve: number;

  /** Event-level ability weights. */
  shotAbilityWeights: EventAbilityWeights;
  passAbilityWeights: EventAbilityWeights;
  dribbleAbilityWeights: EventAbilityWeights;
  duelAbilityWeights: EventAbilityWeights;
  aerialAbilityWeights: EventAbilityWeights;
  tackleAbilityWeights: EventAbilityWeights;
  /** Blend of zone xG vs personal shooting skill (0=zone only, 1=personal). */
  personalShotBlend: number;
  /** Chance each successful attack tick spawns a ground duel. */
  duelChancePerAttack: number;
  aerialChancePerAttack: number;
  tackleChanceOnDefend: number;
  /** Aggressive collision foul bias from attacker power (small). */
  aggressiveFoulPowerFactor: number;

  maxSubstitutions: number;
  subWindowStart: number;
  subWindowEnd: number;
  subFatigueThreshold: number;
  subEarlyFatigueThreshold: number;
  subPoorRatingThreshold: number;
  subBaseChancePerTick: number;

  injuryBaseChance: number;
  injuryFatigueFactor: number;
  injuryLateFactor: number;
  injuryPowerFactor: number;
  injuryVictimPowerRelief: number;
  injuryModerateShare: number;
  injurySevereShare: number;

  formationMatchupCap: number;
  keyPosBonusCap: number;
  keyPosWeaknessFloor: number;
  formationTypeMods: Record<string, FormationTypeMod>;
  /** Soft tactic slider extras beyond zone mul. */
  tacticPossessionExtra: number;
  tacticAttackChanceExtra: number;
  tacticStabilityDefenseExtra: number;
  /** 4-2-4 only becomes fully aggressive when trailing. */
  allOutAttackTrailingBoost: number;

  formationModifiers: Record<string, Partial<ZoneMul>>;
  tacticStyleModifiers: Record<string, TacticStyleMod>;

  ratingBase: number;
  ratingGoal: number;
  ratingAssist: number;
  ratingSave: number;
  ratingCardPenalty: number;
}

export interface StatWeights {
  speed: number;
  power: number;
  technique: number;
  shooting: number;
  passing: number;
  stamina: number;
  leadership?: number;
  pkAbility?: number;
  fkAbility?: number;
  ckAbility?: number;
}

const IDENTITY_ZONE: ZoneMul = {
  leftAttack: 1,
  centerAttack: 1,
  rightAttack: 1,
  leftMid: 1,
  centerMid: 1,
  rightMid: 1,
  leftDefense: 1,
  centerDefense: 1,
  rightDefense: 1,
  goalkeeping: 1,
};

const defaultEventWeights = (
  partial: Partial<EventAbilityWeights>,
): EventAbilityWeights => ({
  speed: 0,
  power: 0,
  technique: 0,
  shooting: 0,
  passing: 0,
  stamina: 0,
  leadership: 0,
  fatiguePenalty: 0.35,
  ...partial,
});

/** Default role drain: wingbacks / B2B high, CB/GK low. Keys = fitSlot. */
const DEFAULT_ROLE_DRAIN: Record<number, number> = {
  1: 1.15, // LW
  2: 1.05, // ST
  3: 1.15, // RW
  4: 1.2, // LM / wing mid
  5: 1.18, // CAM / B2B-ish
  6: 1.2, // RM
  7: 1.25, // LB / LWB activity
  8: 1.22, // CDM press
  9: 1.25, // RB
  10: 1.35, // LWB
  11: 0.82, // CB
  12: 1.35, // RWB
  13: 0.55, // GK
};

export const DEFAULT_SIMULATION_CONFIG: SimulationConfig = {
  simulationVersion: "4",

  positionFitMultiplier: {
    1: 0.45,
    2: 0.61,
    3: 0.74,
    4: 0.84,
    5: 0.91,
    6: 0.96,
    7: 1.0,
  },
  positionFitFallback: 0.74,

  keyStatFitBlend: 0.85,
  physicalFitBlend: 0.25,

  attackWeights: {
    shooting: 0.3,
    speed: 0.18,
    power: 0.15,
    technique: 0.12,
    stamina: 0.1,
    passing: 0.07,
    leadership: 0.08,
  },
  creationWeights: {
    passing: 0.28,
    technique: 0.22,
    leadership: 0.15,
    shooting: 0.1,
    speed: 0.1,
    stamina: 0.08,
    power: 0.07,
  },
  midfieldWeights: {
    passing: 0.24,
    technique: 0.18,
    stamina: 0.17,
    leadership: 0.15,
    power: 0.08,
    speed: 0.06,
    shooting: 0.12,
  },
  pressWeights: {
    stamina: 0.28,
    speed: 0.22,
    power: 0.18,
    technique: 0.12,
    leadership: 0.1,
    passing: 0.05,
    shooting: 0.05,
  },
  defenseWeights: {
    power: 0.22,
    technique: 0.18,
    stamina: 0.16,
    leadership: 0.14,
    speed: 0.12,
    passing: 0.1,
    shooting: 0.08,
  },
  aerialWeights: {
    power: 0.4,
    stamina: 0.15,
    leadership: 0.15,
    technique: 0.15,
    speed: 0.1,
    shooting: 0.05,
    passing: 0.0,
  },
  setpieceWeights: {
    fkAbility: 0.35,
    ckAbility: 0.25,
    pkAbility: 0.2,
    technique: 0.1,
    shooting: 0.1,
    speed: 0,
    power: 0,
    passing: 0,
    stamina: 0,
  },
  goalkeepingWeights: {
    technique: 0.25,
    power: 0.2,
    speed: 0.15,
    leadership: 0.15,
    stamina: 0.1,
    passing: 0.1,
    shooting: 0.05,
  },

  homeAdvantageAttack: 1.08,
  homeAdvantageMid: 1.05,
  homeAttackChanceMul: 1.24,
  awayAttackChanceMul: 0.92,

  matchMinutes: 90,
  tickMinutes: 1,

  baseChancePerTick: 0.21,
  lateGameChanceBoost: 1.1,
  trailingAttackBoost: 1.22,
  leadingTempoDrop: 0.85,
  twoGoalLeadTempoMul: 0.7,
  highScoringDampMul: 0.55,
  redCardStrengthPenalty: 0.86,
  lowStaminaDefensePenalty: 0.92,

  abilityCompressionExponent: 0.61,
  contestSoftness: 0.7,
  underdogFloor: 0.22,
  finishNoiseAmplitude: 0.16,
  maxBreakChance: 0.72,
  maxTickChance: 0.46,

  shotOnTargetRate: 0.39,
  baseFinishRate: 0.318,
  gkSaveFactor: 0.04,
  woodworkRate: 0.05,

  yellowCardPerTick: 0.014,
  redFromYellowChance: 0.11,
  straightRedChance: 0.0012,

  progressionEventsPerTick: 1,
  setpieceChanceOnFailedAttack: 0.13,
  earlySetpieceUntilMinute: 5,
  earlySetpieceChanceMul: 0.25,
  cornerToShotChance: 0.34,
  freeKickOnTargetBonus: 0.07,
  penaltyChanceFromFoul: 0.035,
  penaltyConvertBase: 0.76,

  staminaDrainPerTick: 0.0038,
  staminaFloor: 0.28,
  staminaStatDrainRelief: 0.35,
  roleDrainMul: DEFAULT_ROLE_DRAIN,
  trailingDrainMul: 1.12,
  redCardDrainMul: 1.08,
  fatigueIgnoreAbove: 0.7,
  fatigueMildAbove: 0.5,
  fatigueSevereBelow: 0.3,
  fatigueMildMul: 0.97,
  fatigueModerateMul: 0.9,
  fatigueSevereMul: 0.78,
  lateFatigueCurve: 1.15,

  shotAbilityWeights: defaultEventWeights({
    shooting: 0.42,
    technique: 0.22,
    power: 0.1,
    speed: 0.08,
    stamina: 0.08,
    leadership: 0.1,
    fatiguePenalty: 0.4,
  }),
  passAbilityWeights: defaultEventWeights({
    passing: 0.45,
    technique: 0.25,
    leadership: 0.12,
    stamina: 0.08,
    speed: 0.05,
    power: 0.05,
    fatiguePenalty: 0.35,
  }),
  dribbleAbilityWeights: defaultEventWeights({
    technique: 0.4,
    speed: 0.3,
    power: 0.1,
    stamina: 0.1,
    passing: 0.05,
    leadership: 0.05,
    fatiguePenalty: 0.4,
  }),
  duelAbilityWeights: defaultEventWeights({
    power: 0.4,
    technique: 0.2,
    stamina: 0.15,
    speed: 0.15,
    leadership: 0.1,
    fatiguePenalty: 0.3,
  }),
  aerialAbilityWeights: defaultEventWeights({
    power: 0.5,
    technique: 0.15,
    stamina: 0.15,
    leadership: 0.1,
    speed: 0.1,
    fatiguePenalty: 0.25,
  }),
  tackleAbilityWeights: defaultEventWeights({
    power: 0.35,
    technique: 0.2,
    speed: 0.2,
    stamina: 0.15,
    leadership: 0.1,
    fatiguePenalty: 0.3,
  }),
  personalShotBlend: 0.28,
  duelChancePerAttack: 0.22,
  aerialChancePerAttack: 0.12,
  tackleChanceOnDefend: 0.18,
  aggressiveFoulPowerFactor: 0.015,

  maxSubstitutions: 5,
  subWindowStart: 55,
  subWindowEnd: 75,
  subFatigueThreshold: 0.45,
  subEarlyFatigueThreshold: 0.32,
  subPoorRatingThreshold: 5.8,
  subBaseChancePerTick: 0.09,

  injuryBaseChance: 0.00035,
  injuryFatigueFactor: 0.0012,
  injuryLateFactor: 1.35,
  injuryPowerFactor: 0.0004,
  injuryVictimPowerRelief: 0.08,
  injuryModerateShare: 0.35,
  injurySevereShare: 0.12,

  formationMatchupCap: 0.1,
  keyPosBonusCap: 0.08,
  keyPosWeaknessFloor: 0.92,
  formationTypeMods: {
    P: {
      pressMul: 1.08,
      transitionMul: 0.98,
      possessionMul: 1.02,
      staminaDrainMul: 1.14,
      synergyWeight: 0.06,
    },
    S: {
      pressMul: 0.96,
      transitionMul: 1.12,
      possessionMul: 0.94,
      staminaDrainMul: 1.04,
      synergyWeight: 0.06,
    },
    T: {
      pressMul: 0.98,
      transitionMul: 0.96,
      possessionMul: 1.1,
      staminaDrainMul: 1.0,
      synergyWeight: 0.06,
    },
  },
  tacticPossessionExtra: 0.008,
  tacticAttackChanceExtra: 0.012,
  tacticStabilityDefenseExtra: 0.01,
  allOutAttackTrailingBoost: 1.18,

  formationModifiers: {
    "4-4-2": {
      leftAttack: 1.04,
      rightAttack: 1.04,
      centerAttack: 1.06,
      leftMid: 1.06,
      centerMid: 1.02,
      rightMid: 1.06,
      leftDefense: 1.02,
      centerDefense: 1.04,
      rightDefense: 1.02,
    },
    "4-3-3": {
      leftAttack: 1.14,
      rightAttack: 1.14,
      centerAttack: 1.02,
      leftMid: 0.98,
      centerMid: 1.0,
      rightMid: 0.98,
      leftDefense: 0.97,
      centerDefense: 0.96,
      rightDefense: 0.97,
    },
    "4-2-3-1": {
      leftAttack: 1.02,
      rightAttack: 1.02,
      centerAttack: 1.1,
      leftMid: 1.04,
      centerMid: 1.16,
      rightMid: 1.04,
      leftDefense: 1.0,
      centerDefense: 1.02,
      rightDefense: 1.0,
    },
    "3-5-2": {
      leftAttack: 1.0,
      rightAttack: 1.0,
      centerAttack: 1.08,
      leftMid: 1.12,
      centerMid: 1.1,
      rightMid: 1.12,
      leftDefense: 0.94,
      centerDefense: 0.98,
      rightDefense: 0.94,
    },
    "5-4-1": {
      leftAttack: 0.86,
      rightAttack: 0.86,
      centerAttack: 0.88,
      leftMid: 0.96,
      centerMid: 0.98,
      rightMid: 0.96,
      leftDefense: 1.16,
      centerDefense: 1.2,
      rightDefense: 1.16,
      goalkeeping: 1.04,
    },
    "3-4-3": {
      leftAttack: 1.12,
      rightAttack: 1.12,
      centerAttack: 1.06,
      leftMid: 1.04,
      centerMid: 0.96,
      rightMid: 1.04,
      leftDefense: 0.92,
      centerDefense: 0.94,
      rightDefense: 0.92,
    },
    "3-2-4-1": {
      leftAttack: 1.1,
      rightAttack: 1.1,
      centerAttack: 1.14,
      leftMid: 1.08,
      centerMid: 1.12,
      rightMid: 1.08,
      leftDefense: 0.88,
      centerDefense: 0.9,
      rightDefense: 0.88,
    },
    "3-4-1-2": {
      leftAttack: 1.02,
      rightAttack: 1.02,
      centerAttack: 1.12,
      leftMid: 1.06,
      centerMid: 1.1,
      rightMid: 1.06,
      leftDefense: 0.96,
      centerDefense: 1.04,
      rightDefense: 0.96,
    },
    "4-1-2-1-2": {
      leftAttack: 0.96,
      rightAttack: 0.96,
      centerAttack: 1.14,
      leftMid: 0.94,
      centerMid: 1.18,
      rightMid: 0.94,
      leftDefense: 0.98,
      centerDefense: 1.04,
      rightDefense: 0.98,
    },
    "4-1-4-1": {
      leftAttack: 0.98,
      rightAttack: 0.98,
      centerAttack: 0.96,
      leftMid: 1.08,
      centerMid: 1.14,
      rightMid: 1.08,
      leftDefense: 1.06,
      centerDefense: 1.1,
      rightDefense: 1.06,
    },
    "4-2-2-2": {
      leftAttack: 1.04,
      rightAttack: 1.04,
      centerAttack: 1.12,
      leftMid: 0.98,
      centerMid: 1.08,
      rightMid: 0.98,
      leftDefense: 0.96,
      centerDefense: 1.0,
      rightDefense: 0.96,
    },
    "4-2-4": {
      leftAttack: 1.16,
      rightAttack: 1.16,
      centerAttack: 1.12,
      leftMid: 0.9,
      centerMid: 0.88,
      rightMid: 0.9,
      leftDefense: 0.88,
      centerDefense: 0.86,
      rightDefense: 0.88,
    },
    "4-3-1-2": {
      leftAttack: 0.96,
      rightAttack: 0.96,
      centerAttack: 1.14,
      leftMid: 1.02,
      centerMid: 1.14,
      rightMid: 1.02,
      leftDefense: 0.98,
      centerDefense: 1.02,
      rightDefense: 0.98,
    },
    "4-5-1": {
      leftAttack: 0.92,
      rightAttack: 0.92,
      centerAttack: 0.9,
      leftMid: 1.1,
      centerMid: 1.12,
      rightMid: 1.1,
      leftDefense: 1.08,
      centerDefense: 1.1,
      rightDefense: 1.08,
    },
    "5-3-2": {
      leftAttack: 0.94,
      rightAttack: 0.94,
      centerAttack: 1.02,
      leftMid: 1.04,
      centerMid: 1.06,
      rightMid: 1.04,
      leftDefense: 1.12,
      centerDefense: 1.14,
      rightDefense: 1.12,
    },
  },

  tacticStyleModifiers: {
    balance: {
      zones: { ...IDENTITY_ZONE },
      chanceMul: 1.0,
      finishMul: 1.0,
      possessionBias: 0,
      staminaDrainExtra: 0,
      counterMul: 1.0,
    },
    attack: {
      zones: {
        leftAttack: 1.1,
        centerAttack: 1.12,
        rightAttack: 1.1,
        leftDefense: 0.92,
        centerDefense: 0.9,
        rightDefense: 0.92,
      },
      chanceMul: 1.14,
      finishMul: 1.06,
      possessionBias: -0.02,
      staminaDrainExtra: 0.0006,
      counterMul: 0.95,
    },
    defense: {
      zones: {
        leftAttack: 0.9,
        centerAttack: 0.88,
        rightAttack: 0.9,
        leftDefense: 1.1,
        centerDefense: 1.14,
        rightDefense: 1.1,
        goalkeeping: 1.04,
      },
      chanceMul: 0.86,
      finishMul: 0.96,
      possessionBias: 0.02,
      staminaDrainExtra: -0.0003,
      counterMul: 1.08,
    },
    press: {
      zones: {
        leftMid: 1.1,
        centerMid: 1.12,
        rightMid: 1.1,
        leftAttack: 1.04,
        rightAttack: 1.04,
      },
      chanceMul: 1.06,
      finishMul: 1.0,
      possessionBias: 0.03,
      staminaDrainExtra: 0.0012,
      counterMul: 0.9,
    },
    counter: {
      zones: {
        leftAttack: 1.08,
        rightAttack: 1.08,
        centerDefense: 1.06,
        leftMid: 0.96,
        centerMid: 0.94,
        rightMid: 0.96,
      },
      chanceMul: 0.94,
      finishMul: 1.1,
      possessionBias: -0.05,
      staminaDrainExtra: 0.0002,
      counterMul: 1.22,
    },
    buildup: {
      zones: {
        leftMid: 1.08,
        centerMid: 1.12,
        rightMid: 1.08,
        leftAttack: 1.02,
        centerAttack: 1.04,
        rightAttack: 1.02,
        leftDefense: 1.02,
        centerDefense: 1.04,
        rightDefense: 1.02,
      },
      chanceMul: 1.02,
      finishMul: 0.98,
      possessionBias: 0.06,
      staminaDrainExtra: 0.0004,
      counterMul: 0.88,
    },
    possession: {
      zones: {
        leftMid: 1.08,
        centerMid: 1.12,
        rightMid: 1.08,
      },
      chanceMul: 1.02,
      finishMul: 0.98,
      possessionBias: 0.06,
      staminaDrainExtra: 0.0004,
      counterMul: 0.88,
    },
  },

  ratingBase: 6.2,
  ratingGoal: 0.9,
  ratingAssist: 0.55,
  ratingSave: 0.25,
  ratingCardPenalty: 0.35,
};

export function normalizeFormationKey(name?: string): string {
  if (!name) return "4-3-3";
  const digits = name.replace(/[^0-9]/g, "");
  if (digits.length >= 3) {
    return `${digits[0]}-${digits[1]}-${digits[2]}${
      digits.length > 3 ? `-${digits.slice(3).split("").join("-")}` : ""
    }`;
  }
  return name.trim();
}

export function mergeConfig(
  overrides?: Partial<SimulationConfig>,
): SimulationConfig {
  if (!overrides) {
    return structuredClone(DEFAULT_SIMULATION_CONFIG);
  }
  return {
    ...structuredClone(DEFAULT_SIMULATION_CONFIG),
    ...overrides,
    positionFitMultiplier: {
      ...DEFAULT_SIMULATION_CONFIG.positionFitMultiplier,
      ...(overrides.positionFitMultiplier ?? {}),
    },
    roleDrainMul: {
      ...DEFAULT_SIMULATION_CONFIG.roleDrainMul,
      ...(overrides.roleDrainMul ?? {}),
    },
    formationModifiers: {
      ...DEFAULT_SIMULATION_CONFIG.formationModifiers,
      ...(overrides.formationModifiers ?? {}),
    },
    formationTypeMods: {
      ...DEFAULT_SIMULATION_CONFIG.formationTypeMods,
      ...(overrides.formationTypeMods ?? {}),
    },
    tacticStyleModifiers: {
      ...DEFAULT_SIMULATION_CONFIG.tacticStyleModifiers,
      ...(overrides.tacticStyleModifiers ?? {}),
    },
  };
}
