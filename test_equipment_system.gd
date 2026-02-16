extends Node

func _init():
	print("=== STARTING EQUIPMENT SYSTEM VERIFICATION ===")
	
	test_equipment_flow()
	

func test_equipment_flow():
	print("\n--- TEST: Equipment Flow ---")
	
	# 1. Setup Entity
	var entity = Entity.new()
	entity._ready() # Initialize components
	entity.name = "TestHero"
	
	# Setup base stats
	entity.stats.set_base_stat(StatTypes.STRENGTH, 10)
	entity.stats.set_base_stat(StatTypes.MAX_HP, 100)
	entity.stats.finalize_initialization()
	
	print("Initial STR: %d" % entity.stats.get_stat(StatTypes.STRENGTH))
	print("Initial HP: %d" % entity.stats.get_stat(StatTypes.MAX_HP))
	
	# 2. PROPOSAL: Create Equipment Item (Scripted for test)
	var sword = EquipmentResource.new()
	sword.id = "sword_of_strength"
	sword.display_name = "Sword of Strength"
	sword.slot = EquipmentSlot.Type.MAIN_HAND
	
	# A) Stat Modifier (+5 STR)
	var str_mod = StatModifier.new()
	str_mod.stat = StatTypes.STRENGTH
	str_mod.type = StatModifier.Type.FLAT
	str_mod.value = 5.0
	
	var eff_stat = EffectResource.new()
	eff_stat.effect_id = "sword_str_buff"
	eff_stat.operation = EffectResource.Operation.ADD_STAT_MODIFIER
	eff_stat.stat_modifier = str_mod
	sword.equip_effects.append(eff_stat)
	
	# B) Granted Skill ("Fire Slash")
	var skill = Skill.new()
	skill.skill_name = "Fire Slash"
	sword.granted_skills.append(skill)
	
	# C) Passive Effect (Heal on Turn Start)
	var eff_passive = EffectResource.new()
	eff_passive.effect_id = "regen_passive"
	eff_passive.trigger = EffectResource.Trigger.ON_TURN_START
	eff_passive.operation = EffectResource.Operation.HEAL
	eff_passive.value = 5.0
	sword.passive_effects.append(eff_passive)
	
	# 3. Equip
	print("\n-> Equipping Sword...")
	entity.equipment.equip(sword)
	
	# 4. Verify Stats
	var new_str = entity.stats.get_stat(StatTypes.STRENGTH)
	print("New STR: %d (Expected: 15)" % new_str)
	if new_str == 15:
		print("✅ Stat Check: PASS")
	else:
		print("❌ Stat Check: FAIL")
		
	# 5. Verify Skills
	var has_skill = false
	if entity.skills.known_skills.has(skill):
		has_skill = true
	
	# Also check via component
	var skill_comp_has = entity.skill_component.skills.has(skill)
	
	print("Skill Added: %s (Expected: True)" % has_skill)
	if has_skill and skill_comp_has:
		print("✅ Skill Check: PASS")
	else:
		print("❌ Skill Check: FAIL")
		
	# 6. Verify Passives
	var passives = entity.passives.get_passives_by_trigger(EffectResource.Trigger.ON_TURN_START)
	var has_passive = false
	for p in passives:
		if p.effect == eff_passive:
			has_passive = true
	
	print("Passive Registered: %s (Expected: True)" % has_passive)
	if has_passive:
		print("✅ Passive Check: PASS")
	else:
		print("❌ Passive Check: FAIL")
		
	# 7. Simulate Turn Start (Passive Execution)
	# We manually trigger what TurnManager would do
	print("\n-> Simulating Turn Start...")
	entity.stats.current[StatTypes.HP] = 50 # Damaged
	print("HP Before Turn: %d" % entity.stats.get_current(StatTypes.HP))
	
	# Execute logic from TurnManager
	for p_data in entity.passives.get_passives_by_trigger(EffectResource.Trigger.ON_TURN_START):
		var effect = p_data.effect
		var source_id = p_data.source # Should be 'MAIN_HAND'
		print("Triggering passive from source: %s" % source_id)
		
		# Execute
		var instance = EffectInstance.new(effect)
		var context = CombatContext.new()
		context.source = entity
		context.target = entity # Explicitly set target to self for regression/buffs
		context.custom_source_id = source_id
		OperationExecutor.execute(instance, entity, context)
		
	print("HP After Turn: %d (Expected: 55)" % entity.stats.get_current(StatTypes.HP))
	if entity.stats.get_current(StatTypes.HP) == 55:
		print("✅ Passive Execution Check: PASS")
	else:
		print("❌ Passive Execution Check: FAIL")

	# 8. Unequip
	print("\n-> Unequipping Sword...")
	entity.equipment.unequip(EquipmentSlot.Type.MAIN_HAND)
	
	# 9. Verify Removal
	var final_str = entity.stats.get_stat(StatTypes.STRENGTH)
	var final_skill_has = entity.skills.known_skills.has(skill)
	var final_passive_list = entity.passives.get_passives_by_trigger(EffectResource.Trigger.ON_TURN_START)
	
	print("Final STR: %d (Expected: 10)" % final_str)
	print("Has Skill: %s (Expected: False)" % final_skill_has)
	print("Has Passive: %s (Expected: False)" % (final_passive_list.size() > 0))
	
	if final_str == 10 and not final_skill_has and final_passive_list.is_empty():
		print("✅ Unequip Check: PASS")
	else:
		print("❌ Unequip Check: FAIL")
