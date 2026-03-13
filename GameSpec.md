# 📜 Game Design & Technical Specification (Roguelike Project)

> **Lenguaje del proyecto:** GDScript (Godot 4). Todos los scripts del juego están escritos en GDScript. No se utiliza C#.

---

## 1. Bucle de Juego Principal (Core Game Loop)
El juego sigue una estructura de *roguelike* con progresión por salas y reinicio de estadísticas al finalizar la "run".

1. **Preparación (Lobby/Inicio):**
   * El jugador selecciona una **Clase** (Ej. Warrior, Wizard).
   * Selecciona un **Camp Item** (Consumible inicial).
2. **Selección de Mazmorra:**
   * Se presentan 3 a 4 opciones de mazmorras/minas (algunas pueden estar bloqueadas por progreso o condiciones).
3. **Navegación de Nodos (Dungeon Crawling):** ✅ *Implementado en `core/map/`*
   * `DungeonManager` genera un árbol de nodos con profundidad configurable (`max_depth`, `boss_depth`).
   * El jugador ve las opciones actuales y puede previsualizar las salas siguientes (look-ahead de 1 capa).
   * La visibilidad de iconos es variable: hay un 15% de probabilidad de que los iconos de una sala estén ocultos (`icons_hidden = true`).
4. **Resolución de Salas:** Combate, recolección de cofres o eventos.
5. **Progresión de Piso:** Al derrotar al jefe del piso actual (Floor Boss), `DungeonManager` emite `floor_completed` y avanza al siguiente piso.
6. **Fin de la Partida (Muerte o Victoria):** Todos los niveles, habilidades y objetos se reinician a 0 para la siguiente *run*. El perfil de jugador persistente (`PlayerProfile`) registra los datos de la run.

---

## 2. Sistema de Generación de Salas (Room Generation)
### ✅ Implementado en `core/map/map_node.gd` y `core/map/dungeon_manager.gd`

Cada sala es un `MapNode` (Resource) en el árbol generado por `DungeonManager`.

### 2.1. Tipos de Nodo (`MapNode.Type`)

| Tipo | Descripción |
| :--- | :--- |
| **ENEMY** | Combate estándar. |
| **CHEST** | Recompensa de botín. |
| **EVENT** | Interacción narrativa o de azar. |
| **CAMP** | Zona de descanso/recuperación. |
| **BOSS** | Combate de fin de piso. |
| **ELITE** | Combate de alta dificultad con mejores recompensas. |

### 2.2. Modificadores de Piso (`MapNode.Modifier`)

| Modificador | Efecto |
| :--- | :--- |
| **TRACE** | El Boss aparece antes de lo habitual (`boss_depth = max_depth - 3`). |
| **SUBMERGED** | El Boss aparece más tarde (`boss_depth = max_depth + 3`). |
| **CATACOMB** | Aumenta el peso de salas ENEMY al 60% (vs. 45% normal). |

### 2.3. Lógica de Generación

- Al iniciar, `DungeonManager` lanza `_roll_floor_modifiers()` para determinar si hay modificador de piso activo (15% de probabilidad).
- **Boss garantizado** al alcanzar `boss_depth` (profundidad configurable).
- **Elite garantizado** exactamente en la mitad del piso (`depth == int(boss_depth * 0.5)`).
- La primera sala de cada piso es siempre **CAMP** (inicio seguro).
- Los nodos del árbol se conectan vía `MapNode.connected_nodes`; cada nodo puede tener hasta 4 iconos/modificadores simultáneos.

```gdscript
# Fragmento de dungeon_manager.gd — lógica de pesos
func _get_weighted_room_type(depth: int) -> MapNode.Type:
    if depth >= boss_depth:
        return MapNode.Type.BOSS
    if depth == int(boss_depth * 0.5):
        return MapNode.Type.ELITE
    var roll = randf()
    var enemy_weight = 0.45
    if floor_modifiers.has(MapNode.Modifier.CATACOMB):
        enemy_weight = 0.60
    if roll < enemy_weight:          return MapNode.Type.ENEMY
    elif roll < enemy_weight + 0.12: return MapNode.Type.EVENT
    elif roll < enemy_weight + 0.22: return MapNode.Type.CHEST
    elif roll < enemy_weight + 0.30: return MapNode.Type.CAMP
    elif roll < enemy_weight + 0.38: return MapNode.Type.ELITE
    else:                            return MapNode.Type.ENEMY
```

---

## 3. Estadísticas de Entidades (Stats System)
Tanto el jugador como los enemigos comparten un núcleo de estadísticas.

### Atributos Principales (Escalado)
* **STR** (Fuerza)
* **DEX** (Destreza)
* **INT** (Inteligencia)
* **PIE** (Piedad/Fe)
* **POW** (Poder): Atributo especial que contribuye al daño de **todas** las habilidades principales.

### Atributos de Combate y Supervivencia
* **MAXHP:** Vida máxima.
* **Shield:** Segunda barra de HP. Debe ser reducida a 0 antes de afectar el HP real. Se recupera al 100% tras cada batalla. Puede ser ignorada por la estadística de *Penetration*.
* **CRIT Chance:** Probabilidad de golpe crítico.
* **CRIT Damage:** Multiplicador de daño crítico.
* **Parry Chance:** Probabilidad de desviar un ataque.
* **Avoid Chance:** Probabilidad de evadir un ataque.

---

## 4. Sistema de Combate 1v1
El flujo de combate es estrictamente 1 contra 1. Si una sala genera múltiples enemigos, el jugador se enfrentará a ellos de forma secuencial.

### Habilidades (Skills)
El jugador tiene un número limitado de **Skill Slots**. Las habilidades tienen diferentes tipos de escalado y mecánicas de Cooldown. Las habilidades consumibles tienen un icono de una letra "E" en su contenedor.

| Nombre | Descripción | Escalado | Precisión (Hit) | CD (Turnos) |
| :--- | :--- | :--- | :--- | :--- |
| **Attack** | Ataque básico al enemigo. | 100% (STR) | 90 | 0 |
| **Tornado Slash**| Ataque poderoso al enemigo. | 800% (STR) | 50 | 5 |
| **Guard** | Acción defensiva. Otorga *Damage Reduce* por 1 turno. | POW: 50 | 1000 | 1 |
| **Observe** | Acción táctica. Otorga *Observation* por 1 turno. | N/A | 1000 | 0 |

### Progresión de Nivel ✅ *Implementado en `core/systems/level_up_system.gd`*
* **Level Up:** Al subir de nivel se ofrece una habilidad aleatoria al jugador.
* **Skill Draft UI:** ✅ *Implementado en `ui/components/skill_draft_panel.gd`* — Si los slots están llenos, el jugador debe reemplazar una habilidad o ignorar la nueva.
* **Reroll disponible:** ✅ *Implementado en `core/systems/currency_manager.gd`* — El jugador puede gastar moneda para cambiar la oferta:
  * Reroll de habilidad: **15 monedas** (`SKILL_REROLL_COST = 15`)
  * Reroll de equipamiento: **20 monedas** (`EQUIP_REROLL_COST = 20`)
  * La moneda es persistente (guardada en JSON en `user://currency_save.json`).
* **Mejora:** Reemplazar una habilidad por una idéntica aumenta su nivel (+1).

---

## 5. Sistema de Objetos (Itemization & Loot)
### ✅ Implementado en `core/factory/loot_system.gd` y `core/factory/reward_system.gd`

Los objetos se obtienen por un RNG al matar entidades.

* **Equipamiento:** Hasta 3 objetos equipados simultáneamente (Weapon, Armor, Helmet).
* **Stats Procedurales:** Los *stats* se basan en el piso actual, tipo de enemigo y la lógica del objeto base.
* **Rareza:** Existen objetos Legendarios con efectos pasivos únicos.
* **Tasas de drop:** Normal 20%, Elite 60%, Boss 100% (garantizado).
* Los jefes obtienen un bonus de +1 tier de rareza en el loot generado.

---

## 6. Sistema de Efectos Pasivos (Passive Effects)
Alteran el flujo del juego o los cálculos de daño.

* **Warrior (Super-strength):** Habilidades con baja precisión tienen mayor poder base.
* **Wizard (Hard Shield):** Reduce el daño recibido en un 30% si el *Shield* actual es >= 1. Negable por *Penetrate*.
* **Plating:** Ignora degradación de equipo y otorga resistencias.
* **Supply Route:** Reduce el CD de los *camp items* en -1 al entrar a una sala tipo "Torch".
* **Avoid Critical:** Reduce probabilidad de recibir críticos o ataques de Insta-kill.
* **Poisonous (+%):** Aumenta el daño de habilidades DoT (Daño en el tiempo).
* **Damage Reduce (+%):** Reduce el daño directo recibido.
* **Technique:** Aumenta *CRIT Chance* en base a tu Precisión (Hit) adicional.
* **Counter:** Reduce el CD de tus habilidades al recibir daño.
* **Weaken:** Reduce el poder del enemigo al infligirle daño.
* **Sniping:** Aumenta el poder base de los golpes críticos.
* **Swordmanship:** Al realizar un *Parry*, ganas el buff *Strengthen* por 5 turnos.
* **First Strike:** Probabilidad ocasional de reducir el CD de todas las habilidades en -1 al iniciar un combate.
* **Observation:** Permite ver el HP exacto del enemigo y su próxima acción.

---

## 7. Arquitectura Técnica (System Architecture)

> **El proyecto utiliza GDScript (Godot 4) como lenguaje principal.** No se utiliza C#. Toda la lógica de juego está en scripts `.gd` y los datos en Resources `.tres`.

Diseño híbrido basado en **Composición de Entidades**, **Diseño Basado en Datos** y un **Event Bus**.

### 7.1. Contenedores de Datos (Templates)
* **`SkillData`** (`core/combat/skill.gd`), **`ItemData`** (`core/items/equipment_resource.gd`), **`ClassData`** (`core/data/class_data.gd`), **`EnemyTemplate`** (`core/data/enemy_template.gd`): Archivos Resource (`.tres`) estáticos que definen las reglas base y habilidades garantizadas (Ej. El enemigo Vampiro siempre tiene *Vampiric Touch* en su `EnemyTemplate`).

### 7.2. Entidades de Batalla (`Entity`)
Tanto el jugador como los enemigos son instancias de `Entity` (`core/entity/entity.gd`), compuestas por:
* **`StatsComponent`** (`core/stats/stats_component.gd`): Gestiona HP, Shield y atributos.
* **`SkillManager`** (`core/combat/skill_manager.gd`): Ejecuta ataques y maneja Cooldowns.
* **`EquipmentComponent`** (`core/components/equipment_component.gd`): Suma las estadísticas de los ítems.
* **`EffectManager`** (`core/effects/effect_manager.gd`): Procesa Buffs, Debuffs y Pasivas.

### 7.3. Generación Procedural (Factories)
* **`ItemFactory`** (`core/factory/item_factory.gd`): Clona un `EquipmentResource` base y le añade stats y pasivas extra escaladas por el RNG y el piso actual.
* **`EnemyFactory`** (`core/factory/enemy_factory.gd`): Instancia un `Entity` vacío, inyecta el `EnemyTemplate` y multiplica sus estadísticas según el nivel del piso y los modificadores de la sala (Ej. *Elite*).

---

## 8. Motor de Combate y Ganchos (Event Bus Hooks)

Todas las pasivas del juego funcionan suscribiéndose a estos eventos para alterar el flujo sin código espagueti. El bus está implementado en `core/events/global_event_bus.gd`.

### 8.1. Eventos de Flujo de Juego
* `OnBattleStart`: Se dispara al iniciar el combate 1v1. (Ideal para *First Strike*).
* `OnBattleEnd`: Se dispara al morir el enemigo o el jugador. (Ideal para resetear el Shield).
* `OnTurnStart`: Al iniciar el turno de una entidad. (Ideal para aplicar daño de veneno/DoT).
* `OnTurnEnd`: Al finalizar el turno. (Ideal para reducir la duración de los Buffs/Debuffs).

### 8.2. Eventos de Acción y Combate
* `OnSkillCast`: Se dispara justo cuando se selecciona y usa una habilidad.
* `OnParrySuccess`: Cuando el RNG de evasión determina que hubo un Parry. (Ideal para *Swordmanship*).
* `OnAvoidSuccess`: Cuando el ataque falla por completo.

### 8.3. Fases de Cálculo de Daño (Damage Pipeline)
1. `OnBeforeDamageCalculated`: Antes de aplicar mitigaciones. (Ideal para *Super-strength* o *Sniping*).
2. `OnDamageCalculated`: El daño bruto ha sido definido.
3. `OnBeforeDamageTaken`: Justo antes de restar HP/Shield. (Ideal para *Hard Shield* o *Damage Reduce*).
4. `OnAfterDamageTaken`: Después de que el HP/Shield se redujo. (Ideal para *Counter*).
5. `OnDamageDealt`: Disparado desde la perspectiva del atacante tras impactar. (Ideal para *Weaken* o Robo de Vida).
6. `OnEntityDeath`: Se dispara si el HP llega a 0.

---

## 9. Estructura de Clases Core (Implementación en GDScript)

A continuación se describe la estructura de los componentes principales en GDScript / Godot 4, demostrando la arquitectura basada en composición y el uso del *Event Bus*.

### 9.1. Entity (El Nodo Principal)
`core/entity/entity.gd` — actúa como el "cerebro" que mantiene unidos todos los módulos. No calcula daño por sí misma; delega en sus componentes.

```gdscript
class_name Entity
extends Node

enum Team { PLAYER, ENEMY }

var initialized: bool = false
@export var team: Team = Team.ENEMY

# --- COMPONENTES ---
var stats: StatsComponent
var effects: EffectManager
var skills: SkillManager
var equipment: EquipmentComponent
var skill_component: SkillComponent
var passives: PassiveEffectComponent

func initialize() -> void:
    if initialized: return
    stats = StatsComponent.new()
    effects = EffectManager.new(self)
    skills = SkillManager.new(self)
    skill_component = SkillComponent.new(self)
    passives = PassiveEffectComponent.new()
    equipment = EquipmentComponent.new()
    equipment.initialize(self)
    equipment.stats_component = stats
    equipment.skill_component = skill_component
    equipment.passive_effect_component = passives
    initialized = true

func apply_class(class_data: ClassData) -> void:
    for key in class_data.base_stats:
        stats.set_base_stat(StringName(key), class_data.base_stats[key])
    stats.finalize_initialization()
    for s in class_data.starting_skills:
        skills.learn_skill(s)

func is_alive() -> bool:
    return stats.current.get(StatTypes.HP, 0) > 0
```

### 9.2. SkillManager (Controlador de Habilidades)
`core/combat/skill_manager.gd` — maneja la lista de habilidades aprendidas y sus cooldowns.

```gdscript
class_name SkillManager
extends Object

var owner: Entity
var known_skills: Array[Skill] = []
var cooldowns: Dictionary = {}
var max_skill_slots: int = 4

func learn_skill(skill: Skill) -> bool:
    for existing in known_skills:
        if existing.skill_name == skill.skill_name:
            return true  # Existe → upgrade path
    if known_skills.size() < max_skill_slots:
        known_skills.append(skill)
        cooldowns[skill] = 0
        return true
    return false  # Slots llenos → dispara Skill Draft UI

func is_ready(skill: Skill) -> bool:
    return cooldowns.get(skill, 0) <= 0

func start_cooldown(skill: Skill) -> void:
    cooldowns[skill] = skill.max_cooldown

func reduce_cooldowns(amount: int = 1) -> void:
    for skill in cooldowns:
        cooldowns[skill] = max(0, cooldowns[skill] - amount)
```

### 9.3. CombatContext y Skill (Estructuras de Datos de Combate)
`core/combat/combat_context.gd` y `core/combat/skill.gd`.

El `CombatContext` es un paquete de datos que viaja por todo el pipeline de daño:

```gdscript
class_name CombatContext
extends RefCounted

var source: Entity
var target: Entity
var skill: Skill

var damage: int = 0
var is_crit: bool = false
var is_kill: bool = false
var is_parry: bool = false
var is_avoided: bool = false
var is_penetrating: bool = false
var heal_amount: int = 0
var ignore_defense: bool = false
var stored_damage: int = 0
var effect_instance: EffectInstance = null
var raw_data: Dictionary = {}
```

El `Skill` es un Resource con datos de escalado:

```gdscript
class_name Skill
extends Resource

enum ScalingType { FLAT, STAT_PERCENT }

@export var skill_name: String = "Skill"
@export var scaling_type: ScalingType = ScalingType.STAT_PERCENT
@export var scaling_stat: StringName = StatTypes.STRENGTH
@export var scaling_percent: float = 1.0  # 1.0 = 100%
@export var on_cast_effects: Array[EffectResource] = []
@export var on_hit_effects: Array[EffectResource] = []
@export var base_power: int = 0
@export var max_cooldown: int = 0
@export var hit_chance: int = 90
@export var ignores_shield: bool = false
```

### 9.4. StatsComponent (Gestor de Estadísticas y Salud)
`core/stats/stats_component.gd` — almacena valores base, current y modificadores temporales. Usa `StringName` keys de `StatTypes` para máxima flexibilidad. Los modificadores soportan FLAT, PERCENT_ADD y MULTIPLIER.

La fórmula de cálculo es: `(Base + Flat) * (1 + %Add) * Mult`

Tras cada batalla, `reset_shield()` restaura el Shield al 100% (regla del GDD, llamada desde `GameLoop`).

### 9.5. EffectManager y EffectResource
`core/effects/effect_manager.gd` y `core/effects/effect_resource.gd`.

Cada efecto es un `EffectResource` (archivo `.tres`) con:
- **trigger:** cuándo se ejecuta (ON_SKILL_CAST, ON_DAMAGE_CALCULATED, ON_TURN_START, etc.)
- **operation:** qué hace (ADD_DAMAGE, REDUCE_DAMAGE_PERCENT, ADD_STAT_MODIFIER, HEAL, etc.)
- **stack_rule:** ADD / REFRESH / REPLACE / IGNORE
- **duration_turns:** -1 = infinito; >0 = duración temporal

`EffectManager.dispatch(trigger, context)` despacha el trigger a todos los efectos activos. La ejecución de operaciones se delega a `OperationExecutor` (`core/effects/operation_executor.gd`).

**Ejemplo conceptual — Pasiva "Berserker" (Doble Filo):**
Se implementa como dos `EffectResource.tres`:
- Uno con trigger `ON_PRE_DAMAGE_APPLY` (sobre el source) y operation `ADD_DAMAGE_PERCENT` con value `1.0` (duplicar daño saliente).
- Otro con trigger `ON_DAMAGE_RECEIVED_CALC` (sobre el target) y operation `ADD_DAMAGE_PERCENT` con value `1.0` (duplicar daño entrante).

Esto demuestra la filosofía data-driven: la pasiva existe como archivo de datos, sin código custom.

### 9.6. CombatSystem (Pipeline de Daño Completo)
`core/combat/combat_system.gd` — funciones estáticas que procesan el daño a través de todas las fases del pipeline, incluyendo Shield absorption y death check.

```gdscript
class_name CombatSystem
extends Object

static func deal_damage(context: CombatContext) -> void:
    var source = context.source
    var target = context.target
    if not target: return

    # STAGE 1: PRE CALC
    if source: source.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_CALC, context)
    # STAGE 2: OFFENSIVE
    if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_CALCULATED, context)
    # STAGE 3: DEFENSIVE
    target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_RECEIVED_CALC, context)
    # STAGE 4: FINAL
    if source: source.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY, context)
    target.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY, context)

    # === APPLY DAMAGE (Shield Absorption + Spillover) ===
    var remaining = context.damage
    if context.is_penetrating:
        target.stats.modify_current(StatTypes.HP, -remaining)
    else:
        var shield = target.stats.get_current(StatTypes.SHIELD)
        if shield > 0:
            if remaining <= shield:
                target.stats.modify_current(StatTypes.SHIELD, -remaining)
                remaining = 0
            else:
                remaining -= shield
                target.stats.modify_current(StatTypes.SHIELD, -shield)
        if remaining > 0:
            target.stats.modify_current(StatTypes.HP, -remaining)

    # POST DAMAGE
    if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, context)
    target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, context)
    GlobalEventBus.dispatch("damage_dealt", {
        "source": source, "target": target,
        "damage": context.damage, "is_crit": context.is_crit
    })

    # DEATH CHECK
    if target.stats.get_current(StatTypes.HP) <= 0:
        context.is_kill = true
        if source and source != target:
            source.effects.dispatch(EffectResource.Trigger.ON_KILL, context)
        target.effects.dispatch(EffectResource.Trigger.ON_DEATH, context)
        GlobalEventBus.dispatch("entity_died", {"entity": target, "killer": source})
```

### 9.7. SkillExecutor (Resolución de Habilidad con Combat Rolls)
`core/combat/skill_executor.gd` — orquesta la secuencia: Avoid → Hit → Parry → Damage Calc → Crit → Pipeline → Efectos.

```gdscript
class_name SkillExecutor
extends Object

static func execute(skill: Skill, source: Entity, target: Entity) -> void:
    var context = CombatContext.new(source, target, skill)
    context.is_penetrating = skill.ignores_shield

    # 1. ON_SKILL_CAST
    source.effects.dispatch(EffectResource.Trigger.ON_SKILL_CAST, context)

    # 2. Avoid check
    var avoid = target.stats.get_stat(StatTypes.AVOID_CHANCE)
    if avoid > 0 and randi() % 100 < avoid:
        context.is_avoided = true
        return

    # 3. Hit check
    var total_hit = skill.hit_chance + source.stats.get_stat(StatTypes.ACCURACY)
    if randi() % 100 >= total_hit:
        return

    # 4. Parry check
    var parry = target.stats.get_stat(StatTypes.PARRY_CHANCE)
    if parry > 0 and randi() % 100 < parry:
        context.is_parry = true
        GlobalEventBus.dispatch("parry_success", {"entity": target})
        return

    # 5. Base damage
    context.damage = FormulaCalculator.calculate_damage(skill, source)

    # 6. Crit roll
    var crit = source.stats.get_stat(StatTypes.CRIT_CHANCE)
    if crit > 0 and randi() % 100 < crit:
        context.is_crit = true
        context.damage = int(context.damage * source.stats.get_stat(StatTypes.CRIT_DAMAGE) / 100.0)

    # 7. Full pipeline
    CombatSystem.deal_damage(context)

    # 8. On-hit effects
    for effect in skill.on_cast_effects:
        source.effects.apply_effect(effect)
    for effect in skill.on_hit_effects:
        target.effects.apply_effect(effect)
```

### 9.8. Integración de Efectos Visuales (VFX Timing)
`ui/vfx_manager.gd` — gestiona la sincronización de efectos visuales con el pipeline de daño.

Para que los efectos visuales (Ej. una bola de hielo) se sincronicen con el daño matemático, el sistema desacopla el momento del "Casteo" del momento del "Impacto":

- **`ImpactDelay`** en el `Skill` Resource: valor en segundos entre el inicio del VFX y la aplicación del daño.
- El `SkillExecutor` usa `await get_tree().create_timer(skill.impact_delay).timeout` antes de llamar a `CombatSystem.deal_damage()`.
- Si la animación del efecto ocurre en el frame 45 de una animación a 60 FPS, el `ImpactDelay` sería `45.0 / 60.0 = 0.75` segundos.

**Decisión del Proyecto:** Se utiliza `ImpactDelay` definido en el `Skill` Resource para habilidades simples o instantáneas, manteniendo datos centralizados y sin modificar los assets visuales.

---

## 10. Generación y Escalado de Enemigos

El sistema es responsable de instanciar los adversarios. `EnemyFactory` (`core/factory/enemy_factory.gd`) toma un `EnemyTemplate`, inyecta sus datos en un `Entity` vacío y aplica escalado según el piso y los modificadores de sala.

### Lógica de Escalado por Piso
- Cada piso aplica un multiplicador (`1.0 + floor * 0.15`) sobre MAXHP y POW del template.
- Atributos secundarios como STR pueden escalar más lento (`1.0 + floor * 0.05`).
- Al finalizar el escalado, HP y Shield se restauran al máximo.

### Modificadores Elite y Boss
- **Elite:** +50% MAXHP, +20% POW, y se inyecta una pasiva aleatoria del pool de élite.
- **Boss:** +300% MAXHP respecto a un enemigo normal del mismo piso, pasivas de inmunidad a Insta-kill.

### 10.1. Mecánicas de Fase (Phase Transitions)
Los jefes pueden tener **Phase Passives**: efectos que escuchan el trigger `ON_DAMAGE_TAKEN` y comprueban el % de HP restante. Al caer por debajo del umbral (Ej. 50%), se dispara la Fase 2:
- Se alteran estadísticas dinámicamente.
- Se limpian debuffs activos.
- Se reducen cooldowns a 0 para un ataque inmediato.
- Se puede disparar un VFX de transición.

Todo esto sin código spagueti por jefe: se implementa como un `EffectResource.tres` reutilizable (`Enrage_At_Low_Health`) asignable desde el editor a cualquier `EnemyTemplate`.

### 10.2. Estructura de Directorios Real del Proyecto

```text
📦 dungeoncrawler2d/
 ┣ 📂 core/
 │   ┣ 📂 battle/          (turn_manager.gd)
 │   ┣ 📂 combat/          (combat_system.gd, skill_executor.gd, skill.gd, etc.)
 │   ┣ 📂 components/      (equipment_component.gd, passive_effect_component.gd, etc.)
 │   ┣ 📂 data/            (class_data.gd, enemy_template.gd, rune_resource.gd, etc.)
 │   ┣ 📂 effects/         (effect_manager.gd, effect_resource.gd, operation_executor.gd, etc.)
 │   ┣ 📂 entity/          (entity.gd)
 │   ┣ 📂 events/          (global_event_bus.gd)
 │   ┣ 📂 factory/         (enemy_factory.gd, item_factory.gd, loot_system.gd, reward_system.gd)
 │   ┣ 📂 items/           (camp_item_resource.gd, equipment_resource.gd)
 │   ┣ 📂 map/             (map_node.gd, dungeon_manager.gd) ✅
 │   ┣ 📂 meta/            (player_profile.gd, dungeon_progress.gd, inventory/) ✅
 │   ┣ 📂 rewards/         (reward_resource.gd)
 │   ┣ 📂 stats/           (stats_component.gd, stat_types.gd, stat_modifier.gd, etc.)
 │   ┣ 📂 systems/         (currency_manager.gd ✅, level_up_system.gd ✅, rune_manager.gd ✅, etc.)
 │   ┣ 📂 types/           (equipment_slot.gd)
 │   └ 📂 utils/           (game_rng.gd, resource_generator.gd)
 ┣ 📂 ui/
 │   ┣ 📂 components/      (skill_draft_panel.gd ✅, skill_button.gd, room_selector.gd, loot_panel.gd, rune_panel.gd, etc.)
 │   ┣ game_ui.gd
 │   ┣ lobby.gd
 │   ┣ vfx_manager.gd
 │   ┣ game_over_screen.gd
 │   └ victory_screen.gd
 ┗ 📂 data/
     ┣ 📂 skills/          (15 habilidades .tres)
     ┣ 📂 enemies/         (8 enemigos .tres)
     ┣ 📂 classes/         (8 clases .tres)
     ┣ 📂 dungeons/        (4 mazmorras .tres)
     ┣ 📂 effects/         (varios efectos .tres)
     ┣ 📂 camp_items/      (varios ítems de campamento .tres)
     └ 📂 assets/          (Icon1-48.png, Knight.png, Ronin.png)
```

---

## 11. Sistemas Implementados Adicionales

Esta sección documenta sistemas que estaban en desarrollo o no contemplados inicialmente en el spec, y que ya están implementados en el proyecto real.

### 11.1. Perfil de Jugador Persistente
**`core/meta/player_profile.gd`** (Autoload: `PlayerProfile`)

Registra la progresión meta entre runs:
- `runs_completed`, `runs_won`, `floors_explored`
- Nivel de perfil: sube cada 3 runs completadas (`get_level()`)
- Sistema de quests: First Steps, Veteran, Champion, First Win, Conqueror, Deep Diver
- Persiste en `user://player_profile.json`

### 11.2. Sistema de XP y Level Up
**`core/systems/level_up_system.gd`**

```gdscript
# XP requerida por nivel: 10 + level * 5
const XP_NORMAL: int = 10   # Enemigo común
const XP_ELITE: int  = 25   # Enemigo élite
const XP_BOSS: int   = 50   # Jefe de piso

static func xp_for_level(level: int) -> int:
    return 10 + level * 5
```

Al subir de nivel, `LevelUpSystem.get_skill_offer()` ofrece una habilidad aleatoria cargada de `res://data/skills/`. Si la habilidad ya existe en el inventario del jugador, se activa la ruta de upgrade (`find_upgrade_match`).

### 11.3. Sistema de Moneda y Reroll
**`core/systems/currency_manager.gd`** (Autoload: `CurrencyManager`)

```gdscript
const SKILL_REROLL_COST: int = 15
const EQUIP_REROLL_COST: int = 20
```

- `earn(amount)` — suma moneda y guarda.
- `spend(amount) -> bool` — resta moneda si hay saldo; retorna `false` si es insuficiente.
- `has_enough(amount) -> bool` — consulta sin modificar.
- Balance persistente en `user://currency_save.json`.

### 11.4. Sistemas de Loot y Recompensas
- **`core/factory/loot_system.gd`** — genera loot procedural de enemigos y cofres, aplicando tasas de drop según tier (Normal 20%, Elite 60%, Boss 100%) y bumpeando rareza en drops de jefe.
- **`core/factory/reward_system.gd`** — genera recompensas a partir de tablas de loot definidas en el `EnemyTemplate`.
- **`core/rewards/reward_resource.gd`** — Resource que encapsula una recompensa (ítem, moneda, etc.).

### 11.5. Sistema de Runas
- **`core/systems/rune_manager.gd`** — gestiona las runas activas del jugador durante la run.
- **`core/data/rune_resource.gd`** y **`core/data/rune_library.gd`** — definen los datos de runas disponibles.
- **`ui/components/rune_panel.gd`** — UI de gestión de runas.

Las runas son una capa de progresión paralela a las habilidades. Los detalles de mecánicas específicas se documentarán a medida que el sistema madure.

### 11.6. UI del Skill Draft
**`ui/components/skill_draft_panel.gd`** — implementa el panel de selección de habilidades al subir de nivel:
- Muestra la habilidad ofrecida.
- Permite seleccionar un slot para reemplazar (si los slots están llenos).
- Botón de Reroll que consume `SKILL_REROLL_COST` monedas via `CurrencyManager`.
- Detecta automáticamente si la oferta es un upgrade de una habilidad existente.

---

## 12. Notas de Diseño

### Por qué esta estructura es útil:
1. **Data-Driven:** Las pasivas como *Hard Shield* se implementan como archivos `.tres` con trigger `ON_DAMAGE_RECEIVED_CALC` y operation `REDUCE_DAMAGE_PERCENT`, sin código custom.
2. **Desacoplamiento:** `StatsComponent` no sabe qué efectos existen. Solo recibe el daño ya modificado.
3. **Fácil de expandir:** Nuevas pasivas como *Spiked Armor* se crean como otro `.tres` con trigger `ON_DAMAGE_TAKEN` y operation `ADD_DAMAGE` hacia el atacante.
4. **Escalado de Pisos:** El `floorMultiplier` en `EnemyFactory` es el punto central de balanceo. Cambiar el factor afecta automáticamente todos los enemigos del juego.
5. **Inyección de Élite:** Asignar pasivas aleatorias a enemigos élite (darle *Berserker* a un Vampiro) obliga al jugador a cambiar estrategia en cada run, incluso contra el mismo tipo de enemigo.
6. **Testabilidad:** Para probar la Fase 2 de un jefe, basta con reducir su HP en el editor; la pasiva `CheckHealthForPhase2` se dispara sola.
