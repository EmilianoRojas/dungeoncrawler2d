class_name GameLoop
extends Node

enum State {
	ROOM_SELECTION,
	COMBAT,
	EVENT,
	MENU
}

var current_state: State = State.ROOM_SELECTION

# Systems
var dungeon_manager: DungeonManager
var turn_manager: TurnManager
var player_entity: Entity
var game_ui: GameUI

const UI_SCENE = preload("res://ui/game_ui.tscn")

# Skill Draft state
var _pending_skill_offer: Skill = null

# Passive system
var passive_resolver: PassiveResolver

func _exit_tree() -> void:
	# Ensure we clean up listeners when scene changes or game quits
	GlobalEventBus.unsubscribe("damage_dealt", _on_damage_event)
	GlobalEventBus.unsubscribe("combat_log", _on_combat_log)

func _ready() -> void:
	print("Initializing GameLoop Instance: %d" % get_instance_id())
	GlobalEventBus.reset()
	
	# 1. Initialize UI (First so we can log to it)
	game_ui = UI_SCENE.instantiate()
	add_child(game_ui)
	game_ui.command_submitted.connect(handle_input)
	game_ui.skill_activated.connect(_on_ui_skill_activated)
	game_ui.room_selected.connect(_on_room_selected)
	game_ui.camp_action_chosen.connect(_on_camp_action)
	
	# 2. Initialize Player
	player_entity = Entity.new()
	player_entity.name = "Player"
	player_entity.team = Entity.Team.PLAYER
	player_entity.initialize()
	
	# Load selected class (set by Lobby, fallback to Warrior)
	var selected_class: ClassData = null
	if Engine.has_meta("selected_class"):
		selected_class = Engine.get_meta("selected_class") as ClassData
	
	if not selected_class:
		selected_class = load("res://data/classes/warrior.tres")
	
	if selected_class:
		player_entity.apply_class(selected_class)
		print("Loaded Class: %s" % selected_class.title)
	else:
		print("Error: Could not load any class!")
	
	# Load selected camp item (set by Lobby, optional)
	if Engine.has_meta("selected_camp_item"):
		var camp_item = Engine.get_meta("selected_camp_item") as CampItemResource
		if camp_item:
			player_entity.camp_item = camp_item
			print("Loaded Camp Item: %s" % camp_item.display_name)
	
	# 3. Initialize Systems
	dungeon_manager = DungeonManager.new()
	add_child(dungeon_manager)
	
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	# 4. Connect Signals
	turn_manager.turn_processing_end.connect(_on_battle_turn_end)
	turn_manager.battle_ended.connect(_on_battle_ended)
	game_ui.skill_draft_choice.connect(_on_skill_draft_choice)
	GlobalEventBus.subscribe("damage_dealt", _on_damage_event)
	GlobalEventBus.subscribe("combat_log", _on_combat_log)
	
	# 5. Initialize Passive Resolver
	passive_resolver = PassiveResolver.new()
	add_child(passive_resolver)
	GlobalEventBus.subscribe("battle_start", passive_resolver.on_battle_start)
	GlobalEventBus.subscribe("damage_dealt", passive_resolver.on_damage_dealt)
	GlobalEventBus.subscribe("damage_taken", passive_resolver.on_damage_taken)
	GlobalEventBus.subscribe("pre_damage_calc", passive_resolver.on_pre_damage_calc)
	GlobalEventBus.subscribe("pre_damage_apply", passive_resolver.on_pre_damage_apply)
	GlobalEventBus.subscribe("parry_success", passive_resolver.on_parry_success)
	GlobalEventBus.subscribe("avoid_success", passive_resolver.on_avoid_success)
	
	# 5. Generate Dungeon
	dungeon_manager.generate_dungeon()
	
	_log("Dungeon Generated. Starting at Depth %d" % dungeon_manager.current_depth)
	_show_room_selection()

func handle_input(_command: String) -> void:
	# No more direct movement commands
	pass
	# Combat input is handled via _on_ui_skill_activated

func _on_ui_skill_activated(skill: Skill) -> void:
	if current_state != State.COMBAT: return
	
	# For prototype, assume single target (the first enemy)
	var target = turn_manager.get_first_alive_enemy()
	
	if target:
		var action = AttackAction.new(player_entity, target)
		# action.damage = 10 # REMOVED
		action.skill_reference = skill
		turn_manager.submit_player_action(action)

func _show_room_selection() -> void:
	current_state = State.ROOM_SELECTION
	var choices = dungeon_manager.get_next_choices()
	
	# Update UI with floor info
	game_ui.update_floor_info(
		dungeon_manager.current_floor,
		dungeon_manager.current_depth,
		dungeon_manager.floor_modifiers
	)
	game_ui.update_level_info(
		player_entity.level,
		player_entity.xp,
		LevelUpSystem.xp_for_level(player_entity.level)
	)
	game_ui.show_room_selection(choices)
	game_ui.set_mode(false)

func _on_room_selected(choice_index: int) -> void:
	# Tick camp item cooldown each room traversal
	player_entity.tick_camp_item_cooldown()
	
	var node = dungeon_manager.advance_to_room(choice_index)
	_log("Depth %d — %s" % [dungeon_manager.current_depth, node.get_type_name()])
	
	# Update top bar
	game_ui.update_floor_info(
		dungeon_manager.current_floor,
		dungeon_manager.current_depth,
		dungeon_manager.floor_modifiers
	)
	
	_process_room_event(node)

func _process_room_event(node: MapNode) -> void:
	var type_name = node.get_type_name()
	
	match node.type:
		MapNode.Type.ENEMY, MapNode.Type.ELITE, MapNode.Type.BOSS:
			_log("Encountered %s! Starting Combat." % type_name)
			_start_combat(node)
		MapNode.Type.CHEST:
			_log("Found a Chest!")
			_process_chest_loot()
			dungeon_manager.complete_current_room()
			call_deferred("_on_room_completed")
		MapNode.Type.EVENT:
			_log("Event Triggered! (Not implemented)")
			dungeon_manager.complete_current_room()
			call_deferred("_on_room_completed")
		MapNode.Type.CAMP:
			_log("Found a Camp. Choose your action.")
			_show_camp_menu()

func _start_combat(node: MapNode) -> void:
	current_state = State.COMBAT
	
	# Map room type to enemy tier
	var tier = EnemyTemplate.Tier.NORMAL
	match node.type:
		MapNode.Type.ELITE:
			tier = EnemyTemplate.Tier.ELITE
		MapNode.Type.BOSS:
			tier = EnemyTemplate.Tier.BOSS
	
	var enemy = EnemyFactory.create_random_enemy(tier, dungeon_manager.current_floor)
	_log("Floor %d - %s fight! [%s]" % [dungeon_manager.current_floor, node.get_type_name(), enemy.name])
	
	# Register passives for combat
	passive_resolver.register(player_entity)
	passive_resolver.register(enemy)
	
	turn_manager.start_battle(player_entity, [enemy])
	game_ui.initialize_battle(player_entity, [enemy])
	game_ui.set_mode(true)
	
	# Dispatch battle_start event for passives
	GlobalEventBus.dispatch("battle_start", {
		"player": player_entity,
		"source": player_entity,
		"target": enemy,
		"enemies": [enemy]
	})

func _on_battle_turn_end() -> void:
	pass

func _on_battle_ended(result: TurnManager.Phase) -> void:
	# Clean up passives from battle
	GlobalEventBus.dispatch("battle_end", {"player": player_entity})
	passive_resolver.cleanup_battle_modifiers(player_entity)
	passive_resolver.clear()
	
	if result == TurnManager.Phase.WIN:
		_log("Victory! Proceeding.")
		# Reset shield after battle (GameSpec §3)
		player_entity.stats.reset_shield()
		# Generate loot from the enemy
		_process_combat_loot()
		
		# Award XP based on enemy tier
		var current_room = dungeon_manager.current_room
		var tier = 0 # NORMAL
		if current_room:
			if current_room.type == MapNode.Type.ELITE:
				tier = 1
			elif current_room.type == MapNode.Type.BOSS:
				tier = 2
		
		var xp_amount = LevelUpSystem.get_xp_for_tier(tier)
		_log("+%d XP" % xp_amount)
		var leveled_up = LevelUpSystem.award_xp(player_entity, xp_amount)
		
		# Update XP display
		game_ui.update_level_info(
			player_entity.level,
			player_entity.xp,
			LevelUpSystem.xp_for_level(player_entity.level)
		)
		
		if leveled_up:
			_log("⬆ LEVEL UP! Now Level %d" % player_entity.level)
			_start_skill_draft()
			return # Wait for draft to complete before proceeding
		
		dungeon_manager.complete_current_room()
		await get_tree().create_timer(1.0).timeout
		_on_room_completed()
	else:
		_log("DEFEATED.")
		# Handle Game Over (Run ends, reset everything)

func _on_room_completed() -> void:
	# Show next choices
	_show_room_selection()

func _on_combat_log(data: Dictionary) -> void:
	var msg = data.get("message", "")
	if msg != "":
		_log(msg)

func _on_damage_event(data: Dictionary) -> void:
	# Update UI for the target
	var target = data.get("target")
	if target:
		var is_player = (target == player_entity)
		game_ui.update_hp(target, is_player)

# --- LOOT PROCESSING ---

func _process_combat_loot() -> void:
	var current_room = dungeon_manager.current_room
	var is_elite = current_room and current_room.type == MapNode.Type.ELITE
	var is_boss = current_room and current_room.type == MapNode.Type.BOSS
	var dungeon_floor = dungeon_manager.current_floor
	
	var rewards = LootSystem.generate_enemy_loot(dungeon_floor, is_elite, is_boss)
	
	if rewards.is_empty():
		_log("No loot dropped.")
		return
	
	for reward in rewards:
		if reward.type == RewardResource.Type.EQUIPMENT and reward.equipment:
			var equipped = RewardApplier.try_auto_equip(player_entity, reward.equipment)
			if equipped:
				_log("Equipped: %s [%s]" % [reward.equipment.display_name, reward.equipment.rarity])
				game_ui.update_hp(player_entity, true) # Refresh stats display
			else:
				_log("Found: %s [%s] (current gear is better)" % [reward.equipment.display_name, reward.equipment.rarity])
		else:
			RewardApplier.apply_reward(player_entity, reward)
			_log("Gained: %s" % reward.get_display_name())

func _process_chest_loot() -> void:
	var dungeon_floor = dungeon_manager.current_floor
	var rewards = LootSystem.generate_chest_loot(dungeon_floor)
	
	for reward in rewards:
		if reward.type == RewardResource.Type.EQUIPMENT and reward.equipment:
			var equipped = RewardApplier.try_auto_equip(player_entity, reward.equipment)
			if equipped:
				_log("Equipped: %s [%s]" % [reward.equipment.display_name, reward.equipment.rarity])
				game_ui.update_hp(player_entity, true)
			else:
				_log("Found: %s [%s] (current gear is better)" % [reward.equipment.display_name, reward.equipment.rarity])
		else:
			RewardApplier.apply_reward(player_entity, reward)
			_log("Gained: %s" % reward.get_display_name())

func _log(msg: String) -> void:
	# game_ui.add_log already prints to console, so we don't need print(msg) here
	if game_ui:
		game_ui.add_log(msg)
	else:
		print(msg) # Fallback if UI not ready

# --- SKILL DRAFT ---

func _start_skill_draft() -> void:
	var offered = LevelUpSystem.get_skill_offer(player_entity)
	if not offered:
		_log("No skills available to offer.")
		_finish_post_combat()
		return
	
	_pending_skill_offer = offered
	var upgrade = LevelUpSystem.find_upgrade_match(player_entity, offered)
	
	if upgrade:
		_log("Skill offered: %s (UPGRADE to Lv %d!)" % [offered.skill_name, upgrade.skill_level + 1])
	else:
		_log("Skill offered: %s" % offered.skill_name)
	
	game_ui.show_skill_draft(
		offered,
		player_entity.skills.known_skills,
		player_entity.max_skill_slots,
		upgrade
	)

func _on_skill_draft_choice(action: String, slot_index: int) -> void:
	if not _pending_skill_offer:
		_finish_post_combat()
		return
	
	match action:
		"learn":
			LevelUpSystem.learn_skill(player_entity, _pending_skill_offer)
			_log("Learned: %s" % _pending_skill_offer.skill_name)
		"upgrade":
			var existing = LevelUpSystem.find_upgrade_match(player_entity, _pending_skill_offer)
			if existing:
				LevelUpSystem.upgrade_skill(existing)
				_log("Upgraded: %s → Lv %d" % [existing.skill_name, existing.skill_level])
		"replace":
			var old_name = ""
			if slot_index >= 0 and slot_index < player_entity.skills.known_skills.size():
				old_name = player_entity.skills.known_skills[slot_index].skill_name
			LevelUpSystem.learn_skill(player_entity, _pending_skill_offer, slot_index)
			_log("Replaced %s with %s" % [old_name, _pending_skill_offer.skill_name])
		"skip":
			_log("Skipped skill offer.")
	
	_pending_skill_offer = null
	_finish_post_combat()

func _finish_post_combat() -> void:
	dungeon_manager.complete_current_room()
	await get_tree().create_timer(1.0).timeout
	_on_room_completed()

# --- CAMP MENU ---

func _show_camp_menu() -> void:
	current_state = State.EVENT # Re-use EVENT state for camp interaction
	game_ui.set_mode(false)
	game_ui.show_camp_menu(
		player_entity.camp_item,
		player_entity.camp_item_cooldown,
		player_entity.can_use_camp_item()
	)

func _on_camp_action(action: String) -> void:
	match action:
		"rest":
			# Full HP heal + shield reset
			player_entity.stats.modify_current(StatTypes.HP, player_entity.stats.get_stat(StatTypes.MAX_HP))
			player_entity.stats.reset_shield()
			_log("Rested. HP and Shield fully restored.")
			game_ui.update_hp(player_entity, true)
		"use_item":
			if player_entity.use_camp_item():
				_log("Used: %s" % player_entity.camp_item.display_name)
				game_ui.update_hp(player_entity, true)
			else:
				_log("Cannot use camp item right now.")
	
	dungeon_manager.complete_current_room()
	call_deferred("_on_room_completed")
