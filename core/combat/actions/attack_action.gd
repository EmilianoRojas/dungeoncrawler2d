class_name AttackAction
extends Action

var damage: int = 0
var skill_reference: Skill

func _init(p_source: Node = null, p_target: Node = null) -> void:
	if p_source and p_target:
		super (p_source, p_target)

func execute() -> void:
	if not source or not target:
		print("Action failed: Invalid source or target")
		return

	print("Executing AttackAction: %s -> %s" % [source.name, target.name])
	GlobalEventBus.dispatch("before_damage", {"source": source, "target": target})
	
	var damage = self.damage
	
	var source_entity = source
	var target_entity = target
	
	if source_entity and source_entity.get("stats"):
		var strength = source_entity.stats.get_stat(StatsComponent.StatType.STRENGTH)
		damage += strength
		print("Checking Stats - Strength: %d. Total Damage: %d" % [strength, damage])
	
	if source_entity and target_entity:
		CombatSystem.deal_damage(source_entity, target_entity, damage)
	GlobalEventBus.dispatch("after_damage", {"source": source, "target": target})
