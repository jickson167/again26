export { DEFAULT_SIMULATION_CONFIG, mergeConfig, normalizeFormationKey } from "./config.ts";
export type {
  SimulationConfig,
  StatWeights,
  ZoneMul,
  TacticStyleMod,
  EventAbilityWeights,
  FormationTypeMod,
} from "./config.ts";
export { simulateMatch } from "./match_simulator.ts";
export { SeededRandom } from "./seeded_random.ts";
export { positionFitMultiplier, applyFitBlend } from "./position_fit.ts";
export { buildEffectiveAbilities } from "./player_rating.ts";
export { computeZoneStrength, softContestShare } from "./team_strength.ts";
export { fatiguePerformanceMul, computePlayerDrain } from "./fatigue.ts";
export {
  abilityScore,
  duelSuccess,
  personalShotFactor,
} from "./event_resolution.ts";
export type * from "./types.ts";
export {
  buildGoalAndShotFlavor,
  buildFoulPayload,
  buildCardPayload,
  buildCornerPayload,
  envelope,
  distanceFromPosition,
} from "./event_metadata.ts";
export type {
  EventMetadataEnvelope,
  GoalPayload,
  ShotPayload,
  FoulPayload,
  CardPayload,
  CornerPayload,
  EventMetaKind,
} from "./event_metadata.ts";
