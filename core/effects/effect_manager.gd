class_name EffectManager
extends Object

var owner: Entity
var effects: Array[EffectInstance] = []

func _init(entity: Entity):
    owner = entity

func apply_effect(effect_res: EffectResource) -> void:
    var existing = _find_instance(effect_res.effect_id)
    
    if existing == null:
        effects.append(EffectInstance.new(effect_res))
        print("Effect %s added." % effect_res.effect_id)
        return
    
    match effect_res.stack_rule:
        EffectResource.StackRule.ADD:
            existing.stacks = min(existing.stacks + 1, effect_res.max_stacks)
            existing.remaining_turns = effect_res.duration_turns # Refresh duration usually implied on add
            print("Effect %s stacked. Count: %d" % [effect_res.effect_id, existing.stacks])
            
        EffectResource.StackRule.REFRESH:
            existing.remaining_turns = effect_res.duration_turns
            print("Effect %s refreshed." % effect_res.effect_id)
            
        EffectResource.StackRule.REPLACE:
            effects.erase(existing)
            effects.append(EffectInstance.new(effect_res))
            print("Effect %s replaced." % effect_res.effect_id)
            
        EffectResource.StackRule.IGNORE:
            print("Effect %s ignored." % effect_res.effect_id)
            pass

func _find_instance(id: StringName) -> EffectInstance:
    if id == "": return null
    for instance in effects:
        if instance.resource.effect_id == id:
            return instance
    return null

func tick_all() -> void:
    for instance in effects:
        instance.tick_duration()
    
    # Remove expired
    var active_effects: Array[EffectInstance] = []
    for instance in effects:
        if not instance.is_expired():
            active_effects.append(instance)
        else:
            print("Effect %s expired." % instance.resource.effect_id)
    
    effects = active_effects

func dispatch(trigger: EffectResource.Trigger, data: Dictionary) -> void:
    for instance in effects:
        if instance.resource.trigger == trigger:
            OperationExecutor.execute(instance, owner, data)

