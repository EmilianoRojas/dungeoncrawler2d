class_name EventChoice
extends Resource

## A single choice in a dungeon event.

@export var label: String = "Continue"
@export var description: String = "" # Hint text shown under the button

## Outcome type
enum OutcomeType {
	HEAL_PERCENT,     # Heal % of max HP
	DAMAGE_PERCENT,   # Lose % of current HP
	HEAL_FLAT,        # Heal flat amount
	DAMAGE_FLAT,      # Lose flat amount
	GAIN_XP,          # Gain XP
	RANDOM_LOOT,      # Get a random equipment drop
	STAT_BUFF,        # Temporary stat boost (rest of run)
	NOTHING,          # Nothing happens
	GAMBLE,           # Random: either reward or punishment
}

@export var outcome_type: OutcomeType = OutcomeType.NOTHING

## Primary value for the outcome (percentage, flat amount, XP, etc.)
@export var value: float = 0.0

## For GAMBLE: the reward outcome if you win
@export var gamble_win_type: OutcomeType = OutcomeType.NOTHING
@export var gamble_win_value: float = 0.0
## For GAMBLE: the punishment outcome if you lose
@export var gamble_lose_type: OutcomeType = OutcomeType.NOTHING
@export var gamble_lose_value: float = 0.0
## For GAMBLE: chance of winning (0.0 - 1.0)
@export var gamble_chance: float = 0.5

## For STAT_BUFF: which stat to buff
@export var buff_stat: StringName = ""

## Secondary outcome (applied after primary, e.g. stat buff after HP cost)
@export var secondary_type: OutcomeType = OutcomeType.NOTHING
@export var secondary_value: float = 0.0
@export var secondary_buff_stat: StringName = ""

## Result text shown after choosing
@export var result_text: String = ""
## Gamble win/lose result texts
@export var gamble_win_text: String = ""
@export var gamble_lose_text: String = ""
