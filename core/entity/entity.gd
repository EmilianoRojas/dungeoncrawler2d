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

# New Systems
var equipment: EquipmentComponent
var skill_component: SkillComponent
var passives: PassiveEffectComponent

func _ready() -> void:
	if not initialized:
		initialize()

func initialize() -> void:
	if initialized: return
	
	stats = StatsComponent.new()
	effects = EffectManager.new(self)
	skills = SkillManager.new(self)
	
	# Initialize new components
	skill_component = SkillComponent.new(self) # Pass self for SkillManager integration
	passives = PassiveEffectComponent.new()
	equipment = EquipmentComponent.new()
	equipment.initialize(self)
	
	# Wire dependencies
	equipment.stats_component = stats
	equipment.skill_component = skill_component
	equipment.passive_effect_component = passives
	
	initialized = true


func apply_class(class_data: ClassData) -> void:
	# 1. Apply Base Stats
	for key in class_data.base_stats:
		if key is StringName:
			stats.set_base_stat(StringName(key), class_data.base_stats[key])
	
	stats.finalize_initialization()
	
	# 2. Learn Starting Skills
	for s in class_data.starting_skills:
		skills.learn_skill(s)

func is_alive() -> bool:
	return stats.current.get(StatTypes.HP, 0) > 0

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
