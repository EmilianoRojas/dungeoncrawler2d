class_name DungeonData
extends Resource

## Unique identifier (e.g. &"goblin_caves")
@export var id: StringName = ""

## Display name shown in selection UI
@export var display_name: String = ""

## Flavor text / description
@export var description: String = ""

## Difficulty rating (1-5 stars for display)
@export_range(1, 5) var difficulty: int = 1

## Number of floors before the dungeon is "complete"
@export var total_floors: int = 3

## Rooms per floor (overrides DungeonManager.max_depth)
@export var rooms_per_floor: int = 15

## Enemy pool: which enemies can spawn in this dungeon
@export var enemy_pool: Array[EnemyTemplate] = []

## Boss pool: which bosses appear at floor ends
@export var boss_pool: Array[EnemyTemplate] = []

## Stat scaling multiplier (higher = harder dungeon)
@export var stat_scaling_mult: float = 1.0

## Unlock condition: "none" = always available, otherwise a dungeon ID that must be cleared
@export var unlock_requires: StringName = &""
