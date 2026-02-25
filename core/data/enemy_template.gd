class_name EnemyTemplate
extends Resource

enum Tier {NORMAL, ELITE, BOSS}

@export var enemy_name: String = "Enemy"
@export var tier: Tier = Tier.NORMAL
@export var base_stats: Dictionary[StringName, int] = {}
@export var skills: Array[Skill] = []
@export var stat_scaling: float = 0.12 # Per-floor multiplier: stats * (1 + floor * scaling)
@export var sprite: Texture2D
