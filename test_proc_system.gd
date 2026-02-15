extends Node

func _init():
    print("Starting Proc System Verification...")
    test_proc_0_percent()
    test_proc_100_percent()
    test_proc_50_percent()
    quit()

func test_proc_0_percent():
    print("\n--- Testing 0% Proc Chance ---")
    var entity = Entity.new()
    entity.initialize()
    
    var effect = EffectResource.new()
    effect.effect_id = "dud"
    effect.trigger = EffectResource.Trigger.ON_TURN_START
    effect.operation = EffectResource.Operation.HEAL_FLAT
    effect.value = 10.0
    effect.proc_chance = 0.0 # 0% chance
    
    var instance = EffectInstance.new(effect)
    
    # Try 10 times
    var triggers = 0
    for i in range(10):
        # We simulate execution directly to bypass dispatch loop and test executor logic
        var initial_hp = entity.stats.current[StatsComponent.StatType.HP]
        OperationExecutor.execute(instance, entity, {})
        if entity.stats.current[StatsComponent.StatType.HP] > initial_hp:
             triggers += 1
             # Reset HP
             entity.stats.set_base_stat(StatsComponent.StatType.HP, initial_hp)
    
    if triggers == 0:
        print("✅ PASS: 0% chance never triggered.")
    else:
        print("❌ FAIL: 0% chance triggered %d times." % triggers)

func test_proc_100_percent():
    print("\n--- Testing 100% Proc Chance ---")
    var entity = Entity.new()
    entity.initialize()
    
    var effect = EffectResource.new()
    effect.proc_chance = 1.0 # 100% chance
    effect.operation = EffectResource.Operation.HEAL_FLAT
    effect.value = 10.0
    
    var instance = EffectInstance.new(effect)
    
    # Try 10 times
    var triggers = 0
    for i in range(10):
        var initial_hp = entity.stats.current[StatsComponent.StatType.HP]
        OperationExecutor.execute(instance, entity, {})
        if entity.stats.current[StatsComponent.StatType.HP] > initial_hp:
             triggers += 1
        entity.stats.modify_current(StatsComponent.StatType.HP, -10) # Reset
            
    if triggers == 10:
        print("✅ PASS: 100% chance always triggered.")
    else:
        print("❌ FAIL: 100% chance triggered %d/10 times." % triggers)

func test_proc_50_percent():
    print("\n--- Testing 50% Proc Chance (Statistical) ---")
    var entity = Entity.new()
    entity.initialize()
    
    var effect = EffectResource.new()
    effect.proc_chance = 0.5 # 50% chance
    effect.operation = EffectResource.Operation.HEAL_FLAT
    effect.value = 10.0
    
    var instance = EffectInstance.new(effect)
    
    var trials = 100
    var triggers = 0
    for i in range(trials):
        var initial_hp = entity.stats.current[StatsComponent.StatType.HP]
        OperationExecutor.execute(instance, entity, {})
        if entity.stats.current[StatsComponent.StatType.HP] > initial_hp:
             triggers += 1
        entity.stats.modify_current(StatsComponent.StatType.HP, -10) # Reset
    
    print("50% Chance Results: %d/%d triggers" % [triggers, trials])
    
    # Allow some variance (e.g. 30-70 is acceptable for random test)
    if triggers > 30 and triggers < 70:
        print("✅ PASS: 50% chance is within expected range.")
    else:
        print("❌ FAIL: 50% chance result weird: %d" % triggers)
