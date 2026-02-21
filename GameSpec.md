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

## 9. Estructura de Clases Core (Code Implementation)



A continuación, se define la estructura en código (C#) de la entidad principal y su controlador de habilidades, demostrando la arquitectura basada en componentes y el uso del *Event Bus*.

### 9.1. BattleEntity.cs (El Nodo Principal)
Esta clase actúa como el "cerebro" central que mantiene unidos todos los módulos. No calcula daño por sí misma, sino que delega las tareas a sus componentes.

```csharp
using System;
using System.Collections.Generic;

public class BattleEntity 
{
    // Identificación
    public string EntityName;
    public bool IsPlayer;

    // --- COMPONENTES ---
    // Referencias a los módulos que construyen la entidad
    public StatsComponent Stats { get; private set; }
    public SkillController Skills { get; private set; }
    public EffectReceiver Effects { get; private set; }
    public EquipmentManager Equipment { get; private set; }

    // --- EVENT BUS LOCAL ---
    // Ganchos a los que las pasivas y habilidades pueden suscribirse
    public event Action OnBattleStart;
    public event Action OnTurnStart;
    public event Action OnTurnEnd;
    public event Action<DamageInfo> OnBeforeDamageTaken;
    public event Action<DamageInfo> OnAfterDamageTaken;
    public event Action OnEntityDeath;
    public event Action OnParrySuccess;

    // Inicialización (Inyección de dependencias y datos)
    public void Initialize(EntityTemplate template) 
    {
        // Instanciar componentes
        Stats = new StatsComponent(this);
        Skills = new SkillController(this);
        Effects = new EffectReceiver(this);
        
        if (IsPlayer) {
            Equipment = new EquipmentManager(this);
        }

        // Cargar datos base desde el template (Clase o Enemigo)
        Stats.LoadBaseStats(template);
        Skills.LoadInitialSkills(template.StartingSkills);
    }

    // Métodos para disparar los eventos desde el Game Manager o Combate
    public void TriggerTurnStart() => OnTurnStart?.Invoke();
    public void TriggerTurnEnd() => OnTurnEnd?.Invoke();
    public void TriggerParry() => OnParrySuccess?.Invoke();
    
    // El flujo de recibir daño
    public void TakeDamage(DamageInfo incomingDamage) 
    {
        // 1. Las pasivas pueden modificar el daño entrante aquí (Ej. Hard Shield)
        OnBeforeDamageTaken?.Invoke(incomingDamage);

        // 2. El StatsComponent procesa la reducción matemática de HP/Shield
        Stats.ApplyDamage(incomingDamage);

        // 3. Las pasivas pueden reaccionar al daño recibido (Ej. Counter)
        OnAfterDamageTaken?.Invoke(incomingDamage);

        // 4. Comprobar muerte
        if (Stats.CurrentHP <= 0) {
            OnEntityDeath?.Invoke();
        }
    }
}

using System.Collections.Generic;
using System.Linq;

public class SkillController 
{
    private BattleEntity _owner;
    
    // Lista de habilidades equipadas actualmente (Instancias vivas)
    public List<SkillInstance> EquippedSkills { get; private set; }
    
    // Límite máximo de habilidades que puede tener la entidad
    public int MaxSkillSlots = 4;

    public SkillController(BattleEntity owner) 
    {
        _owner = owner;
        EquippedSkills = new List<SkillInstance>();
    }

    // Carga las habilidades iniciales desde el Data Template
    public void LoadInitialSkills(List<SkillData> startingSkills) 
    {
        foreach(var skillData in startingSkills) 
        {
            AddSkill(skillData);
        }
    }

    // Agregar una nueva habilidad (Ej. Al subir de nivel)
    public bool AddSkill(SkillData newSkillData) 
    {
        // Comprobar si ya la tenemos para subirla de nivel
        var existingSkill = EquippedSkills.FirstOrDefault(s => s.Data.ID == newSkillData.ID);
        if (existingSkill != null) 
        {
            existingSkill.LevelUp();
            return true;
        }

        // Si hay espacio, la añadimos como una nueva instancia
        if (EquippedSkills.Count < MaxSkillSlots) 
        {
            EquippedSkills.Add(new SkillInstance(newSkillData));
            return true;
        }

        // Si no hay espacio, la UI deberá manejar el reemplazo (Draft UI)
        return false; 
    }

    // Ejecutar una habilidad contra un objetivo
    public void CastSkill(int skillIndex, BattleEntity target) 
    {
        if (skillIndex < 0 || skillIndex >= EquippedSkills.Count) return;

        SkillInstance skillToCast = EquippedSkills[skillIndex];

        if (!skillToCast.IsReady()) return; // Comprueba Cooldown

        // Calcular daño base sumando el escalado (Ej. STR) y el atributo POW del _owner
        DamageInfo damagePackage = CalculateDamage(skillToCast);

        // Enviar el paquete de daño al objetivo
        target.TakeDamage(damagePackage);

        // Aplicar el Cooldown a la habilidad recién usada
        skillToCast.StartCooldown();
    }

    // Reducir los Cooldowns al inicio del turno (o mediante pasivas como Counter)
    public void ReduceCooldowns(int amount = 1) 
    {
        foreach(var skill in EquippedSkills) 
        {
            skill.ReduceCooldown(amount);
        }
    }

    // Cálculo interno de daño basado en los Stats del dueño y el escalado de la habilidad
    private DamageInfo CalculateDamage(SkillInstance skill) 
    {
        DamageInfo info = new DamageInfo();
        
        // Ejemplo matemático: Daño Base de la habilidad + (Atributo Escalar * %) + POW
        // Si la habilidad escala con STR (Attack, Tornado Slash)
        float statBonus = _owner.Stats.STR * skill.Data.ScalingPercentage;
        
        info.RawDamage = skill.Data.BaseDamage + statBonus + _owner.Stats.POW;
        info.HitChance = skill.Data.BaseHit + _owner.Stats.ExtraAccuracy;
        info.IsPenetrating = skill.Data.IgnoresShield; // Para evadir el Shield
        
        return info;
    }
}

// Estructura que viaja desde el atacante hasta el defensor
public class DamageInfo 
{
    public float RawDamage;
    public float FinalDamage; // Modificado por pasivas/defensa
    public float HitChance;
    public bool IsCritical;
    public bool IsPenetrating; // Si es true, ignora el Shield
}

// Representa una habilidad "viva" en combate
public class SkillInstance 
{
    public SkillData Data { get; private set; } // Referencia al Data Template
    public int CurrentLevel { get; private set; }
    public int CurrentCooldown { get; private set; }

    public SkillInstance(SkillData data) 
    {
        Data = data;
        CurrentLevel = 1;
        CurrentCooldown = 0;
    }

    public void LevelUp() => CurrentLevel++;
    public bool IsReady() => CurrentCooldown <= 0;
    public void StartCooldown() => CurrentCooldown = Data.BaseCooldown;
    
    public void ReduceCooldown(int amount) 
    {
        CurrentCooldown -= amount;
        if (CurrentCooldown < 0) CurrentCooldown = 0;
    }
}

### 9.4. StatsComponent.cs (Gestor de Estadísticas y Salud)
Este componente almacena los valores actuales y máximos de la entidad. También contiene la lógica de resolución de daño (HP vs. Shield) y permite que otros sistemas (como los ítems equipados) modifiquen las estadísticas base.



```csharp
using System;
using UnityEngine; // O el equivalente matemático en tu motor (Mathf)

public class StatsComponent 
{
    private BattleEntity _owner;

    // --- ATRIBUTOS PRINCIPALES ---
    // (Se pueden dividir en Base y Modificados para manejar los buffs temporales)
    public float STR { get; set; }
    public float DEX { get; set; }
    public float INT { get; set; }
    public float PIE { get; set; }
    public float POW { get; set; }

    // --- ATRIBUTOS DE SUPERVIVENCIA ---
    public float MAXHP { get; set; }
    public float CurrentHP { get; set; }

    public float MaxShield { get; set; }
    public float CurrentShield { get; set; }

    // --- ATRIBUTOS DE COMBATE ---
    public float CritChance { get; set; }
    public float CritDamage { get; set; }
    public float ParryChance { get; set; }
    public float AvoidChance { get; set; }
    public float ExtraAccuracy { get; set; }

    public StatsComponent(BattleEntity owner) 
    {
        _owner = owner;
    }

    // Inicializa las estadísticas desde la plantilla base
    public void LoadBaseStats(EntityTemplate template) 
    {
        STR = template.BaseSTR;
        DEX = template.BaseDEX;
        INT = template.BaseINT;
        PIE = template.BasePIE;
        POW = template.BasePOW;
        
        MAXHP = template.BaseMAXHP;
        MaxShield = template.BaseShield; // Algunas clases/enemigos empiezan sin escudo

        CritChance = template.BaseCritChance;
        CritDamage = template.BaseCritDamage;
        ParryChance = template.BaseParryChance;
        AvoidChance = template.BaseAvoidChance;

        // Llenar las barras al iniciar
        CurrentHP = MAXHP;
        CurrentShield = MaxShield;
    }

    // Restaurar escudo al 100% después de cada batalla (regla del GDD)
    public void ResetShieldAfterBattle() 
    {
        CurrentShield = MaxShield;
    }

    // Curación normal de HP
    public void Heal(float amount) 
    {
        CurrentHP += amount;
        if (CurrentHP > MAXHP) CurrentHP = MAXHP;
    }

    // --- LÓGICA CORE DE DAÑO ---
    // Resuelve matemáticamente cómo impacta el daño en las barras
    public void ApplyDamage(DamageInfo info) 
    {
        float damageToDeal = info.FinalDamage;

        // Si el ataque tiene Penetration, ignora el Shield y va directo a la vida
        if (info.IsPenetrating) 
        {
            CurrentHP -= damageToDeal;
            Debug.Log($"{_owner.EntityName} recibió {damageToDeal} de daño penetrante directo al HP!");
        } 
        else 
        {
            // Daño normal: Primero golpea el Shield
            if (CurrentShield > 0) 
            {
                if (damageToDeal <= CurrentShield) 
                {
                    // El escudo absorbe todo el daño
                    CurrentShield -= damageToDeal;
                    damageToDeal = 0; 
                    Debug.Log($"El escudo de {_owner.EntityName} absorbió el ataque.");
                } 
                else 
                {
                    // El daño rompe el escudo y sobra
                    damageToDeal -= CurrentShield;
                    CurrentShield = 0;
                    Debug.Log($"¡El escudo de {_owner.EntityName} se rompió!");
                }
            }

            // Si quedó daño remanente (o no había escudo), va al HP
            if (damageToDeal > 0) 
            {
                CurrentHP -= damageToDeal;
                Debug.Log($"{_owner.EntityName} recibió {damageToDeal} de daño al HP.");
            }
        }

        // Prevenir que el HP baje de 0
        if (CurrentHP < 0) CurrentHP = 0;
    }
}

### Notas sobre el diseño:
1. **Spillover (Daño sobrante):** La lógica de `damageToDeal -= CurrentShield` asegura que si tienes 10 de Escudo y recibes 50 de daño, el escudo se rompe (0) y los 40 restantes pasan a tu HP real. Esto evita que un escudo de 1 HP bloquee un ataque nuclear.
2. **Penetration:** Un simple `if (info.IsPenetrating)` desvía todo el cálculo directamente a la variable `CurrentHP`, saltándose el bloque del escudo. ¡Súper limpio y fácil de leer!
3. **Restauración:** Como indicaste en las reglas, el método `ResetShieldAfterBattle()` se llamaría desde tu *GameManager* o *RoomManager* justo cuando termina el combate, dejándolo listo para la siguiente sala.

Con este módulo, la entidad ya sabe atacar (`SkillController`), recibir daño (`StatsComponent`) y organizar eventos (`BattleEntity`). 

Para completar este cuarteto de componentes, el siguiente paso lógico sería estructurar el **`EffectReceiver`** (el que maneja los Buffs/Debuffs y escucha las pasivas) o podemos pasar a cómo se vería la **Generación Procedural de Ítems**. ¿Cuál prefieres agregar a la especificación?

### 9.5. EffectReceiver.cs (Gestor de Estados y Pasivas)
Este módulo se encarga de recibir, almacenar y procesar alteraciones que no son permanentes (Buffs/Debuffs) y las habilidades Pasivas. Se conecta fuertemente al *Event Bus* de la `BattleEntity` para escuchar cuándo debe actuar.

```csharp
using System.Collections.Generic;
using UnityEngine;

public class EffectReceiver 
{
    private BattleEntity _owner;

    // Listas de alteraciones activas
    public List<StatusEffect> ActiveStatusEffects { get; private set; }
    public List<PassiveAbility> ActivePassives { get; private set; }

    public EffectReceiver(BattleEntity owner) 
    {
        _owner = owner;
        ActiveStatusEffects = new List<StatusEffect>();
        ActivePassives = new List<PassiveAbility>();

        // Nos suscribimos al final del turno para reducir la duración de los Buffs/Debuffs
        _owner.OnTurnEnd += TickEffects;
    }

    // --- GESTIÓN DE ESTADOS TEMPORALES (Buffs / Debuffs) ---
    public void AddStatusEffect(StatusEffect effect) 
    {
        // Revisar si ya existe para acumularlo o reiniciar su duración
        var existingEffect = ActiveStatusEffects.Find(e => e.ID == effect.ID);
        if (existingEffect != null) 
        {
            existingEffect.Duration = effect.Duration; // Reinicia duración
        } 
        else 
        {
            ActiveStatusEffects.Add(effect);
            effect.OnApply(_owner); // Aplica el efecto inicial (Ej. +10 STR temporal)
        }
    }

    private void TickEffects() 
    {
        for (int i = ActiveStatusEffects.Count - 1; i >= 0; i--) 
        {
            var effect = ActiveStatusEffects[i];
            effect.Duration--;

            // Efectos DoT (Damage over Time) como Veneno actúan aquí
            effect.OnTick(_owner); 

            if (effect.Duration <= 0) 
            {
                effect.OnRemove(_owner); // Revierte el efecto (Ej. -10 STR)
                ActiveStatusEffects.RemoveAt(i);
            }
        }
    }

    // --- GESTIÓN DE PASIVAS (Items, Clases, Enemigos) ---
    public void AddPassive(PassiveAbility passive) 
    {
        ActivePassives.Add(passive);
        passive.Initialize(_owner); // Aquí la pasiva se suscribe a los eventos necesarios
    }

    public void RemovePassive(PassiveAbility passive) 
    {
        passive.Dispose(); // Desuscribe la pasiva de los eventos para evitar memory leaks
        ActivePassives.Remove(passive);
    }
}

public class Passive_HardShield : PassiveAbility 
{
    private BattleEntity _owner;

    // Se llama cuando el EffectReceiver añade la pasiva
    public override void Initialize(BattleEntity owner) 
    {
        _owner = owner;
        // Nos suscribimos al momento EXACTO antes de recibir daño
        _owner.OnBeforeDamageTaken += ApplyShieldReduction;
    }

    private void ApplyShieldReduction(DamageInfo incomingDamage) 
    {
        // Si el ataque es penetrante, el Hard Shield no funciona (Regla del GDD)
        if (incomingDamage.IsPenetrating) return;

        // "Cuando el current Shield es al menos 1, el daño recibido se reduce 30%"
        if (_owner.Stats.CurrentShield >= 1) 
        {
            float reductionAmount = incomingDamage.FinalDamage * 0.30f;
            incomingDamage.FinalDamage -= reductionAmount;
            
            Debug.Log($"[Hard Shield] redujo el daño en {reductionAmount}. Daño restante: {incomingDamage.FinalDamage}");
        }
    }

    // Se llama si el jugador se quita el ítem o cambia de clase
    public override void Dispose() 
    {
        _owner.OnBeforeDamageTaken -= ApplyShieldReduction;
    }
}

### Por qué esta estructura es tan útil:
1. **Desacoplamiento:** El `StatsComponent` que hicimos antes no tiene idea de que "Hard Shield" existe. Simplemente recibe el `DamageInfo` modificado y hace la resta.
2. **Fácil de expandir:** Si mañana quieres crear una pasiva llamada **Spiked Armor** (devuelve daño al ser atacado), solo creas una clase nueva `Passive_SpikedArmor`, te suscribes a `_owner.OnAfterDamageTaken`, y le haces daño al atacante. Cero modificaciones a tu código base.
3. **Mantenimiento limpio:** Al usar `Dispose()`, te aseguras de que si un jugador cambia su "Casco" por otro, las pasivas del casco viejo dejan de escuchar los eventos y no causan bugs (memory leaks).

### 9.7. ItemFactory.cs (Generación Procedural de Botín)
El patrón *Factory* se utiliza para instanciar objetos únicos a partir de plantillas estáticas (`ItemData`). Al crear el objeto, la fábrica toma en cuenta el nivel de la mazmorra (piso actual) para calcular bonificaciones estadísticas aleatorias (RNG) e inyectar posibles efectos pasivos.



```csharp
using System.Collections.Generic;
using UnityEngine;

// La instancia "viva" del objeto que el jugador equipará
public class ItemInstance 
{
    public ItemData BaseData { get; private set; }
    
    // Estadísticas finales calculadas (Base + RNG)
    public float BonusSTR;
    public float BonusINT;
    public float BonusMAXHP;
    
    // Lista de pasivas que rodaron en este ítem específico
    public List<PassiveAbility> RolledPassives;

    public ItemInstance(ItemData data) 
    {
        BaseData = data;
        RolledPassives = new List<PassiveAbility>();
    }
}

// El sistema encargado de crear el botín
public class ItemFactory 
{
    // Método principal llamado al abrir un cofre o matar un enemigo
    public ItemInstance GenerateLoot(ItemData template, int currentFloor) 
    {
        // 1. Crear el contenedor vacío basado en la plantilla
        ItemInstance newItem = new ItemInstance(template);

        // 2. Asignar valores base de la plantilla (Ej. +10 INT fijos)
        newItem.BonusSTR = template.BaseSTR;
        newItem.BonusINT = template.BaseINT;
        newItem.BonusMAXHP = template.BaseMAXHP;

        // 3. Sistema RNG: Escalado por el piso actual
        // A mayor piso, mayor es el pool de "puntos de mejora" a repartir
        int statBudget = Random.Range(currentFloor, currentFloor * 3);
        
        // Repartir el presupuesto aleatoriamente entre los stats permitidos por el ítem
        for (int i = 0; i < statBudget; i++) 
        {
            float roll = Random.value;
            if (roll < 0.33f) newItem.BonusSTR += 1; // +1 de Fuerza extra
            else if (roll < 0.66f) newItem.BonusINT += 1; // +1 de Inteligencia extra
            else newItem.BonusMAXHP += 5; // +5 de Vida extra
        }

        // 4. Sistema RNG: Generación de Pasivas
        // Los ítems legendarios siempre traen su pasiva única
        if (template.Rarity == ItemRarity.Legendary && template.UniquePassive != null) 
        {
            newItem.RolledPassives.Add(CreatePassiveInstance(template.UniquePassive));
        }
        else 
        {
            // Probabilidad de obtener una pasiva común/poco común (Ej. Plating)
            float passiveChance = 0.10f + (currentFloor * 0.02f); // Más chance en pisos altos
            if (Random.value <= passiveChance) 
            {
                PassiveAbility randomPassive = GetRandomCommonPassive();
                newItem.RolledPassives.Add(randomPassive);
                Debug.Log($"¡El ítem generó la pasiva {randomPassive.Name}!");
            }
        }

        return newItem;
    }

    // Método de soporte para instanciar la clase de la pasiva correcta
    private PassiveAbility CreatePassiveInstance(PassiveData data) 
    {
        // En producción, esto usaría Reflexión o un Switch para retornar la clase correcta
        // Ej: return new Passive_Plating();
        return null; 
    }

    private PassiveAbility GetRandomCommonPassive() 
    {
        // Lógica para sacar una pasiva aleatoria del Pool (Ej. Supply Route, Avoid Critical)
        return null;
    }
}