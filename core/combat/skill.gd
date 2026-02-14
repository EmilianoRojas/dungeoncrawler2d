class_name Skill
extends Resource

@export var skill_name: String = "Skill"
@export var scaling_stat: String = "strength"
@export var multiplier: float = 1.0
@export var max_cooldown: int = 0 # in turns


func use(user: Entity, target: Entity) -> void:
	# Calculate raw damage based on stats
	var stat_value = user.stats.get_stat(scaling_stat)
	var damage = int(stat_value * multiplier)
	
	# Pass to CombatSystem to handle the rest (events, mitigation, etc)
	# We use a static reference or singleton for CombatSystem
	CombatSystem.deal_damage(user, target, damage)
