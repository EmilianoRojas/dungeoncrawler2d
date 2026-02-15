class_name LifestealEffect
extends Effect

@export var percent: float = 0.5 # 50% lifesteal

func on_event(event_name: String, data: Dictionary) -> void:
    if event_name == "on_damage_dealt":
        var damage = data.get("damage", 0)
        var source = data.get("source") as Entity
        
        if source and damage > 0:
            var heal_amount = int(damage * percent)
            # Simplistic heal for now: modify base stat directly or assume we implement heal()
            # For this architecture demo, we'll just print and set variable
            print("Lifesteal triggered! Healing %d" % heal_amount)
            
            # Implementation of heal:
            var current_hp = source.stats.get_stat(StatsComponent.StatType.HP)
            source.stats.set_base_stat(StatsComponent.StatType.HP, current_hp + heal_amount)
