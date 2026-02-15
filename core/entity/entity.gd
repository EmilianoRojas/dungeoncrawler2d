class_name Entity
extends Node

enum Team {
	PLAYER,
	ENEMY
}

var initialized: bool = false
@export var team: Team = Team.ENEMY # Default to Enemy

var stats: StatsComponent
var effects: EffectManager
var skills: SkillManager

func _ready() -> void:
	if not initialized:
		initialize()

func initialize() -> void:
	if initialized: return
	
	stats = StatsComponent.new()
	effects = EffectManager.new(self)
	skills = SkillManager.new(self)
	
	initialized = true


func apply_class(class_data: ClassData) -> void:
	# 1. Apply Base Stats
	for key in class_data.base_stats:
		var enum_key = -1
		
		# Handle both String keys (from JSON/Editor) and int keys (direct enum usage)
		if key is String:
			enum_key = StatsComponent.get_stat_type_from_string(key)
		elif key is int:
			enum_key = key
			
		if enum_key != -1:
			stats.set_base_stat(enum_key, class_data.base_stats[key])
	
	stats.finalize_initialization()
	
	# 2. Learn Starting Skills
	for s in class_data.starting_skills:
		skills.learn_skill(s)

func is_alive() -> bool:
	return stats.current.get(StatsComponent.StatType.HP, 0) > 0

func decide_action(context: Dictionary = {}) -> Action:
	# Virtual method. 
	# Player: Return null (waits for input) or a pre-selected action if input handling is separate.
	# Enemy: Return an AI decided action.
	# Simple AI for prototype:
	if team == Team.ENEMY and skills.known_skills.size() > 0:
		var skill = skills.known_skills[0] # Pick first skill
		var target = context.get("target") # Passed by TurnManager?
		
		# If no target in context, we need to find one. 
		# For now, let's assume specific logic in subclasses or external AI controller.
		# Returning null means "skip/wait" or "not ready".
		
		if target:
			var action = AttackAction.new(self, target)
			# action.damage = 5 # REMOVED
			action.skill_reference = skill
			return action
			
	return null
