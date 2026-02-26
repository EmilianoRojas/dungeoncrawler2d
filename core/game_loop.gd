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

# Loot queue state
var _pending_loot: Array[EquipmentResource] = []
var _pending_loot_source: String = "" # "combat" or "chest"

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
	game_ui.loot_decision.connect(_on_loot_decision)
	
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
	
	# Give UI a reference to the player for the Stats panel
	game_ui.set_player_ref(player_entity)
	# 3. Initialize Systems
	dungeon_manager = DungeonManager.new()
	add_child(dungeon_manager)
	
	# Load selected dungeon (set by Lobby)
	if Engine.has_meta("selected_dungeon"):
		var dungeon_data = Engine.get_meta("selected_dungeon") as DungeonData
		if dungeon_data:
			dungeon_manager.configure(dungeon_data)
	
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
	
	# 6. Generate Dungeon
	dungeon_manager.generate_dungeon()
	
	var dungeon_name = "Dungeon"
	if dungeon_manager.dungeon_data:
		dungeon_name = dungeon_manager.dungeon_data.display_name
	_log("%s — Starting at Depth %d" % [dungeon_name, dungeon_manager.current_depth])
	_show_room_selection()

func handle_input(_command: String) -> void:
	# No more direct movement commands
	pass
	# Combat input is handled via _on_ui_skill_activated

func _on_ui_skill_activated(skill: Skill) -> void:
	if current_state != State.COMBAT: return
	
	# Check cooldown
	if not player_entity.skills.is_skill_ready(skill):
		_log("⏳ %s is on cooldown (%d turns left)" % [skill.skill_name, player_entity.skills.cooldowns.get(skill, 0)])
		return
	
	# For prototype, assume single target (the first enemy)
	var target = turn_manager.get_first_alive_enemy()
	
	if target:
		var action = AttackAction.new(player_entity, target)
		action.skill_reference = skill
		# Put skill on cooldown before submitting (so UI updates immediately)
		player_entity.skills.put_on_cooldown(skill)
		game_ui.update_skill_cooldowns(player_entity)
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
		MapNode.Type.EVENT:
			_start_event()
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
	
	# Create enemy from dungeon pool or fallback to global
	var enemy: Entity
	var dd = dungeon_manager.dungeon_data
	if dd and (dd.enemy_pool.size() > 0 or dd.boss_pool.size() > 0):
		enemy = EnemyFactory.create_from_pool(dd.enemy_pool, dd.boss_pool, tier, dungeon_manager.current_floor, dd.stat_scaling_mult)
	else:
		enemy = EnemyFactory.create_random_enemy(tier, dungeon_manager.current_floor)
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
		# Check if this was the final boss of the dungeon
		var is_final_boss = _is_final_boss()
		# Generate loot from the enemy and show loot UI
		_process_combat_loot(is_final_boss)
	else:
		_log("DEFEATED.")
		_show_game_over_screen()

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

var _is_final_boss_victory: bool = false

func _is_final_boss() -> bool:
	if not dungeon_manager or not dungeon_manager.current_room:
		return false
	return dungeon_manager.current_floor >= dungeon_manager.total_floors and dungeon_manager.current_room.type == MapNode.Type.BOSS

func _process_combat_loot(is_final_boss: bool = false) -> void:
	_is_final_boss_victory = is_final_boss
	var current_room = dungeon_manager.current_room
	var is_elite = current_room and current_room.type == MapNode.Type.ELITE
	var is_boss = current_room and current_room.type == MapNode.Type.BOSS
	var dungeon_floor = dungeon_manager.current_floor
	
	var rewards = LootSystem.generate_enemy_loot(dungeon_floor, is_elite, is_boss)
	
	if rewards.is_empty():
		_log("No loot dropped.")
		_finish_loot_phase()
		return
	
	# Separate equipment (needs UI) from auto-apply rewards
	_pending_loot.clear()
	_pending_loot_source = "combat"
	for reward in rewards:
		if reward.type == RewardResource.Type.EQUIPMENT and reward.equipment:
			_pending_loot.append(reward.equipment)
		else:
			RewardApplier.apply_reward(player_entity, reward)
			_log("Gained: %s" % reward.get_display_name())
	
	_process_loot_queue()

func _process_chest_loot() -> void:
	var dungeon_floor = dungeon_manager.current_floor
	var rewards = LootSystem.generate_chest_loot(dungeon_floor)
	
	_pending_loot.clear()
	_pending_loot_source = "chest"
	for reward in rewards:
		if reward.type == RewardResource.Type.EQUIPMENT and reward.equipment:
			_pending_loot.append(reward.equipment)
		else:
			RewardApplier.apply_reward(player_entity, reward)
			_log("Gained: %s" % reward.get_display_name())
	
	_process_loot_queue()

func _process_loot_queue() -> void:
	if _pending_loot.is_empty():
		_finish_loot_phase()
		return
	
	# Show the next item
	var item = _pending_loot[0]
	var slot = item.slot
	var current_equipped: EquipmentResource = null
	if player_entity.equipment and player_entity.equipment.equipped_items.has(slot):
		current_equipped = player_entity.equipment.equipped_items[slot] as EquipmentResource
	
	_log("Found: %s [%s]" % [item.display_name, item.rarity])
	game_ui.show_loot_panel(item, current_equipped)

func _on_loot_decision(equip: bool) -> void:
	if _pending_loot.is_empty():
		return
	
	var item = _pending_loot.pop_front()
	if equip:
		if player_entity.equipment:
			player_entity.equipment.equip(item)
		_log("Equipped: %s [%s]" % [item.display_name, item.rarity])
		game_ui.update_hp(player_entity, true)
	else:
		_log("Skipped: %s" % item.display_name)
	
	# Show next item or finish
	_process_loot_queue()

func _finish_loot_phase() -> void:
	if _pending_loot_source == "combat":
		# Award XP after combat loot
		var current_room = dungeon_manager.current_room
		var tier = 0
		if current_room:
			if current_room.type == MapNode.Type.ELITE:
				tier = 1
			elif current_room.type == MapNode.Type.BOSS:
				tier = 2
		
		var xp_amount = LevelUpSystem.get_xp_for_tier(tier)
		_log("+%d XP" % xp_amount)
		var leveled_up = LevelUpSystem.award_xp(player_entity, xp_amount)
		
		game_ui.update_level_info(
			player_entity.level,
			player_entity.xp,
			LevelUpSystem.xp_for_level(player_entity.level)
		)
		
		if leveled_up:
			_log("⬆ LEVEL UP! Now Level %d" % player_entity.level)
			_start_skill_draft()
			return
		
		dungeon_manager.complete_current_room()
		
		if _is_final_boss_victory:
			await get_tree().create_timer(1.0).timeout
			_show_victory_screen()
			return
		
		await get_tree().create_timer(1.0).timeout
		_on_room_completed()
	else:
		# Chest loot — just proceed
		dungeon_manager.complete_current_room()
		call_deferred("_on_room_completed")

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
	
	if _is_final_boss_victory:
		await get_tree().create_timer(1.0).timeout
		_show_victory_screen()
		return
	
	await get_tree().create_timer(1.0).timeout
	_on_room_completed()

# --- EVENTS ---

var _current_event: EventData = null
var _event_panel: EventPanel = null

func _start_event() -> void:
	current_state = State.EVENT
	game_ui.set_mode(false)
	
	var all_events = EventFactory.get_all_events()
	_current_event = EventSystem.pick_random_event(all_events, dungeon_manager.current_floor)
	
	if not _current_event:
		_log("Nothing of interest here.")
		dungeon_manager.complete_current_room()
		call_deferred("_on_room_completed")
		return
	
	_log("📜 %s" % _current_event.title)
	
	_event_panel = EventPanel.new()
	_event_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_ui.add_child(_event_panel)
	_event_panel.setup(_current_event)
	_event_panel.event_choice_made.connect(_on_event_choice)
	_event_panel.event_dismissed.connect(_on_event_dismissed)

func _on_event_choice(choice_index: int) -> void:
	if not _current_event or choice_index < 0 or choice_index >= _current_event.choices.size():
		return
	
	var choice = _current_event.choices[choice_index]
	var result_text = EventSystem.resolve_choice(player_entity, choice)
	
	_log(result_text)
	game_ui.update_hp(player_entity, true)
	
	# Update level info in case XP was gained
	game_ui.update_level_info(
		player_entity.level,
		player_entity.xp,
		LevelUpSystem.xp_for_level(player_entity.level)
	)
	
	# Handle RANDOM_LOOT outcomes
	var needs_loot = false
	if choice.outcome_type == EventChoice.OutcomeType.RANDOM_LOOT:
		needs_loot = true
	elif choice.outcome_type == EventChoice.OutcomeType.GAMBLE:
		# Check if gamble won and reward was loot
		if choice.gamble_win_type == EventChoice.OutcomeType.RANDOM_LOOT:
			# We can't easily know if we won, so check result text
			if result_text == choice.gamble_win_text or (choice.gamble_win_text == "" and result_text == "You got lucky!"):
				needs_loot = true
	
	if _event_panel:
		_event_panel.show_result(result_text)
	
	# If loot was awarded, we'll handle it after dismissal
	if needs_loot:
		_pending_loot_source = "chest" # Re-use chest flow
		_pending_loot.clear()
		var item = ItemFactory.generate_random_item(dungeon_manager.current_floor)
		if item:
			_pending_loot.append(item)

func _on_event_dismissed() -> void:
	if _event_panel:
		_event_panel.queue_free()
		_event_panel = null
	_current_event = null
	
	# Check if player died from event damage
	if not player_entity.is_alive():
		_show_game_over_screen()
		return
	
	# Process any pending loot from the event
	if not _pending_loot.is_empty():
		_process_loot_queue()
		return
	
	dungeon_manager.complete_current_room()
	call_deferred("_on_room_completed")

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

# --- GAME OVER / VICTORY ---

func _get_run_stats() -> Dictionary:
	var class_name_str = "Unknown"
	if Engine.has_meta("selected_class"):
		var cls = Engine.get_meta("selected_class") as ClassData
		if cls:
			class_name_str = cls.title
	
	return {
		"class_name": class_name_str,
		"level": player_entity.level if player_entity else 1,
		"floor": dungeon_manager.current_floor if dungeon_manager else 1,
		"depth": dungeon_manager.current_depth if dungeon_manager else 0,
		"rooms_cleared": dungeon_manager.rooms_completed if dungeon_manager else 0,
	}

func _show_game_over_screen() -> void:
	current_state = State.MENU
	game_ui.set_mode(false)
	
	var screen = GameOverScreen.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_ui.add_child(screen)
	screen.setup(_get_run_stats())
	screen.return_to_lobby.connect(_return_to_lobby)

func _show_victory_screen() -> void:
	current_state = State.MENU
	game_ui.set_mode(false)
	
	var screen = VictoryScreen.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_ui.add_child(screen)
	screen.setup(_get_run_stats())
	screen.return_to_lobby.connect(_return_to_lobby)

func _return_to_lobby() -> void:
	# Clean up Engine metas from this run
	if Engine.has_meta("selected_class"):
		Engine.remove_meta("selected_class")
	if Engine.has_meta("selected_camp_item"):
		Engine.remove_meta("selected_camp_item")
	if Engine.has_meta("selected_dungeon"):
		Engine.remove_meta("selected_dungeon")
	
	# Reset event bus
	GlobalEventBus.reset()
	
	# Return to lobby
	get_tree().change_scene_to_file("res://ui/lobby.tscn")
