# 📜 Game Design & Technical Specification (Roguelike Project)

## 1. Bucle de Juego Principal (Core Game Loop)
El juego sigue una estructura de *roguelike* con progresión por salas y reinicio de estadísticas al finalizar la "run".

1. **Preparación (Lobby/Inicio):**
   * El jugador selecciona una **Clase** (Ej. Warrior, Wizard).
   * Selecciona un **Camp Item** (Consumible inicial).
2. **Selección de Mazmorra:**
   * Se presentan 3 a 4 opciones de mazmorras/minas (algunas pueden estar bloqueadas por progreso o condiciones).
3. **Navegación de Nodos (Dungeon Crawling):**
   * Estructura de árbol de nodos. El jugador ve 2 salas actuales y puede previsualizar las 2 salas siguientes.
   * La visibilidad es variable (a veces los iconos superiores están ocultos, a veces los caminos están bloqueados).
4. **Resolución de Salas:** Combate, recolección de cofres o eventos.
5. **Progresión de Piso:** Al derrotar al jefe del piso actual (Floor Boss), se desbloquea el acceso al siguiente piso.
6. **Fin de la Partida (Muerte o Victoria):** Todos los niveles, habilidades y objetos se reinician a 0 para la siguiente *run*.

---

## 2. Sistema de Generación de Salas (Room Generation)
Cada sala es un nodo en el mapa y está definida por una serie de **Iconos (Modificadores)**. Una sala puede tener hasta 4 iconos simultáneos.

**Tipos de Iconos / Eventos de Sala:**
* **Enemy:** Combate estándar.
* **Chest:** Recompensa de botín.
* **Event:** Interacción narrativa o de azar.
* **Camp:** Zona de descanso/recuperación.
* **Boss:** Combate de fin de piso.
* **Elite Enemy:** Combate de alta dificultad con mejores recompensas.
* **Trace:** Modificador de piso (El Boss aparece antes de lo habitual).
* **Submerged:** Modificador de piso (El Boss aparece más tarde).
* **Catacomb:** Modificador de piso (Aumenta la tasa de aparición de enemigos).

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

### Progresión de Nivel
* **Level Up:** Otorga una habilidad aleatoria al subir de nivel.
* **Skill Draft UI:** Si los slots están llenos, el jugador debe reemplazar una habilidad o ignorar la nueva. Reroll disponible gastando moneda.
* **Mejora:** Reemplazar una habilidad por una idéntica aumenta su nivel (+1).

---

## 5. Sistema de Objetos (Itemization & Loot)
Los objetos se obtienen por un RNG al matar entidades. 

* **Equipamiento:** Hasta 3 objetos equipados simultáneamente (Weapon, Armor, Helmet).
* **Stats Procedurales:** Los *stats* se basan en el piso actual, tipo de enemigo y la lógica del objeto base.
* **Rareza:** Existen objetos Legendarios con efectos pasivos únicos.

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
Diseño híbrido basado en **Composición de Entidades**, **Diseño Basado en Datos** y un **Event Bus**.

### 7.1. Contenedores de Datos (Templates)
* **`SkillData`**, **`ItemData`**, **`ClassData`**, **`EnemyTemplate`**: Archivos estáticos que definen las reglas base y habilidades garantizadas (Ej. El enemigo Vampiro siempre tiene *Vampiric Touch* en su `EnemyTemplate`).

### 7.2. Entidades de Batalla (`BattleEntity`)
Tanto el jugador como los enemigos son instancias de `BattleEntity`, compuestas por:
* **`StatsComponent`**: Gestiona HP, Shield y atributos.
* **`SkillController`**: Ejecuta ataques y maneja Cooldowns.
* **`EquipmentManager`**: Suma las estadísticas de los ítems.
* **`EffectReceiver`**: Procesa Buffs, Debuffs y Pasivas.

### 7.3. Generación Procedural (Factories)
* **`ItemFactory`**: Clona un `ItemData` base y le añade stats y pasivas extra escaladas por el RNG y el piso actual.
* **`EnemySpawner`**: Instancia un `BattleEntity` vacío, inyecta el `EnemyTemplate` y multiplica sus estadísticas según el nivel del piso y los modificadores de la sala (Ej. *Elite*).

---

## 8. Motor de Combate y Ganchos (Event Bus Hooks)

Todas las pasivas del juego funcionan suscribiéndose a estos eventos para alterar el flujo sin modificar el código espagueti.

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

## 9. Estructura de Clases Core (Implementación en GDScript)

A continuación, se define la estructura en código (GDScript / Godot 4) de la entidad principal y sus componentes, demostrando la arquitectura basada en composición y el uso del *Event Bus*.

### 9.1. Entity (El Nodo Principal)
Esta clase actúa como el "cerebro" central que mantiene unidos todos los módulos. No calcula daño por sí misma, sino que delega las tareas a sus componentes.

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

func _ready() -> void:
	if not initialized:
		initialize()

func initialize() -> void:
	if initialized: return
	
	# Instanciar componentes
	stats = StatsComponent.new()
	effects = EffectManager.new(self)
	skills = SkillManager.new(self)
	skill_component = SkillComponent.new(self)
	passives = PassiveEffectComponent.new()
	equipment = EquipmentComponent.new()
	equipment.initialize(self)
	
	# Conectar dependencias del EquipmentComponent
	equipment.stats_component = stats
	equipment.skill_component = skill_component
	equipment.passive_effect_component = passives
	
	initialized = true

# Cargar datos desde ClassData (Warrior, Wizard, etc.)
func apply_class(class_data: ClassData) -> void:
	for key in class_data.base_stats:
		if key is StringName:
			stats.set_base_stat(StringName(key), class_data.base_stats[key])
	stats.finalize_initialization()
	for s in class_data.starting_skills:
		skills.learn_skill(s)

func is_alive() -> bool:
	return stats.current.get(StatTypes.HP, 0) > 0

# AI simple para enemigos (se puede sobreescribir o delegar a un AIController)
func decide_action(context: Dictionary = {}) -> Action:
	if team == Team.ENEMY and skills.known_skills.size() > 0:
		var skill = skills.known_skills[0]
		var target = context.get("target")
		if target:
			var action = AttackAction.new(self, target)
			action.skill_reference = skill
			return action
	return null
```

### 9.2. SkillManager (Controlador de Habilidades)
Maneja la lista de habilidades aprendidas y sus cooldowns.

```gdscript
class_name SkillManager
extends Object

var owner: Entity
var known_skills: Array[Skill] = []
var cooldowns: Dictionary = {} # Skill -> remaining_turns
var max_skill_slots: int = 4

func _init(entity: Entity):
	owner = entity

func learn_skill(skill: Skill) -> bool:
	# Si ya la tiene, sube de nivel (Skill Draft merge)
	for existing in known_skills:
		if existing.skill_name == skill.skill_name:
			# TODO: Skill level up logic
			return true
	
	if known_skills.size() < max_skill_slots:
		known_skills.append(skill)
		cooldowns[skill] = 0
		return true
	return false # Slots llenos → Draft UI

func is_ready(skill: Skill) -> bool:
	return cooldowns.get(skill, 0) <= 0

func start_cooldown(skill: Skill) -> void:
	cooldowns[skill] = skill.max_cooldown

func reduce_cooldowns(amount: int = 1) -> void:
	for skill in cooldowns:
		cooldowns[skill] = max(0, cooldowns[skill] - amount)
```

### 9.3. CombatContext y Skill (Estructuras de Datos de Combate)
El `CombatContext` viaja por todo el pipeline de daño. El `Skill` es un Resource con datos de escalado.

```gdscript
# --- CombatContext: paquete de datos que viaja por el pipeline ---
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

func _init(p_source: Entity = null, p_target: Entity = null, p_skill: Skill = null):
	source = p_source
	target = p_target
	skill = p_skill
```

```gdscript
# --- Skill: recurso estático que define la habilidad ---
class_name Skill
extends Resource

enum ScalingType { FLAT, STAT_PERCENT }

@export var skill_name: String = "Skill"
@export var scaling_type: ScalingType = ScalingType.STAT_PERCENT
@export var scaling_stat: StringName = StatTypes.STRENGTH
@export var scaling_percent: float = 1.0 # 1.0 = 100%
@export var on_cast_effects: Array[EffectResource] = [] # Efectos al casteador
@export var on_hit_effects: Array[EffectResource] = [] # Efectos al objetivo
@export var base_power: int = 0
@export var max_cooldown: int = 0 # Turnos de cooldown
@export var hit_chance: int = 90 # 90 = 90% precisión base
@export var ignores_shield: bool = false # Penetrating: salta el Shield
```

### 9.4. StatsComponent (Gestor de Estadísticas y Salud)
Este componente almacena valores base, current y modificadores temporales. Usa `StringName` keys de `StatTypes` para máxima flexibilidad. Los modificadores soportan FLAT, PERCENT_ADD y MULTIPLIER.

```gdscript
class_name StatsComponent
extends Resource

@export var base: Dictionary[StringName, int] = {}
var current: Dictionary[StringName, int] = {}
var modifiers: Dictionary = {} # StringName -> Array[StatModifierInstance]

# Valores por defecto si no se asignan en el ClassData/EnemyTemplate
const DEFAULTS = {
	StatTypes.HP: 10, StatTypes.MAX_HP: 10,
	StatTypes.STRENGTH: 5, StatTypes.DEXTERITY: 5,
	StatTypes.INTELLIGENCE: 5, StatTypes.PIETY: 5, StatTypes.POWER: 0,
	StatTypes.SPEED: 5, StatTypes.DEFENSE: 0,
	StatTypes.SHIELD: 0, StatTypes.MAX_SHIELD: 0,
	StatTypes.CRIT_CHANCE: 5, StatTypes.CRIT_DAMAGE: 150,
	StatTypes.PARRY_CHANCE: 0, StatTypes.AVOID_CHANCE: 0, StatTypes.ACCURACY: 0,
}

func finalize_initialization() -> void:
	current.clear()
	for key in base:
		current[key] = base[key]
	if base.has(StatTypes.MAX_SHIELD) and not base.has(StatTypes.SHIELD):
		current[StatTypes.SHIELD] = base[StatTypes.MAX_SHIELD]

# Fórmula: (Base + Flat) * (1 + %Add) * Mult
func get_stat(stat_type: StringName) -> int:
	var base_val = base.get(stat_type, DEFAULTS.get(stat_type, 0))
	var flat = 0.0; var percent_add = 0.0; var mult = 1.0
	if modifiers.has(stat_type):
		for mod_instance in modifiers[stat_type]:
			match mod_instance.resource.type:
				StatModifier.Type.FLAT: flat += mod_instance.resource.value
				StatModifier.Type.PERCENT_ADD: percent_add += mod_instance.resource.value
				StatModifier.Type.MULTIPLIER: mult *= mod_instance.resource.value
	return int((base_val + flat) * (1.0 + percent_add) * mult)

func get_current(stat_type: StringName) -> int:
	return current.get(stat_type, DEFAULTS.get(stat_type, 0))

func set_base_stat(stat_type: StringName, value: int) -> void:
	base[stat_type] = value

func modify_current(stat_type: StringName, amount: int) -> void:
	var current_val = current.get(stat_type, DEFAULTS.get(stat_type, 0))
	current[stat_type] = current_val + amount
	# Clamp a los máximos correspondientes
	if stat_type == StatTypes.HP:
		current[stat_type] = clampi(current[stat_type], 0, get_stat(StatTypes.MAX_HP))
	elif stat_type == StatTypes.SHIELD:
		current[stat_type] = clampi(current[stat_type], 0, get_stat(StatTypes.MAX_SHIELD))

# Restaurar escudo al 100% después de cada batalla (regla del GDD)
func reset_shield() -> void:
	current[StatTypes.SHIELD] = get_stat(StatTypes.MAX_SHIELD)
```

### Notas sobre el diseño:
1. **StringName Keys:** Usar `StatTypes.STRENGTH` etc. permite crear stats nuevas sin modificar enums.
2. **Modificadores en capas:** FLAT → PERCENT_ADD → MULTIPLIER se aplican en orden para buffs/debuffs/equipo.
3. **Spillover de Shield:** La lógica de absorción está en `CombatSystem.deal_damage()`, no aquí.
4. **Restauración:** `reset_shield()` se llama desde el `GameLoop` al terminar cada combate.

### 9.5. EffectManager (Gestor de Efectos y Pasivas)
Este módulo administra los efectos activos (Buffs, Debuffs, DoTs, Pasivas). Los efectos se definen como `EffectResource` y se instancian como `EffectInstance`. La ejecución de operaciones se delega a `OperationExecutor`.

```gdscript
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
		return
	# Manejo de stacking según la regla del EffectResource
	match effect_res.stack_rule:
		EffectResource.StackRule.ADD:
			existing.stacks = min(existing.stacks + 1, effect_res.max_stacks)
			existing.remaining_turns = effect_res.duration_turns
		EffectResource.StackRule.REFRESH:
			existing.remaining_turns = effect_res.duration_turns
		EffectResource.StackRule.REPLACE:
			effects.erase(existing)
			effects.append(EffectInstance.new(effect_res))
		EffectResource.StackRule.IGNORE:
			pass

func tick_all() -> void:
	for instance in effects:
		instance.tick_duration()
	# Remover expirados
	var active: Array[EffectInstance] = []
	for instance in effects:
		if not instance.is_expired():
			active.append(instance)
	effects = active

# Despacha un trigger a todos los efectos que lo escuchen
func dispatch(trigger: EffectResource.Trigger, context: Variant) -> void:
	var combat_context: CombatContext
	if context is CombatContext:
		combat_context = context
	elif context is Dictionary:
		combat_context = CombatContext.new()
		combat_context.raw_data = context
	else:
		return
	for instance in effects:
		if instance.resource.trigger == trigger:
			OperationExecutor.execute(instance, owner, combat_context)
```

### 9.6. EffectResource (Definición de Datos de Efecto)
Cada efecto es un `Resource` con trigger, operation, stacking y duración. Los `.tres` se crean en el editor.

```gdscript
class_name EffectResource
extends Resource

@export var effect_id: StringName = ""

enum Trigger {
	ON_SKILL_CAST,
	ON_PRE_DAMAGE_CALC, ON_DAMAGE_CALCULATED,
	ON_DAMAGE_RECEIVED_CALC, ON_PRE_DAMAGE_APPLY,
	ON_DAMAGE_DEALT, ON_DAMAGE_TAKEN,
	ON_KILL, ON_DEATH, ON_HEAL_RECEIVED,
	ON_TURN_START, ON_TURN_END
}

enum Operation {
	ADD_DAMAGE, ADD_DAMAGE_PERCENT, MULTIPLY_DAMAGE, SET_DAMAGE,
	REDUCE_DAMAGE_FLAT, REDUCE_DAMAGE_PERCENT, ABSORB_DAMAGE,
	CLAMP_MIN_DAMAGE, CLAMP_MAX_DAMAGE,
	CONVERT_TO_TRUE_DAMAGE, STORE_DAMAGE,
	ADD_STAT_MODIFIER, HEAL
}

@export var trigger: Trigger
@export var operation: Operation
@export var stat_modifier: StatModifier # Para ADD_STAT_MODIFIER
@export var value: float = 0.0
@export var stat_type: StringName = ""
@export var proc_chance: float = 1.0
@export var conditions: Array[EffectCondition] = []

enum StackRule { ADD, REFRESH, REPLACE, IGNORE }
@export var stack_rule: StackRule = StackRule.ADD
@export var max_stacks: int = 99
@export var duration_turns: int = -1 # -1 = infinito
```

### 9.6.2. Ejemplo: Pasiva "Berserker" (Doble Filo)
Esta pasiva demuestra cómo una habilidad puede alterar múltiples flujos del combate suscribiéndose a más de un evento a la vez. El efecto: "Haces y recibes el doble de daño".

```csharp
public class Passive_Berserker : PassiveAbility 
{
    private BattleEntity _owner;

    public override void Initialize(BattleEntity owner) 
    {
        _owner = owner;
        
        // 1. Nos suscribimos para duplicar el daño que RECIBIMOS
        _owner.OnBeforeDamageTaken += DoubleIncomingDamage;
        
        // 2. Nos suscribimos para duplicar el daño que HACEMOS
        _owner.OnBeforeDamageDealt += DoubleOutgoingDamage; 
    }

    // Intercepta el daño que el enemigo nos va a hacer
    private void DoubleIncomingDamage(DamageInfo incomingDamage) 
    {
        incomingDamage.FinalDamage *= 2f;
        Debug.Log($"[Berserker] Daño recibido DUPLICADO. Nuevo daño: {incomingDamage.FinalDamage}");
    }

    // Intercepta el daño que nosotros calculamos antes de enviárselo al enemigo
    private void DoubleOutgoingDamage(DamageInfo outgoingDamage) 
    {
        outgoingDamage.FinalDamage *= 2f;
        Debug.Log($"[Berserker] Daño infligido DUPLICADO. Nuevo daño: {outgoingDamage.FinalDamage}");
    }

    // Limpieza crítica si el personaje pierde la pasiva
    public override void Dispose() 
    {
        _owner.OnBeforeDamageTaken -= DoubleIncomingDamage;
        _owner.OnBeforeDamageDealt -= DoubleOutgoingDamage;
    }
}

### Por qué esta estructura es útil:
1. **Data-Driven:** Las pasivas como *Hard Shield* se implementan como archivos `.tres` con trigger `ON_DAMAGE_RECEIVED_CALC` y operation `REDUCE_DAMAGE_PERCENT`, sin código custom.
2. **Desacoplamiento:** `StatsComponent` no sabe qué efectos existen. Solo recibe el daño ya modificado.
3. **Fácil de expandir:** Nuevas pasivas como *Spiked Armor* se crean como otro `.tres` con trigger `ON_DAMAGE_TAKEN` y operation `ADD_DAMAGE` hacia el atacante.

### 9.7. CombatSystem (Pipeline de Daño Completo)
Funciones estáticas que procesan el daño a través de todas las fases del pipeline, incluyendo Shield absorption y death check.

```gdscript
class_name CombatSystem
extends Object

static func deal_damage(context: CombatContext) -> void:
	var source = context.source
	var target = context.target
	if not target: return

	# STAGE 1: PRE CALC (e.g. "Next attack +50% power")
	if source: source.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_CALC, context)
	# STAGE 2: OFFENSIVE (Crit buffs, Attack buffs, Elemental)
	if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_CALCULATED, context)
	# STAGE 3: DEFENSIVE (Shields, Armor, Resistances)
	target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_RECEIVED_CALC, context)
	# STAGE 4: FINAL (Clamps, caps, special interactions)
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

static func heal(context: CombatContext) -> void:
	var target = context.target
	if not target or context.heal_amount <= 0: return
	target.stats.modify_current(StatTypes.HP, context.heal_amount)
	target.effects.dispatch(EffectResource.Trigger.ON_HEAL_RECEIVED, context)
```

### 9.8. SkillExecutor (Resolución de Habilidad con Combat Rolls)
Orquesta la secuencia completa: Avoid → Hit → Parry → Damage Calc → Crit → Pipeline → Efectos.

```gdscript
class_name SkillExecutor
extends Object

static func execute(skill: Skill, source: Entity, target: Entity) -> void:
	var context = CombatContext.new(source, target, skill)
	context.is_penetrating = skill.ignores_shield

	# 1. ON_SKILL_CAST trigger
	source.effects.dispatch(EffectResource.Trigger.ON_SKILL_CAST, context)

	# 2. Avoid check
	var avoid = target.stats.get_stat(StatTypes.AVOID_CHANCE)
	if avoid > 0 and randi() % 100 < avoid:
		context.is_avoided = true
		return # Esquivado completamente

	# 3. Hit check (skill accuracy + source accuracy stat)
	var total_hit = skill.hit_chance + source.stats.get_stat(StatTypes.ACCURACY)
	if randi() % 100 >= total_hit:
		return # Falla de precisión

	# 4. Parry check
	var parry = target.stats.get_stat(StatTypes.PARRY_CHANCE)
	if parry > 0 and randi() % 100 < parry:
		context.is_parry = true
		GlobalEventBus.dispatch("parry_success", {"entity": target})
		return # Desviado

	# 5. Base damage calculation
	context.damage = FormulaCalculator.calculate_damage(skill, source)

	# 6. Crit roll
	var crit = source.stats.get_stat(StatTypes.CRIT_CHANCE)
	if crit > 0 and randi() % 100 < crit:
		context.is_crit = true
		context.damage = int(context.damage * source.stats.get_stat(StatTypes.CRIT_DAMAGE) / 100.0)

	# 7. Full damage pipeline
	CombatSystem.deal_damage(context)

	# 8. Apply on-hit effects
	for effect in skill.on_cast_effects:
		source.effects.apply_effect(effect)
	for effect in skill.on_hit_effects:
		target.effects.apply_effect(effect)
```