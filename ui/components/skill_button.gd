class_name SkillButton
extends Button

var skill_reference: Skill

func setup(skill: Skill) -> void:
	skill_reference = skill
	text = skill.skill_name + "\nCD: %d" % skill.max_cooldown
	
	# Optional: Set icon if available
	# icon = skill.icon

func update_cooldown(current_cd: int) -> void:
	if current_cd > 0:
		text = skill_reference.skill_name + "\n⏳ %d" % current_cd
		disabled = true
	else:
		text = skill_reference.skill_name + "\nCD: %d" % skill_reference.max_cooldown
		disabled = false
