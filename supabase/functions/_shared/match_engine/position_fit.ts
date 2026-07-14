import type { SimulationConfig } from "./config.ts";

/** Resolve fit multiplier from config only — no linear formulas. */
export function positionFitMultiplier(
  assignedFit: number,
  config: SimulationConfig,
): number {
  const key = Math.round(assignedFit);
  const map = config.positionFitMultiplier;
  if (Object.prototype.hasOwnProperty.call(map, key)) {
    return map[key]!;
  }
  return config.positionFitFallback;
}

/**
 * Blend base value with fit.
 * blend=1 → full fit multiply; blend=0 → ignore fit.
 */
export function applyFitBlend(
  base: number,
  fitMul: number,
  blend: number,
): number {
  const b = Math.max(0, Math.min(1, blend));
  return base * (1 - b + b * fitMul);
}
