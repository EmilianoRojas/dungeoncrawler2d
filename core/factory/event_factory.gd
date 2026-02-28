class_name EventFactory
extends Object

## Builds the pool of dungeon events. Each event is created in code
## so we don't need .tres files for now.

static func get_all_events() -> Array[EventData]:
	var events: Array[EventData] = []
	events.append(_mysterious_fountain())
	events.append(_wandering_merchant())
	events.append(_ancient_altar())
	events.append(_trapped_chest())
	events.append(_old_warrior())
	events.append(_cursed_shrine())
	events.append(_abandoned_camp())
	events.append(_strange_mushrooms())
	return events

# --- Event Definitions ---

static func _mysterious_fountain() -> EventData:
	var event = EventData.new()
	event.event_id = "mysterious_fountain"
	event.title = "Mysterious Fountain"
	event.description = "You find a glowing fountain in the center of the room. The water shimmers with an otherworldly light. Do you drink?"
	event.weight = 1.0
	
	var drink = EventChoice.new()
	drink.label = "🥤 Drink the water"
	drink.description = "50% chance: Full heal or lose 30% HP"
	drink.outcome_type = EventChoice.OutcomeType.GAMBLE
	drink.gamble_chance = 0.5
	drink.gamble_win_type = EventChoice.OutcomeType.HEAL_PERCENT
	drink.gamble_win_value = 100.0
	drink.gamble_win_text = "The water fills you with warmth. Fully healed!"
	drink.gamble_lose_type = EventChoice.OutcomeType.DAMAGE_PERCENT
	drink.gamble_lose_value = 30.0
	drink.gamble_lose_text = "The water burns! It was poisoned..."
	
	var leave = EventChoice.new()
	leave.label = "🚪 Walk away"
	leave.description = "Play it safe"
	leave.outcome_type = EventChoice.OutcomeType.NOTHING
	leave.result_text = "You leave the fountain untouched."
	
	var _choices: Array[EventChoice] = [drink, leave]
	event.choices = _choices
	return event

static func _wandering_merchant() -> EventData:
	var event = EventData.new()
	event.event_id = "wandering_merchant"
	event.title = "Wandering Merchant"
	event.description = "A hooded figure blocks your path. \"Trade your blood for power, adventurer?\" they whisper."
	event.weight = 1.0
	
	var trade = EventChoice.new()
	trade.label = "💉 Trade HP for STR"
	trade.description = "Lose 20% HP, gain +3 STR permanently"
	trade.outcome_type = EventChoice.OutcomeType.DAMAGE_PERCENT
	trade.value = 20.0
	trade.secondary_type = EventChoice.OutcomeType.STAT_BUFF
	trade.secondary_value = 3.0
	trade.secondary_buff_stat = StatTypes.STRENGTH
	trade.result_text = "Pain surges through you... but you feel stronger. STR +3!"
	
	var trade2 = EventChoice.new()
	trade2.label = "🧠 Trade HP for INT"
	trade2.description = "Lose 20% HP, gain +3 INT permanently"
	trade2.outcome_type = EventChoice.OutcomeType.DAMAGE_PERCENT
	trade2.value = 20.0
	trade2.secondary_type = EventChoice.OutcomeType.STAT_BUFF
	trade2.secondary_value = 3.0
	trade2.secondary_buff_stat = StatTypes.INTELLIGENCE
	trade2.result_text = "Your mind expands as your body weakens. INT +3!"
	
	var decline = EventChoice.new()
	decline.label = "🚪 Decline"
	decline.description = "Keep your blood"
	decline.outcome_type = EventChoice.OutcomeType.NOTHING
	decline.result_text = "\"Your loss...\" The figure vanishes."
	
	var _choices: Array[EventChoice] = [trade, trade2, decline]
	event.choices = _choices
	return event

static func _ancient_altar() -> EventData:
	var event = EventData.new()
	event.event_id = "ancient_altar"
	event.title = "Ancient Altar"
	event.description = "A crumbling stone altar radiates dark energy. Ancient runes promise power to those who sacrifice."
	event.weight = 0.8
	
	var pray = EventChoice.new()
	pray.label = "🙏 Pray at the altar"
	pray.description = "Gain +50 XP"
	pray.outcome_type = EventChoice.OutcomeType.GAIN_XP
	pray.value = 50.0
	pray.result_text = "The altar accepts your prayer. You feel enlightened."
	
	var sacrifice = EventChoice.new()
	sacrifice.label = "🩸 Blood sacrifice"
	sacrifice.description = "Lose 15 HP, gain +100 XP"
	sacrifice.outcome_type = EventChoice.OutcomeType.DAMAGE_FLAT
	sacrifice.value = 15.0
	sacrifice.secondary_type = EventChoice.OutcomeType.GAIN_XP
	sacrifice.secondary_value = 100.0
	sacrifice.result_text = "Blood flows over the runes. Ancient knowledge floods your mind. +100 XP!"
	
	var ignore = EventChoice.new()
	ignore.label = "🚪 Leave it alone"
	ignore.outcome_type = EventChoice.OutcomeType.NOTHING
	ignore.result_text = "Best not to meddle with dark forces."
	
	var _choices: Array[EventChoice] = [pray, sacrifice, ignore]
	event.choices = _choices
	return event

static func _trapped_chest() -> EventData:
	var event = EventData.new()
	event.event_id = "trapped_chest"
	event.title = "Suspicious Chest"
	event.description = "A chest sits in the corner, slightly ajar. Something about it feels... wrong."
	event.weight = 1.0
	
	var open = EventChoice.new()
	open.label = "📦 Open it"
	open.description = "60% loot, 40% trap"
	open.outcome_type = EventChoice.OutcomeType.GAMBLE
	open.gamble_chance = 0.6
	open.gamble_win_type = EventChoice.OutcomeType.RANDOM_LOOT
	open.gamble_win_value = 1.0
	open.gamble_win_text = "Inside you find something useful!"
	open.gamble_lose_type = EventChoice.OutcomeType.DAMAGE_FLAT
	open.gamble_lose_value = 20.0
	open.gamble_lose_text = "TRAP! A spike shoots out and pierces you!"
	
	var kick = EventChoice.new()
	kick.label = "🦵 Kick it open (carefully)"
	kick.description = "Safe but only get XP"
	kick.outcome_type = EventChoice.OutcomeType.GAIN_XP
	kick.value = 25.0
	kick.result_text = "You disarm the trap. A few coins scatter — not much, but it's something."
	
	var _choices: Array[EventChoice] = [open, kick]
	event.choices = _choices
	return event

static func _old_warrior() -> EventData:
	var event = EventData.new()
	event.event_id = "old_warrior"
	event.title = "Fallen Warrior"
	event.description = "A wounded warrior sits against the wall, barely alive. \"Help me... or take my gear. Your choice.\""
	event.weight = 0.8
	
	var help = EventChoice.new()
	help.label = "💚 Help them"
	help.description = "Lose 10 HP, gain +2 DEX permanently"
	help.outcome_type = EventChoice.OutcomeType.DAMAGE_FLAT
	help.value = 10.0
	help.secondary_type = EventChoice.OutcomeType.STAT_BUFF
	help.secondary_value = 2.0
	help.secondary_buff_stat = StatTypes.DEXTERITY
	help.result_text = "You share your supplies. \"Thank you... take this technique I've learned.\" DEX +2!"
	
	var loot_them = EventChoice.new()
	loot_them.label = "🗡️ Take their gear"
	loot_them.description = "Random equipment drop"
	loot_them.outcome_type = EventChoice.OutcomeType.RANDOM_LOOT
	loot_them.value = 1.0
	loot_them.result_text = "You take what you need. They won't be needing it much longer..."
	
	var leave = EventChoice.new()
	leave.label = "🚪 Walk past"
	leave.outcome_type = EventChoice.OutcomeType.NOTHING
	leave.result_text = "You move on. No time for sentiment."
	
	var _choices: Array[EventChoice] = [help, loot_them, leave]
	event.choices = _choices
	return event

static func _cursed_shrine() -> EventData:
	var event = EventData.new()
	event.event_id = "cursed_shrine"
	event.title = "Cursed Shrine"
	event.description = "A dark shrine pulses with forbidden power. Touching it could make you stronger... or destroy you."
	event.weight = 0.6
	event.min_floor = 2
	
	var touch = EventChoice.new()
	touch.label = "✋ Touch the shrine"
	touch.description = "40% chance: +5 POW or lose 40% HP"
	touch.outcome_type = EventChoice.OutcomeType.GAMBLE
	touch.gamble_chance = 0.4
	touch.gamble_win_type = EventChoice.OutcomeType.STAT_BUFF
	touch.gamble_win_value = 5.0
	touch.buff_stat = StatTypes.POWER
	touch.gamble_win_text = "Dark power surges through you! POW +5!"
	touch.gamble_lose_type = EventChoice.OutcomeType.DAMAGE_PERCENT
	touch.gamble_lose_value = 40.0
	touch.gamble_lose_text = "The curse lashes out! Your body burns with dark energy."
	
	var avoid = EventChoice.new()
	avoid.label = "🚪 Stay away"
	avoid.outcome_type = EventChoice.OutcomeType.NOTHING
	avoid.result_text = "Wisdom is knowing when not to gamble."
	
	var _choices: Array[EventChoice] = [touch, avoid]
	event.choices = _choices
	return event

static func _abandoned_camp() -> EventData:
	var event = EventData.new()
	event.event_id = "abandoned_camp"
	event.title = "Abandoned Camp"
	event.description = "You stumble upon a recently abandoned campsite. Embers still glow in the fire pit. Some supplies remain."
	event.weight = 1.2
	
	var rest = EventChoice.new()
	rest.label = "🔥 Rest by the fire"
	rest.description = "Heal 25% HP"
	rest.outcome_type = EventChoice.OutcomeType.HEAL_PERCENT
	rest.value = 25.0
	rest.result_text = "The warmth soothes your wounds."
	
	var search = EventChoice.new()
	search.label = "🔍 Search the camp"
	search.description = "Gain +30 XP"
	search.outcome_type = EventChoice.OutcomeType.GAIN_XP
	search.value = 30.0
	search.result_text = "You find some notes about dungeon patterns. Useful knowledge."
	
	var _choices: Array[EventChoice] = [rest, search]
	event.choices = _choices
	return event

static func _strange_mushrooms() -> EventData:
	var event = EventData.new()
	event.event_id = "strange_mushrooms"
	event.title = "Strange Mushrooms"
	event.description = "Glowing mushrooms grow along the walls. They smell sweet... almost too sweet."
	event.weight = 0.9
	
	var eat = EventChoice.new()
	eat.label = "🍄 Eat one"
	eat.description = "50% chance: Heal 40% or lose 15% HP"
	eat.outcome_type = EventChoice.OutcomeType.GAMBLE
	eat.gamble_chance = 0.5
	eat.gamble_win_type = EventChoice.OutcomeType.HEAL_PERCENT
	eat.gamble_win_value = 40.0
	eat.gamble_win_text = "Delicious! You feel revitalized."
	eat.gamble_lose_type = EventChoice.OutcomeType.DAMAGE_PERCENT
	eat.gamble_lose_value = 15.0
	eat.gamble_lose_text = "Your stomach churns... that was a bad idea."
	
	var collect = EventChoice.new()
	collect.label = "🧪 Collect samples"
	collect.description = "Gain +20 XP"
	collect.outcome_type = EventChoice.OutcomeType.GAIN_XP
	collect.value = 20.0
	collect.result_text = "You carefully collect a few specimens. Might come in handy."
	
	var ignore = EventChoice.new()
	ignore.label = "🚪 Ignore them"
	ignore.outcome_type = EventChoice.OutcomeType.NOTHING
	ignore.result_text = "You walk past. Not everything needs to be touched."
	
	var _choices: Array[EventChoice] = [eat, collect, ignore]
	event.choices = _choices
	return event
