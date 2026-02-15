extends Node

func _init():
	print("Starting Advanced Trigger Verification...")
	test_on_kill()
	test_on_skill_cast()
	test_skill_application()

func test_on_kill():
	print("\n--- Testing ON_KILL Trigger ---")
	
	# Attacker has an effect that heals on kill
	var attacker = Entity.new()
	attacker.name = "Killer"
	attacker.initialize()
	attacker.stats.set_base_stat(StatsComponent.StatType.HP, 10)
	attacker.stats.set_base_stat(StatsComponent.StatType.MAX_HP, 100)
	attacker.stats.finalize_initialization()
	
	var heal_on_kill = EffectResource.new()
	heal_on_kill.effect_id = "heal_kill"
	heal_on_kill.trigger = EffectResource.Trigger.ON_KILL
	heal_on_kill.operation = EffectResource.Operation.HEAL_FLAT
	heal_on_kill.value = 50.0 # FLIGHT FIX
	attacker.effects.apply_effect(heal_on_kill)
	
	# Victim logic
	var victim = Entity.new()
	victim.name = "Victim"
	victim.initialize()
	victim.stats.set_base_stat(StatsComponent.StatType.HP, 10)
	victim.stats.finalize_initialization()
	
	print("Attacker HP before kill: %d" % attacker.stats.current[StatsComponent.StatType.HP])
	
	# Kill the victim
	print("dealing fatal damage...")
	var context = CombatContext.new(attacker, victim)
	context.damage = 20
	CombatSystem.deal_damage(context)
	
	var final_hp = attacker.stats.current[StatsComponent.StatType.HP]
	print("Attacker HP after kill: %d" % final_hp)
	
	if final_hp == 60:
		print("✅ PASS: ON_KILL triggered and healed attacker.")
	else:
		print("❌ FAIL: ON_KILL not triggered or value incorrect.")

func test_on_skill_cast():
	print("\n--- Testing ON_SKILL_CAST Trigger ---")
	
	var caster = Entity.new()
	caster.name = "Mage"
	caster.initialize()
	caster.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	caster.stats.finalize_initialization()
	
	# Effect: Heal when casting any skill
	var cast_heal = EffectResource.new()
	cast_heal.effect_id = "cast_mastery"
	cast_heal.trigger = EffectResource.Trigger.ON_SKILL_CAST
	cast_heal.operation = EffectResource.Operation.HEAL_FLAT
	cast_heal.value = 10.0 # FLOAT FIX
	caster.effects.apply_effect(cast_heal)
	caster.stats.modify_current(StatsComponent.StatType.HP, -20) # Damaged to 80
	
	var dummy = Entity.new()
	dummy.initialize()
	dummy.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	dummy.stats.finalize_initialization()
	
	var skill = Skill.new()
	skill.skill_name = "Zap"
	
	print("HP before cast: %d" % caster.stats.current[StatsComponent.StatType.HP])
	SkillExecutor.execute(skill, caster, dummy)
	print("HP after cast: %d" % caster.stats.current[StatsComponent.StatType.HP])
	
	if caster.stats.current[StatsComponent.StatType.HP] == 90:
		print("✅ PASS: ON_SKILL_CAST triggered.")
	else:
		print("❌ FAIL: ON_SKILL_CAST failed.")

func test_skill_application():
	print("\n--- Testing Skill Effect Application ---")
	
	var caster = Entity.new()
	caster.name = "Venomancer"
	caster.initialize()
	caster.stats.finalize_initialization()
	
	var target = Entity.new()
	target.name = "Target"
	target.initialize()
	target.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	target.stats.finalize_initialization()
	
	# Skill applies Poison
	var poison = EffectResource.new()
	poison.effect_id = "poison"
	poison.trigger = EffectResource.Trigger.ON_TURN_START
	poison.operation = EffectResource.Operation.DEAL_DAMAGE_PERCENT_BACK # Placeholder op
	
	var skill = Skill.new()
	skill.skill_name = "Poison Stab"
	skill.on_hit_effects.append(poison)
	
	print("Target effects before: %d" % target.effects.effects.size())
	SkillExecutor.execute(skill, caster, target)
	print("Target effects after: %d" % target.effects.effects.size())
	
	if target.effects._find_instance("poison") != null:
		print("✅ PASS: Skill applied effect to target.")
	else:
		print("❌ FAIL: Skill failed to apply effect.")
