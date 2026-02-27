# CLAUDE.md - Project Guide

## Overview
**Dungeon Crawler 2D** — A roguelike built in **Godot 4.4** with **GDScript**.
Turn-based 1v1 combat, procedural dungeons, skill drafting, and permadeath runs.

## Architecture
Hybrid design: **Entity Composition** + **Data-Driven Effects** + **Event Bus**.

### Core Patterns
- **Entities** are composed of components (StatsComponent, SkillManager, EffectManager, EquipmentComponent, PassiveEffectComponent)
- **Skills** are `.tres` Resources with scaling, cooldowns, hit chance, and optional on_cast/on_hit effects
- **Effects** are `.tres` Resources with triggers, operations, stacking rules — processed by OperationExecutor
- **Passives** are registered in PassiveLibrary (14 total) and resolved by PassiveResolver via EventBus
- **Enemies** are spawned by EnemyFactory from EnemyTemplate `.tres` files with floor-based scaling

### Event Bus
`GlobalEventBus` (autoload) handles all cross-system communication:
- `damage_dealt`, `entity_died`, `combat_log`, `battle_start`, `battle_end`
- `parry_success`, `avoid_success`, `observe_used`
- Passives subscribe to these events via PassiveResolver

### Damage Pipeline (in order)
1. `ON_PRE_DAMAGE_CALC` — pre-calculation (Super-strength)
2. `ON_DAMAGE_CALCULATED` — offensive phase (crit buffs)
3. `ON_DAMAGE_RECEIVED_CALC` — defensive phase (Hard Shield, Iron Skin)
4. `ON_PRE_DAMAGE_APPLY` — final adjustments
5. Shield absorption → HP damage
6. `ON_DAMAGE_DEALT` / `ON_DAMAGE_TAKEN` — post-damage (Weaken, Counter)
7. Death check → `ON_KILL` / `ON_DEATH`

## Directory Structure
```
data/
  classes/          # ClassData .tres (warrior, cleric, wizard, rogue, ranger)
  skills/           # Skill .tres (14 skills)
  effects/          # EffectResource .tres (iron_skin, rage, slow)
  enemies/          # EnemyTemplate .tres (8 enemies, tier 0/1/2)
  dungeons/         # DungeonData .tres (4 dungeons)
  camp_items/       # CampItemResource .tres (4 items)
core/
  battle/           # TurnManager
  combat/           # Skill, SkillExecutor, SkillManager, CombatSystem, CombatContext, FormulaCalculator, ActionQueue
  components/       # EquipmentComponent, PassiveEffectComponent, SkillComponent
  data/             # ClassData, DungeonData, EnemyTemplate, EventData, EventChoice, PassiveLibrary
  effects/          # EffectResource, EffectInstance, EffectManager, EffectCondition, OperationExecutor
  entity/           # Entity (main node)
  events/           # GlobalEventBus (autoload)
  factory/          # EnemyFactory, ItemFactory, ItemTemplates, LootSystem, RewardSystem, EventFactory
  items/            # CampItemResource, EquipmentResource
  map/              # DungeonManager, MapNode
  meta/             # DungeonProgress, InventoryComponent, InventoryItem
  rewards/          # RewardResource
  stats/            # StatsComponent, StatModifier, StatModifierInstance, StatTypes
  systems/          # LevelUpSystem, PassiveResolver, RewardApplier, EventSystem
  types/            # EquipmentSlot
  utils/            # GameRNG, ResourceGenerator
  game_loop.gd      # Main game loop (orchestrates everything)
ui/
  game_ui.gd        # Battle UI, skill bar, HP bars, log, room selector
  lobby.gd          # Class/camp item/dungeon selection
  game_over_screen.gd
  victory_screen.gd
  components/       # HPBar, SkillButton, SkillDraftPanel, RoomSelector, RoomButton, CharacterPanel, LootPanel, EventPanel
```

## Game Flow
1. **Lobby** → pick class, camp item, dungeon → `Engine.set_meta()` → change scene to `main.tscn`
2. **GameLoop** → room selection → combat/event/chest/camp → loot → XP/level up → skill draft → repeat
3. **Death** → GameOverScreen → return to lobby (clears Engine metas)
4. **Victory** → VictoryScreen (after final floor boss) → return to lobby

## Key Classes

| Class | Main Stat | HP | Passive | Starting Skill |
|---|---|---|---|---|
| Warrior | STR 12 | 120 | Super-strength | Heavy Strike |
| Cleric | PIE 12 | 100 | — | Holy Smite |
| Wizard | INT 14 | 80 (+30 Shield) | Hard Shield | Fireball |
| Rogue | DEX 14 | 85 | Technique | Quick Slash |
| Ranger | DEX 10 | 95 | Sniping | Ice Shard |

## Enemy Scaling (GameSpec §10)
- **HP/Shield:** full rate per floor (`1 + floor * template.stat_scaling`)
- **Combat stats:** 33% of base rate (slower growth)
- **Elite:** +50% HP, +20% POW, random offensive passive
- **Boss:** 300% HP, 200% Shield, avoid_critical passive

## Conventions
- All game data is in `.tres` resource files under `data/`
- Skills are loaded from `data/skills/` by LevelUpSystem for the draft pool
- Enemies are loaded from `data/enemies/` by EnemyFactory
- Passives are defined in `PassiveLibrary` and resolved by `PassiveResolver`
- Skill flags: `is_self_heal` (heals caster), `is_observe` (reveals enemy info)
- UI is built programmatically (no .tscn for most panels) — dark theme, centered overlays

## Build & Run
```bash
# Headless compile check (VPS)
GODOT_SILENCE_ROOT_WARNING=1 xvfb-run -a -s "-screen 0 1280x720x24" godot --windowed --resolution 1280x720

# Note: Audio warnings are expected on headless servers (no sound card)
```

## GameSpec
See `GameSpec.md` for the full design document (in Spanish). It covers combat, skills, passives, items, enemy factory, boss phases, and VFX timing.
