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

# Progression
var xp: int = 0
var level: int = 1
var max_skill_slots: int = 4

# Visuals
var sprite: Texture2D

# Camp Item (GameSpec §1: consumable selected at run start)
var camp_item: CampItemResource = null
var camp_item_cooldown: int = 0
var _camp_item_consumed: bool = false # Tracks if a consumable item was used

## Use the equipped camp item. Returns true if successful.
func use_camp_item() -> bool:
	if not camp_item:
		return false
	if _camp_item_consumed:
		return false
	if camp_item_cooldown > 0:
		return false
	
	# Apply each effect from the camp item
	for effect_res in camp_item.effects:
		if effect_res.operation == EffectResource.Operation.HEAL:
			# Special: heal based on percentage of max HP
			var max_hp = stats.get_stat(StatTypes.MAX_HP)
			var heal_amount = int(max_hp * effect_res.value)
			stats.modify_current(StatTypes.HP, heal_amount)
		elif effect_res.operation == EffectResource.Operation.ADD_STAT_MODIFIER:
			effects.apply_effect(effect_res)
		else:
			effects.apply_effect(effect_res)
	
	# Start cooldown or consume
	if camp_item.is_consumable:
		_camp_item_consumed = true
	else:
		camp_item_cooldown = camp_item.max_cooldown
	
	return true

## Tick camp item cooldown (call once per room traversal)
func tick_camp_item_cooldown() -> void:
	if camp_item_cooldown > 0:
		camp_item_cooldown -= 1

## Check if the camp item is available to use
func can_use_camp_item() -> bool:
	if not camp_item: return false
	if _camp_item_consumed: return false
	if camp_item_cooldown > 0: return false
	return true

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
	if class_data.sprite:
		self.sprite = class_data.sprite
		
	# 1. Apply Base Stats
	for key in class_data.base_stats:
		if key is StringName:
			stats.set_base_stat(StringName(key), class_data.base_stats[key])
	
	stats.finalize_initialization()
	
	# 2. Learn Starting Skills
	for s in class_data.starting_skills:
		skills.learn_skill(s)
	
	# 3. Apply Starting Passives
	for passive_id in class_data.starting_passives:
		var passive_info = PassiveLibrary.get_passive(passive_id)
		if not passive_info.is_empty():
			passives.add_passive(null, &"class_passive", passive_info)
			print("Applied passive: %s" % passive_info.get("name", passive_id))

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
