class_name OperationExecutor
extends Object

static func execute(instance: EffectInstance, owner: Entity, data: Dictionary) -> void:
    # Proc Check
    if instance.resource.proc_chance < 1.0:
        if randf() > instance.resource.proc_chance:
            return

    var effect = instance.resource
    match effect.operation:

        EffectResource.Operation.HEAL_PERCENT:
            _heal_percent(instance, owner, data)

        EffectResource.Operation.HEAL_FLAT:
            _heal_flat(instance, owner)

        EffectResource.Operation.MODIFY_STAT_PERCENT:
            _modify_stat_percent(instance, owner)

        EffectResource.Operation.DEAL_DAMAGE_PERCENT_BACK:
            _thorns(instance, owner, data)

# 🧪 Implementaciones reales

# Lifesteal
static func _heal_percent(instance: EffectInstance, owner: Entity, data: Dictionary):
    var effect = instance.resource
    var damage = data.get("damage", 0)
    # Scale with stacks? e.g. 50% * 2 stacks = 100%? Or just duration stacking?
    # For now, let's assume intensity stacking for percent effects too.
    var value = effect.value * instance.stacks
    var heal = int(damage * value)
    
    if owner.has_method("get_stats") or "stats" in owner:
        owner.stats.modify_current(StatsComponent.StatType.HP, heal)

# Heal flat
static func _heal_flat(instance: EffectInstance, owner: Entity):
    var effect = instance.resource
    var value = effect.value * instance.stacks
    if owner.has_method("get_stats") or "stats" in owner:
        owner.stats.modify_current(StatsComponent.StatType.HP, int(value))

# Thorns
static func _thorns(instance: EffectInstance, owner: Entity, data: Dictionary):
    var effect = instance.resource
    var attacker = data.get("source")
    if attacker and attacker is Entity:
        var damage = data.get("damage", 0)
        var value = effect.value * instance.stacks
        var reflected = int(damage * value)
        
        CombatSystem.deal_damage(owner, attacker, reflected)

# Stat buff
static func _modify_stat_percent(instance: EffectInstance, owner: Entity):
    var effect = instance.resource
    var stat = effect.stat_type
    if owner.has_method("get_stats") or "stats" in owner:
        var base = owner.stats.get_stat(stat)
        var value = effect.value * instance.stacks
        var bonus = int(base * value)
        
        owner.stats.add_bonus(stat, bonus)
