class_name DungeonProgress
extends Object

## Tracks which dungeons have been cleared across runs.
## NOTE: This does not persist to disk yet — resets when the game closes.

static var cleared_dungeons: Array[StringName] = []

## Check if a dungeon is unlocked based on its unlock_requires field.
static func is_unlocked(dungeon: DungeonData) -> bool:
	if dungeon.unlock_requires == &"":
		return true
	return cleared_dungeons.has(dungeon.unlock_requires)

## Mark a dungeon as cleared.
static func mark_cleared(dungeon_id: StringName) -> void:
	if not cleared_dungeons.has(dungeon_id):
		cleared_dungeons.append(dungeon_id)
		print("DungeonProgress: Marked '%s' as cleared" % dungeon_id)

## Reset all progress (for testing or new save).
static func reset() -> void:
	cleared_dungeons.clear()
