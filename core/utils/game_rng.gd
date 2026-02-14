class_name GameRNG
extends Object

static var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

static func seed_rng(seed: int) -> void:
	_rng.seed = seed

static func roll_percent(chance: float) -> bool:
	# chance is 0.0 to 100.0 or 0.0 to 1.0? Let's standard on 0.0-1.0
	return _rng.randf() < chance

static func roll_damage(base: int, variation_percent: float = 0.1) -> int:
	var modification = base * variation_percent
	return int(base + _rng.randf_range(-modification, modification))
