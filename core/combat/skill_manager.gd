class_name SkillManager
extends Node

# Dictionary mapping Skill resource to current cooldown (int)
# { skill_resource: current_cooldown_turns }
var cooldowns: Dictionary = {}
var known_skills: Array[Skill] = []
var owner_entity: Node

func _init(p_owner: Node) -> void:
	owner_entity = p_owner

func learn_skill(skill: Skill) -> void:
	if not known_skills.has(skill):
		known_skills.append(skill)
		cooldowns[skill] = 0

func unlearn_skill(skill: Skill) -> void:
	if known_skills.has(skill):
		known_skills.erase(skill)
		cooldowns.erase(skill)

func is_skill_ready(skill: Skill) -> bool:
	return cooldowns.get(skill, 0) <= 0

func put_on_cooldown(skill: Skill) -> void:
	if skill.max_cooldown > 0:
		cooldowns[skill] = skill.max_cooldown

func tick_cooldowns() -> void:
	for skill in known_skills:
		if cooldowns[skill] > 0:
			cooldowns[skill] -= 1
			if cooldowns[skill] == 0:
				# Optional: Dispatch generic event "skill_ready"
				pass

func get_skill(index: int) -> Skill:
	if index >= 0 and index < known_skills.size():
		return known_skills[index]
	return null

func use_skill(skill: Skill, target: Entity) -> bool:
	if not known_skills.has(skill):
		print("Error: Entity %s does not know skill %s" % [owner_entity.name, skill.skill_name])
		return false
		
	if not is_skill_ready(skill):
		print("Skill %s is on cooldown! (%d turns)" % [skill.skill_name, cooldowns[skill]])
		return false
		
	# Execute
	skill.use(owner_entity, target)
	put_on_cooldown(skill)
	return true
