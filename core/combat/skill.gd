class_name Skill
extends Resource

@export var skill_name: String = "Skill"
@export var scaling_stat: StatsComponent.StatType = StatsComponent.StatType.STRENGTH
@export var multiplier: float = 1.0
@export var max_cooldown: int = 0 # in turns


func use(user: Node, target: Node) -> void:
    # Calculate raw damage based on stats
    var user_entity = user
    var stat_value = 0
    if user_entity.get("stats"):
        stat_value = user_entity.stats.get_stat(scaling_stat)
        
    var damage = int(stat_value * multiplier)
    
    # Pass to CombatSystem to handle the rest (events, mitigation, etc)
    # We use a static reference or singleton for CombatSystem
    if user_entity and target:
        CombatSystem.deal_damage(user_entity, target, damage)
