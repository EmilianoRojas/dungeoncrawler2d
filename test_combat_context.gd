extends SceneTree

func _init():
	print("Starting CombatContext Verification...")
	test_context_flow()
	quit()

func test_context_flow():
	print("\n--- Testing CombatContext Flow ---")
	
	var attacker = Entity.new()
	attacker.name = "Attacker"
	attacker.initialize()
	
	var defender = Entity.new()
	defender.name = "Defender"
	defender.initialize()
	defender.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	defender.stats.set_base_stat(StatsComponent.StatType.MAX_HP, 100)
	defender.stats.finalize_initialization()
	
	# Create an effect that triggers on damage taken, but ONLY if it was a CRIT
	var react_effect = EffectResource.new()
	react_effect.effect_id = "crit_reaction"
	react_effect.trigger = EffectResource.Trigger.ON_DAMAGE_TAKEN
	react_effect.operation = EffectResource.Operation.HEAL_FLAT
	react_effect.value = 50.0
	
	# Condition: Is Crit
	var cond = EffectCondition.new()
	cond.type = EffectCondition.Type.IS_CRIT
	react_effect.conditions.append(cond)
	
	defender.effects.apply_effect(react_effect)
	
	# 1. Non-Crit Attack
	print("Test 1: Normal Attack (Should NOT trigger reaction)...")
	var normal_ctx = CombatContext.new(attacker, defender)
	normal_ctx.damage = 10
	CombatSystem.deal_damage(normal_ctx)
	
	if defender.stats.current[StatsComponent.StatType.HP] == 90: # 100 - 10
		print("✅ PASS: Normal attack passed, reaction blocked.")
	else:
		print("❌ FAIL: Reaction triggered incorrectly. HP: %d" % defender.stats.current[StatsComponent.StatType.HP])
		
	# 2. Crit Attack (Simulated by hacking context or adding crit support to deal_damage?)
	# CombatSystem.deal_damage doesn't expose is_crit arg yet.
	# We can simulate the dispatch manually to test the Context pipeline.
	
	print("Test 2: Crit Event (Manual Dispatch)...")
	var ctx = CombatContext.new(attacker, defender)
	ctx.damage = 20
	ctx.is_crit = true
	
	defender.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, ctx)
	
	# Expected: Took no damage (manual dispatch only triggers effects), but HEAL should trigger.
	# HP was 90. Heal is 50. Max is 100. Should be 100.
	
	if defender.stats.current[StatsComponent.StatType.HP] == 100:
		print("✅ PASS: Crit reaction triggered.")
	else:
		print("❌ FAIL: Crit reaction failed. HP: %d" % defender.stats.current[StatsComponent.StatType.HP])
