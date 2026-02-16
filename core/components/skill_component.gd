class_name SkillComponent
extends Node

# Active Skills Registry
# Key: skill_id (StringName) -> Value: { "resource": Skill, "source": source_id }
# Note: Since one skill could technically be granted by multiple sources, 
# we might need an array of sources if we want to support that. 
# For now, following simple plan: Source tracking.
var skills := {}

var owner_entity: Entity

func _init(entity: Entity) -> void:
	owner_entity = entity

func add_skill(skill: Skill, source_id: StringName) -> void:
	if not skill: return
	
	if not skills.has(skill):
		skills[skill] = []
	
	if not source_id in skills[skill]:
		skills[skill].append(source_id)
		_notify_skill_added(skill)

func remove_skills_from_source(source_id: StringName) -> void:
	var to_remove = []
	
	for skill in skills:
		var sources = skills[skill]
		if sources.has(source_id):
			sources.erase(source_id)
			
			if sources.is_empty():
				to_remove.append(skill)
	
	for skill in to_remove:
		skills.erase(skill)
		_notify_skill_removed(skill)

func _notify_skill_added(skill: Skill) -> void:
	if owner_entity and owner_entity.skills:
		owner_entity.skills.learn_skill(skill)
		print("SkillComponent: Added %s to SkillManager" % skill.skill_name)

func _notify_skill_removed(skill: Skill) -> void:
	if owner_entity and owner_entity.skills:
		owner_entity.skills.unlearn_skill(skill)
		print("SkillComponent: Removed %s from SkillManager" % skill.skill_name)
