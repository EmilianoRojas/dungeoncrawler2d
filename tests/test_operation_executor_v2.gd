extends Node

func _init():
	print("Starting OperationExecutor Verification V2...")
	test_offensive()
	test_defensive()
	test_clamps()
	test_conditions()
	test_special()

func test_offensive():
	print("\n--- Testing Offensive Operations ---")
	
	var ctx = CombatContext.new()
	ctx.damage = 100
	
	var op = EffectResource.new()
	
	# TEST 1: ADD_DAMAGE
	op.operation = EffectResource.Operation.ADD_DAMAGE
	op.value = 50
	_run_op(op, ctx)
	_assert(ctx.damage == 150, "ADD_DAMAGE failed. Got: %d" % ctx.damage)
	
	# TEST 2: ADD_DAMAGE_PERCENT
	# 150 + (150 * 0.5) = 150 + 75 = 225
	op.operation = EffectResource.Operation.ADD_DAMAGE_PERCENT
	op.value = 0.5
	_run_op(op, ctx)
	_assert(ctx.damage == 225, "ADD_DAMAGE_PERCENT failed. Got: %d" % ctx.damage)
	
	# TEST 3: MULTIPLY_DAMAGE
	# 225 * 2 = 450
	op.operation = EffectResource.Operation.MULTIPLY_DAMAGE
	op.value = 2.0
	_run_op(op, ctx)
	_assert(ctx.damage == 450, "MULTIPLY_DAMAGE failed. Got: %d" % ctx.damage)
	
	# TEST 4: SET_DAMAGE
	op.operation = EffectResource.Operation.SET_DAMAGE
	op.value = 999
	_run_op(op, ctx)
	_assert(ctx.damage == 999, "SET_DAMAGE failed. Got: %d" % ctx.damage)

func test_defensive():
	print("\n--- Testing Defensive Operations ---")
	
	var ctx = CombatContext.new()
	ctx.damage = 100
	var op = EffectResource.new()
	
	# TEST 1: REDUCE_DAMAGE_FLAT
	op.operation = EffectResource.Operation.REDUCE_DAMAGE_FLAT
	op.value = 20
	_run_op(op, ctx)
	_assert(ctx.damage == 80, "REDUCE_DAMAGE_FLAT failed. Got: %d" % ctx.damage)
	
	# TEST 2: REDUCE_DAMAGE_PERCENT
	# 80 * (1.0 - 0.25) = 60
	op.operation = EffectResource.Operation.REDUCE_DAMAGE_PERCENT
	op.value = 0.25
	_run_op(op, ctx)
	_assert(ctx.damage == 60, "REDUCE_DAMAGE_PERCENT failed. Got: %d" % ctx.damage)
	
	# TEST 3: ABSORB_DAMAGE
	# Absorb 40. 60 - 40 = 20
	op.operation = EffectResource.Operation.ABSORB_DAMAGE
	op.value = 40
	_run_op(op, ctx)
	_assert(ctx.damage == 20, "ABSORB_DAMAGE failed. Got: %d" % ctx.damage)

func test_clamps():
	print("\n--- Testing Clamps ---")
	var op = EffectResource.new()
	
	# TEST 1: CLAMP_MIN_DAMAGE
	var ctx1 = CombatContext.new()
	ctx1.damage = 5
	op.operation = EffectResource.Operation.CLAMP_MIN_DAMAGE
	op.value = 10
	_run_op(op, ctx1)
	_assert(ctx1.damage == 10, "CLAMP_MIN_DAMAGE (increase) failed. Got: %d" % ctx1.damage)
	
	# TEST 2: CLAMP_MAX_DAMAGE
	var ctx2 = CombatContext.new()
	ctx2.damage = 100
	op.operation = EffectResource.Operation.CLAMP_MAX_DAMAGE
	op.value = 50
	_run_op(op, ctx2)
	_assert(ctx2.damage == 50, "CLAMP_MAX_DAMAGE (decrease) failed. Got: %d" % ctx2.damage)

func test_conditions():
	print("\n--- Testing Conditions ---")
	
	var ctx = CombatContext.new()
	ctx.damage = 100
	ctx.is_crit = false
	
	var op = EffectResource.new()
	op.operation = EffectResource.Operation.MULTIPLY_DAMAGE
	op.value = 2.0
	
	var cond = EffectCondition.new()
	cond.type = EffectCondition.Type.IS_CRIT
	op.conditions.append(cond)
	
	# TEST 1: Condition Fail (Not Crit)
	_run_op(op, ctx)
	_assert(ctx.damage == 100, "Condition Filter Check Failed. Should be 100, got: %d" % ctx.damage)
	
	# TEST 2: Condition Pass (Is Crit)
	ctx.is_crit = true
	_run_op(op, ctx)
	_assert(ctx.damage == 200, "Condition Pass Check Failed. Should be 200, got: %d" % ctx.damage)

func test_special():
	print("\n--- Testing Special Operations ---")
	
	var ctx = CombatContext.new()
	ctx.damage = 50
	
	var op = EffectResource.new()
	
	# STORE_DAMAGE
	op.operation = EffectResource.Operation.STORE_DAMAGE
	_run_op(op, ctx)
	_assert(ctx.stored_damage == 50, "STORE_DAMAGE failed.")
	
	# CONVERT_TO_TRUE_DAMAGE
	op.operation = EffectResource.Operation.CONVERT_TO_TRUE_DAMAGE
	_run_op(op, ctx)
	_assert(ctx.ignore_defense == true, "CONVERT_TO_TRUE_DAMAGE failed.")

# Helper to run op logic
func _run_op(res: EffectResource, ctx: CombatContext):
	var instance = EffectInstance.new(res)
	instance.stacks = 1
	# Mock owner entity
	var owner = Entity.new()
	OperationExecutor.execute(instance, owner, ctx)

func _assert(condition: bool, msg: String):
	if condition:
		print("✅ PASS")
	else:
		print("❌ FAIL: " + msg)
