class_name SkillExecutor
extends Object

static func execute(skill: Skill, source: Entity, target: Entity) -> void:
	if not skill or not source or not target:
		push_error("SkillExecutor: Invalid arguments")
		return

	var damage = FormulaCalculator.calculate_damage(skill, source)
	
	CombatSystem.deal_damage(source, target, damage)
