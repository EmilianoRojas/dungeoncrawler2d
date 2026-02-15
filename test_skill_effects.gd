extends Node

func _init():
	print("Starting Skill Effects Verification...")
	test_skill_effects()

func test_skill_effects():
	print("\n--- Testing Skill Effects (On Cast vs On Hit) ---")
	
	var caster = Entity.new()
	caster.name = "Caster"
	caster.initialize()
	
	var target = Entity.new()
	target.name = "Target"
	target.initialize()
	
	# 1. Effect for Caster (Buff)
	var buff = EffectResource.new()
	buff.effect_id = "rage"
	buff.trigger = EffectResource.Trigger.ON_TURN_START
	
	# 2. Effect for Target (Debuff)
	var debuff = EffectResource.new()
	debuff.effect_id = "bleed"
	debuff.trigger = EffectResource.Trigger.ON_TURN_START
	
	# 3. Skill Configuration
	var skill = Skill.new()
	skill.skill_name = "Reckless Strike"
	skill.on_cast_effects.append(buff)
	skill.on_hit_effects.append(debuff)
	
	print("Executing skill...")
	SkillExecutor.execute(skill, caster, target)
	
	# Verify Caster has Buff
	if caster.effects._find_instance("rage") != null:
		print("✅ PASS: Caster received On-Cast effect (Rage).")
	else:
		print("❌ FAIL: Caster missing effect.")
		
	# Verify Target has Debuff
	if target.effects._find_instance("bleed") != null:
		print("✅ PASS: Target received On-Hit effect (Bleed).")
	else:
		print("❌ FAIL: Target missing effect.")
		
	# Verify Cross-Contamination (Caster shouldn't have Bleed, Target shouldn't have Rage)
	if caster.effects._find_instance("bleed") == null and target.effects._find_instance("rage") == null:
		print("✅ PASS: Effects applied to correct targets only.")
	else:
		print("❌ FAIL: Effects applied to wrong targets!")
