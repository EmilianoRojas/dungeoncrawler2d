class_name StatTypes
extends Object

# Core Resources
const HP := &"hp"
const MAX_HP := &"max_hp"

# Primary Attributes (Scaling)
const STRENGTH := &"strength"
const DEXTERITY := &"dexterity"
const INTELLIGENCE := &"intelligence"
const PIETY := &"piety"
const POWER := &"power" # Contributes to ALL skill damage

# Derived / Secondary
const SPEED := &"speed"
const DEFENSE := &"defense"

# Shield
const SHIELD := &"shield"
const MAX_SHIELD := &"max_shield"

# Combat Stats
const CRIT_CHANCE := &"crit_chance" # 0-100 scale (percentage)
const CRIT_DAMAGE := &"crit_damage" # Multiplier, e.g. 150 = 1.5x
const PARRY_CHANCE := &"parry_chance" # 0-100 scale
const AVOID_CHANCE := &"avoid_chance" # 0-100 scale
const ACCURACY := &"accuracy" # Extra accuracy added to skill hit
