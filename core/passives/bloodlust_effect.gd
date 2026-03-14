class_name BloodlustEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_bloodlust")
	var hp = entity.stats.get_current(StatTypes.HP)
	var max_hp = entity.stats.get_stat(StatTypes.MAX_HP)
	if max_hp <= 0:
		return
	var hp_percent = float(hp) / float(max_hp)
	var missing_percent = 1.0 - hp_percent
	var stacks = mini(int(missing_percent / 0.20), 5)
	if stacks <= 0:
		return
	var bonus = stacks * 0.05
	var mod = StatModifier.new()
	mod.stat = StatTypes.STRENGTH
	mod.type = StatModifier.Type.PERCENT_ADD
	mod.value = bonus
	entity.stats.add_modifier(mod, &"passive_bloodlust")
	log_passive(entity, "+%d%% STR (%d stacks, HP %d%%)" % [int(bonus * 100), stacks, int(hp_percent * 100)])

func cleanup(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_bloodlust")
