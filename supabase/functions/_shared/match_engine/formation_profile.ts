import {
  normalizeFormationKey,
  type FormationTypeMod,
  type SimulationConfig,
  type ZoneMul,
} from "./config.ts";
import { normalizeFormationType } from "./fatigue.ts";
import type {
  EffectiveAbilities,
  TeamSimulationSnapshot,
  ZoneStrength,
} from "./types.ts";

export function getFormationZoneMul(
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): Partial<ZoneMul> {
  const key = normalizeFormationKey(team.formationName);
  return config.formationModifiers[key] ?? {};
}

export function getFormationTypeMod(
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): FormationTypeMod {
  const t = normalizeFormationType(team.formationType) ?? "T";
  return config.formationTypeMods[t] ?? config.formationTypeMods["T"]!;
}

/** Soft synergy of on-pitch players with formation type (no fake intel/org stats). */
export function formationTypeSynergy(
  abilities: EffectiveAbilities[],
  team: TeamSimulationSnapshot,
  config: SimulationConfig,
): number {
  const type = normalizeFormationType(team.formationType) ?? "T";
  const mod = getFormationTypeMod(team, config);
  const onPitch = abilities.filter((a) => a.onPitch && !a.sentOff && !a.injuredOut);
  if (onPitch.length === 0) return 1;

  let sum = 0;
  for (const a of onPitch) {
    if (type === "P") {
      sum += (a.staminaStat + a.power + a.leadership) / 3;
    } else if (type === "S") {
      sum += (a.speed + a.shooting + a.technique * 0.5) / 2.5;
    } else {
      sum += (a.passing + a.technique + a.leadership) / 3;
    }
  }
  const avg = sum / onPitch.length; // ~0..10
  const centered = (avg - 5) / 10; // -0.5..0.5
  return 1 + centered * mod.synergyWeight;
}

/** Apply type mods + soft tactic extras onto zones (mutates). */
export function applyFormationTypeToZones(
  zones: ZoneStrength,
  team: TeamSimulationSnapshot,
  abilities: EffectiveAbilities[],
  config: SimulationConfig,
  scoreDiffForAllOut: number,
): void {
  const mod = getFormationTypeMod(team, config);
  const synergy = formationTypeSynergy(abilities, team, config);

  zones.leftMid *= mod.pressMul * synergy;
  zones.centerMid *= mod.pressMul * synergy;
  zones.rightMid *= mod.pressMul * synergy;

  zones.leftAttack *= mod.transitionMul;
  zones.centerAttack *= mod.transitionMul;
  zones.rightAttack *= mod.transitionMul;

  zones.leftMid *= mod.possessionMul;
  zones.centerMid *= mod.possessionMul;
  zones.rightMid *= mod.possessionMul;

  const tac = team.tactic;
  const possExtra = 1 + tac.possession * config.tacticPossessionExtra;
  const attExtra = 1 + tac.attack * config.tacticAttackChanceExtra;
  const stabExtra = 1 + tac.stability * config.tacticStabilityDefenseExtra;
  zones.leftMid *= possExtra;
  zones.centerMid *= possExtra;
  zones.rightMid *= possExtra;
  zones.leftAttack *= attExtra;
  zones.centerAttack *= attExtra;
  zones.rightAttack *= attExtra;
  zones.leftDefense *= stabExtra;
  zones.centerDefense *= stabExtra;
  zones.rightDefense *= stabExtra;

  // 4-2-4: full aggression mainly when trailing
  const formKey = normalizeFormationKey(team.formationName);
  if (formKey === "4-2-4" && scoreDiffForAllOut < 0) {
    const boost = config.allOutAttackTrailingBoost;
    zones.leftAttack *= boost;
    zones.rightAttack *= boost;
    zones.centerAttack *= boost;
    zones.leftDefense /= Math.sqrt(boost);
    zones.centerDefense /= Math.sqrt(boost);
    zones.rightDefense /= Math.sqrt(boost);
  }
}
