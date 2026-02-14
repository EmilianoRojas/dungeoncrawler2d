class_name AttackAction
extends Action

var damage: int = 0
var skill_reference: Skill

func _init(p_source: Entity = null, p_target: Entity = null) -> void:
	if p_source and p_target:
		super (p_source, p_target)

func execute() -> void:
	if not source or not target:
		print("Action failed: Invalid source or target")
		return

	print("Executing AttackAction: %s -> %s" % [source.name, target.name])
	GlobalEventBus.dispatch("before_damage", {"source": source, "target": target})
	
	var damage = self.damage
	if source.stats:
		var strength = source.stats.get_stat("strength")
		damage += strength
		print("Checking Stats - Strength: %d. Total Damage: %d" % [strength, damage])
	
	CombatSystem.deal_damage(source, target, damage)
	GlobalEventBus.dispatch("after_damage", {"source": source, "target": target})
