extends Node

## Tracks cross-run meta progression: runs, wins, floors explored.
## Registered as autoload "PlayerProfile" in project.godot.
## Persists to disk at user://player_profile.json.

const SAVE_PATH := "user://player_profile.json"
const XP_PER_RUN := 30
const XP_PER_LEVEL := 100

var runs_completed: int = 0
var runs_won: int = 0
var floors_explored: int = 0

func _ready() -> void:
	_load()

## Call after a run ends. won=true on victory. floors = how many floors reached.
func record_run(won: bool, floors: int) -> void:
	runs_completed += 1
	if won:
		runs_won += 1
	floors_explored += floors
	_save()

## Player level — increases every 3 runs.
func get_level() -> int:
	return 1 + runs_completed / 3

## XP within the current level (0 to get_xp_for_next_level - 1).
func get_xp() -> int:
	return runs_completed % 3

## XP needed for the next level (always 3 runs).
func get_xp_for_next_level() -> int:
	return 3

## Returns an Array of quest Dictionaries:
##   { title, desc, current, target, done }
func get_quests() -> Array:
	return [
		_q("First Steps",  "Complete your first run",    runs_completed, 1),
		_q("Veteran",      "Complete 5 runs",            runs_completed, 5),
		_q("Champion",     "Complete 10 runs",           runs_completed, 10),
		_q("First Win",    "Win a dungeon run",          runs_won,       1),
		_q("Conqueror",    "Win 3 runs",                 runs_won,       3),
		_q("Deep Diver",   "Explore 15 floors total",    floors_explored, 15),
	]

func _q(title: String, desc: String, current: int, target: int) -> Dictionary:
	return {
		"title":   title,
		"desc":    desc,
		"current": mini(current, target),
		"target":  target,
		"done":    current >= target,
	}

func _save() -> void:
	var data := {
		"runs_completed":  runs_completed,
		"runs_won":        runs_won,
		"floors_explored": floors_explored,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data = json.get_data()
	if not data is Dictionary:
		return
	runs_completed  = int(data.get("runs_completed",  0))
	runs_won        = int(data.get("runs_won",        0))
	floors_explored = int(data.get("floors_explored", 0))
