class_name EventData
extends Resource

## A dungeon event with narrative text and player choices.

@export var event_id: StringName = ""
@export var title: String = "Event"
@export var description: String = ""
@export var choices: Array[EventChoice] = []

## Minimum floor this event can appear on (0 = any)
@export var min_floor: int = 0
## Maximum floor (0 = no limit)
@export var max_floor: int = 0
## Weight for random selection (higher = more likely)
@export var weight: float = 1.0
