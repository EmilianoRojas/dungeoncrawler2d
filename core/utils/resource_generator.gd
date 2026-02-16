@tool
extends SceneTree

func _init():
	print("Starting Resource Generation...")
	generate_effects()
	generate_skills()
	print("Resource Generation Complete!")
	quit()

func generate_effects():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("resources/effects"):
		dir.make_dir_recursive("resources/effects")
		
	# 1. Iron Skin
	var iron_skin = EffectResource.new()
	iron_skin.effect_id = "iron_skin"
	iron_skin.trigger = EffectResource.Trigger.ON_DAMAGE_RECEIVED_CALC
	iron_skin.operation = EffectResource.Operation.REDUCE_DAMAGE_PERCENT
	iron_skin.value = 0.3
	iron_skin.duration_turns = 2
	iron_skin.stack_rule = EffectResource.StackRule.REFRESH
	save_resource(iron_skin, "res://resources/effects/iron_skin.tres")
	
	# 2. Rage
	var rage = EffectResource.new()
	rage.effect_id = "rage"
	rage.trigger = EffectResource.Trigger.ON_DAMAGE_CALCULATED
	rage.operation = EffectResource.Operation.MULTIPLY_DAMAGE
	rage.value = 1.5
	rage.duration_turns = 3
	rage.stack_rule = EffectResource.StackRule.REFRESH
	save_resource(rage, "res://resources/effects/rage.tres")

func generate_skills():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("resources/skills"):
		dir.make_dir_recursive("resources/skills")

	# 1. Basic Attack
	var basic = Skill.new()
	basic.skill_name = "Basic Attack"
	basic.base_power = 5
	basic.scaling_stat = StatTypes.STRENGTH
	basic.scaling_percent = 1.0
	basic.max_cooldown = 0
	save_resource(basic, "res://resources/skills/basic_attack.tres")
	
	# 2. Heavy Strike
	var heavy = Skill.new()
	heavy.skill_name = "Heavy Strike"
	heavy.base_power = 10
	heavy.scaling_stat = StatTypes.STRENGTH
	heavy.scaling_percent = 1.5
	heavy.max_cooldown = 2
	save_resource(heavy, "res://resources/skills/heavy_strike.tres")
	
	# 3. Defensive Stance
	var def_stance = Skill.new()
	def_stance.skill_name = "Defensive Stance"
	def_stance.base_power = 0
	def_stance.scaling_type = Skill.ScalingType.FLAT
	def_stance.max_cooldown = 3
	
	# Link Iron Skin effect
	# Note: In a real editor, we'd load reference. 
	# Here we load what we just saved or create new instance if needed, 
	# but ResourceLoader is best.
	var iron_skin = ResourceLoader.load("res://resources/effects/iron_skin.tres")
	if iron_skin:
		def_stance.on_cast_effects.append(iron_skin)
	else:
		print("Error: Could not load iron_skin.tres for Defensive Stance")
		
	save_resource(def_stance, "res://resources/skills/defensive_stance.tres")
	
	# 4. Enrage
	var enrage = Skill.new()
	enrage.skill_name = "Enrage"
	enrage.base_power = 0
	enrage.scaling_type = Skill.ScalingType.FLAT
	enrage.max_cooldown = 5
	
	var rage = ResourceLoader.load("res://resources/effects/rage.tres")
	if rage:
		enrage.on_cast_effects.append(rage)
	else:
		print("Error: Could not load rage.tres for Enrage")
		
	save_resource(enrage, "res://resources/skills/enrage.tres")

func save_resource(res: Resource, path: String):
	var result = ResourceSaver.save(res, path)
	if result == OK:
		print("Saved: %s" % path)
	else:
		print("Error saving %s: %s" % [path, result])
