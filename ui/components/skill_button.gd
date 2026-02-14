class_name SkillButton
extends Button

var skill_reference: Skill

func setup(skill: Skill) -> void:
	skill_reference = skill
	text = skill.skill_name + "\nCD: %d" % skill.max_cooldown
	
	# Optional: Set icon if available
	# icon = skill.icon
