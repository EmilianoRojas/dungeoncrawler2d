class_name ToxinMasteryEffect
extends PassiveEffect

func execute(entity: Entity, data: Dictionary) -> void:
	var target = data.get("target") as Entity
	var skill = data.get("skill") as Skill
	if not target or not skill:
		return
	# Only trigger if the skill applies poison
	var has_poison = false
	for eff in skill.on_hit_effects:
		if eff is EffectResource and eff.effect_id == &"poison":
			has_poison = true
			break
	if not has_poison:
		return
	# Apply 1 extra poison stack — caster is passed so DoT scaling works automatically
	var poison_res = load("res://data/effects/poison.tres") as EffectResource
	if poison_res:
		target.effects.apply_effect(poison_res, entity)
		log_passive(entity, "Extra poison stack on %s" % target.name)
