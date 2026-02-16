@tool
extends SceneTree

func _init():
	print("--- Starting Stat Modifier System Test ---")
	test_stat_modifiers()
	quit()

func test_stat_modifiers():
	var stats = StatsComponent.new()
	stats.base = {
		"strength": 10,
		"speed": 5
	}
	stats.finalize_initialization()
	
	print("Base Strength: ", stats.get_stat("strength")) # Should be 10
	assert(stats.get_stat("strength") == 10, "Base strength mismatch")
	
	# 1. Flat Modifier (+5)
	var flat_mod = StatModifier.new()
	flat_mod.stat = "strength"
	flat_mod.type = StatModifier.Type.FLAT
	flat_mod.value = 5
	# flat_mod.source_id = "test_buff" # Old way
	
	# Test override
	stats.add_modifier(flat_mod, "test_buff")
	print("After Flat (+5): ", stats.get_stat("strength")) # Should be 15
	assert(stats.get_stat("strength") == 15, "Flat modifier failed")
	
	# 2. Percent Add (+100%, i.e. +1.0)
	var pct_mod = StatModifier.new()
	pct_mod.stat = "strength"
	pct_mod.type = StatModifier.Type.PERCENT_ADD
	pct_mod.value = 1.0 # +100%
	
	stats.add_modifier(pct_mod)
	# Formula: (10 + 5) * (1 + 1) = 15 * 2 = 30
	print("After Percent (+100%): ", stats.get_stat("strength")) 
	assert(stats.get_stat("strength") == 30, "Percent modifier failed")
	
	# 3. Multiplier (x2.0)
	var mult_mod = StatModifier.new()
	mult_mod.stat = "strength"
	mult_mod.type = StatModifier.Type.MULTIPLIER
	mult_mod.value = 2.0
	
	stats.add_modifier(mult_mod)
	# Formula: 30 * 2 = 60
	print("After Mult (x2): ", stats.get_stat("strength"))
	assert(stats.get_stat("strength") == 60, "Multiplier modifier failed")
	
	# 4. Remove by source
	stats.remove_modifiers_from_source("test_buff")
	# Removed flat (+5).
	# Formula: (10) * (1 + 1) * 2 = 10 * 2 * 2 = 40
	print("After removing 'test_buff' (flat +5): ", stats.get_stat("strength"))
	assert(stats.get_stat("strength") == 40, "Removal failed")
	
	# 5. Duration / Ticking
	# Add a timed modifier
	var timed_mod = StatModifier.new()
	timed_mod.stat = "speed"
	timed_mod.type = StatModifier.Type.FLAT
	timed_mod.value = 10
	timed_mod.duration_turns = 2
	
	stats.add_modifier(timed_mod)
	print("Speed with timed mod: ", stats.get_stat("speed")) # 5 + 10 = 15
	assert(stats.get_stat("speed") == 15, "Timed mod init failed")
	
	# Tick 1
	stats.tick_modifiers()
	print("Speed after 1 tick: ", stats.get_stat("speed")) # Should still be 15
	assert(stats.get_stat("speed") == 15, "Timed mod premature expiry")
	
	# Tick 2
	stats.tick_modifiers()
	print("Speed after 2 ticks: ", stats.get_stat("speed")) # Should be 5 (expired)
	assert(stats.get_stat("speed") == 5, "Timed mod failed to expire")
	
	print("--- All Stat Modifier Tests Passed ---")
