class_name AttackAction
extends Action

var skill_reference: Skill

func _init(p_source: Node = null, p_target: Node = null) -> void:
	if p_source and p_target:
		super (p_source, p_target)

func execute() -> void:
	if not source or not target:
		print("Action failed: Invalid source or target")
		return

	if source.has_method("is_alive") and not source.is_alive():
		print("Action skipped: Source %s is dead" % source.name)
		return

	if not skill_reference:
		print("Action failed: No skill reference")
		return

	# Delegate to SkillExecutor
	SkillExecutor.execute(skill_reference, source as Entity, target as Entity)
