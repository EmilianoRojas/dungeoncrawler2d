class_name CurrencyManager
extends Node

const SAVE_PATH: String = "user://currency_save.json"
const SKILL_REROLL_COST: int  = 15
const EQUIP_REROLL_COST: int  = 20

var balance: int = 0

signal balance_changed(new_balance: int)

func _ready() -> void:
	load_currency()

# --- API ---

func earn(amount: int) -> void:
	balance += amount
	save_currency()
	balance_changed.emit(balance)

func spend(amount: int) -> bool:
	if balance < amount:
		return false
	balance -= amount
	save_currency()
	balance_changed.emit(balance)
	return true

func has_enough(amount: int) -> bool:
	return balance >= amount

# --- Persistence ---

func save_currency() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"balance": balance}))
		file.close()

func load_currency() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data = json.get_data()
	if data is Dictionary and data.has("balance"):
		balance = int(data["balance"])
