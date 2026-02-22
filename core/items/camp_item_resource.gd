class_name CampItemResource
extends Resource

## Unique identifier (e.g. &"healing_herb")
@export var id: StringName = ""

## Display name shown in UI
@export var display_name: String = ""

## Description shown in tooltips and selection
@export var description: String = ""

## Badge character for skill slot display (GameSpec §4: "E" icon)
@export var icon_text: String = "E"

## Rooms between uses (0 = single use, consumed forever)
@export var max_cooldown: int = 3

## Effects applied when the item is used (heal, buff, etc.)
@export var effects: Array[EffectResource] = []

## If true, the item is destroyed after one use and cannot recharge
@export var is_consumable: bool = false
