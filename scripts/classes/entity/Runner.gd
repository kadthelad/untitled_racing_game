class_name Runner

# Constants
const STAT_CAP := 1200.0
const ACCELERATION_CAP := 20.0
const ACCELERATION_MIN_CAP := 1.0
const MAX_SPEED_CAP := 20.0
const MAX_SPEED_MIN_CAP := 10.0
const TROT_SPEED_MULTIPLIER := 1.5
const PACING_FACTOR_MIN := 0.45
const PACING_FACTOR_MAX := 0.75
const SPRINT_SPEED_FACTOR := 0.90
const SPURT_SPEED_FACTOR := 1.0
const MAX_STAMINA_CAP := 150.0
const MAX_STAMINA_MIN_CAP := 50.0
const STAMINA_DRAIN_MAX := 6.0
const STAMINA_DRAIN_MIN := 0.5
const STAMINA_REGEN_MAX := 2.0
const STAMINA_REGEN_MIN := 3.0
const FATIGUE_BUILDUP_MAX := 8.0
const FATIGUE_BUILDUP_MIN := 2.0

# Ground damage, placeholder values
const MIN_STRENGTH_FOR_DAMAGE: Dictionary[GroundData.GROUND_TYPES, int] = {
	GroundData.GROUND_TYPES.GRASS : 800,
	GroundData.GROUND_TYPES.DIRT : 500,
	GroundData.GROUND_TYPES.SAND : 400,
	GroundData.GROUND_TYPES.CONCRETE : 1000,
}
const GROUND_DAMAGE_MIN_STRENGTH_SPEED_FACTOR := 1.0 # At the strength requirement: sprint_speed, i.e. the speed SPURT begins at
const GROUND_DAMAGE_MAX_STRENGTH_SPEED_FACTOR := 0.5 # At STAT_CAP strength: this far through the PACING range, from trot_speed (0.0) to pacing_speed (1.0)
const GROUND_DAMAGE_TARGET_FRACTION := 0.5 # Portion of a ground's health a maxed-out runner should be able to deal crossing one segment
const GROUND_DAMAGE_REFERENCE_SEGMENT_LENGTH := 30.0 # Matches checkpoint_spacing on racecourse_1.tscn, the reference course
const GROUND_DAMAGE_TICK_INTERVAL := 1.0 # Ground can only take damage this often, in seconds

# Enumerations
enum STATS {
	SPEED,
	STAMINA,
	WILLPOWER,
	INTELLIGENCE,
	STRENGTH,
}

enum HIDDEN_STATS {
	FATIGUE_CAP,
	FATIGUE_DRAIN_RATE,
	VISION_CAP,
	VISION_DRAIN_RATE,
}

# Properties
var i_name: String = "No name"
var level: int = 0
var skill_points: int = 0
var stats: Dictionary[STATS, int] = {
	STATS.SPEED : 0,
	STATS.STAMINA : 0,
	STATS.WILLPOWER : 0,
	STATS.INTELLIGENCE : 0,
	STATS.STRENGTH : 0,
}

var runner_mind: Array[Skill] = []
var owned_traits: Array[Trait] = []
var vision_cap := 100.0
var vision_drain_rate := 1.0
var fatigue_cap := 100.0

# Methods
func _init(r_name: String, r_level: int, r_skill_points: int, 
			r_stats: Dictionary[STATS, int], r_runner_mind: Array[Skill]) -> void:
	i_name = r_name
	level = r_level
	skill_points = r_skill_points
	stats = r_stats.duplicate()
	runner_mind = r_runner_mind.duplicate()

static func empty() -> Runner:
	var default_stats: Dictionary[STATS, int] = {
		STATS.SPEED : 100,
		STATS.STAMINA : 100,
		STATS.WILLPOWER : 100,
		STATS.INTELLIGENCE : 100,
		STATS.STRENGTH : 100,
	}
	return Runner.new("No Name", 0, 0, default_stats, [])


# God I'm so trash at maths.
func get_acceleration() -> float:
	# Normalize each stat to a 0.0 - 1.0 range
	var speed_n: float = stats[STATS.SPEED] / STAT_CAP
	var willpower_n: float = stats[STATS.WILLPOWER] / STAT_CAP
	var strength_n: float = stats[STATS.STRENGTH] / STAT_CAP
	
	# Weighted sum — speed dominates, willpower helps, power contributes a little
	var raw := (speed_n * 0.80) + (willpower_n * 0.15) + (strength_n * 0.05)
	
	# Squared curve — the OPPOSITE of sqrt. Low stats get a disproportionately
	# LOW share of max acceleration instead of an inflated head start.
	var curved := raw * raw
	
	return clampf(curved * ACCELERATION_CAP, ACCELERATION_MIN_CAP, ACCELERATION_CAP)

func get_max_speed() -> float:
	# Normalize each stat to a 0.0 - 1.0 range
	var speed_n: float = stats[STATS.SPEED] / STAT_CAP
	var strength_n: float = stats[STATS.STRENGTH] / STAT_CAP
	var intelligence_n: float = stats[STATS.INTELLIGENCE] / STAT_CAP
	
	# Weighted sum
	var raw := (speed_n * 0.75) + (strength_n * 0.20) + (intelligence_n * 0.05)
	
	return raw * MAX_SPEED_CAP + MAX_SPEED_MIN_CAP

func get_trot_speed(base_walk_speed: float) -> float:
	# Trot is a small, flat step above walking — not stat-driven, just a brisk pace
	return base_walk_speed * TROT_SPEED_MULTIPLIER

func get_pacing_speed() -> float:
	# Endurance factor — mostly stamina, willpower helps push a little further
	var stamina_n: float = stats[STATS.STAMINA] / STAT_CAP
	var willpower_n: float = stats[STATS.WILLPOWER] / STAT_CAP
	
	var raw := (stamina_n * 0.85) + (willpower_n * 0.15)
	var curved := sqrt(raw)
	
	# High max speed means nothing here if stamina can't back it up
	var pacing_factor: float = lerp(PACING_FACTOR_MIN, PACING_FACTOR_MAX, curved)
	return get_max_speed() * pacing_factor

func get_sprint_speed() -> float:
	return get_max_speed() * SPRINT_SPEED_FACTOR

func get_spurt_speed() -> float:
	return get_max_speed() * SPURT_SPEED_FACTOR

func get_focus() -> int:
	# Focus amount = 20% of intelligence stat (float math first, then round)
	return roundi(stats[STATS.INTELLIGENCE] * 0.20)

func get_max_stamina() -> float:
	var stamina_n: float = stats[STATS.STAMINA] / STAT_CAP
	var willpower_n: float = stats[STATS.WILLPOWER] / STAT_CAP
	
	var raw := (stamina_n * 0.85) + (willpower_n * 0.15)
	var curved := sqrt(raw)
	
	return curved * MAX_STAMINA_CAP + MAX_STAMINA_MIN_CAP

func get_stamina_drain() -> float:
	# Higher stamina stat = more efficient runner = lower drain rate
	var stamina_n: float = stats[STATS.STAMINA] / STAT_CAP
	return lerp(STAMINA_DRAIN_MAX, STAMINA_DRAIN_MIN, stamina_n)

func get_stamina_regen() -> float:
	# Higher stamina stat = faster recovery when not pushing hard
	var stamina_n: float = stats[STATS.STAMINA] / STAT_CAP
	return lerp(STAMINA_REGEN_MIN, STAMINA_REGEN_MAX, stamina_n)

func get_fatigue_buildup() -> float:
	# Placeholder — higher willpower slows fatigue accumulation
	var willpower_n: float = stats[STATS.WILLPOWER] / STAT_CAP
	return lerp(FATIGUE_BUILDUP_MAX, FATIGUE_BUILDUP_MIN, willpower_n)

# Stat values in STATS enum declaration order. RPCs can't send a Runner (or any custom
# Object) directly — Godot's multiplayer RPC encoding doesn't support arbitrary Object/
# RefCounted types — so send this plus i_name/level/skill_points instead and rebuild a Runner
# with stats_from_values() on the receiving end.
func get_stat_values() -> PackedInt32Array:
	var values := PackedInt32Array()
	for stat_key: STATS in STATS.values():
		values.append(stats.get(stat_key, 0))
	return values

static func stats_from_values(stat_values: PackedInt32Array) -> Dictionary[STATS, int]:
	var result: Dictionary[STATS, int] = {}
	var stat_keys := STATS.values()
	for i in mini(stat_values.size(), stat_keys.size()):
		result[stat_keys[i]] = stat_values[i]
	return result

# 0.0 right at a ground's strength requirement, 1.0 at STAT_CAP, or -1.0 if this runner's
# strength doesn't meet the requirement at all (can't damage this ground, at any speed).
func _get_ground_damage_strength_factor(ground_type: GroundData.GROUND_TYPES) -> float:
	var required_strength: int = MIN_STRENGTH_FOR_DAMAGE.get(ground_type, int(STAT_CAP) + 1)
	var strength: int = stats[STATS.STRENGTH]
	if strength < required_strength:
		return -1.0
	if required_strength >= STAT_CAP:
		return 1.0
	return clampf((strength - required_strength) / (STAT_CAP - required_strength), 0.0, 1.0)

# The speed a maxed-out-strength runner needs to reach to damage the ground: not a fraction of
# pacing_speed itself, but partway *through* their own PACING range — from trot_speed (where
# PACING begins) to pacing_speed (where it ends) — via GROUND_DAMAGE_MAX_STRENGTH_SPEED_FACTOR.
# base_walk_speed matches get_trot_speed()'s own parameter (trot isn't stat-driven).
func _get_ground_damage_reference_speed(base_walk_speed: float) -> float:
	return lerp(get_trot_speed(base_walk_speed), get_pacing_speed(), GROUND_DAMAGE_MAX_STRENGTH_SPEED_FACTOR)

# A runner with high enough strength can start damaging the ground by running at a calculated min speed
func get_min_speed_for_ground_damage(ground_type: GroundData.GROUND_TYPES, base_walk_speed: float) -> float:
	var strength_factor := _get_ground_damage_strength_factor(ground_type)
	if strength_factor < 0.0:
		return INF # Can't damage this ground regardless of speed

	# Barely meeting the requirement demands the speed where SPURT begins — that's
	# sprint_speed, the boundary in PlayerMovementController._get_running_stage(), not
	# get_spurt_speed() (the ceiling of the spurt range, not its entry point). Maxed-out
	# strength lowers that down to the reference speed within the PACING range.
	var highest_threshold := get_sprint_speed() * GROUND_DAMAGE_MIN_STRENGTH_SPEED_FACTOR
	var lowest_threshold := _get_ground_damage_reference_speed(base_walk_speed)
	return lerp(highest_threshold, lowest_threshold, strength_factor)

# How much damage this runner deals per hit when damaging ground_type (assumes the caller
# already checked they're moving at/above get_min_speed_for_ground_damage(), and enforces the
# once-per-GROUND_DAMAGE_TICK_INTERVAL cadence itself — this only returns the per-hit amount).
func get_ground_damage_amount(ground_type: GroundData.GROUND_TYPES, base_walk_speed: float) -> float:
	var strength_factor := _get_ground_damage_strength_factor(ground_type)
	if strength_factor < 0.0:
		return 0.0

	# Calibrated so a maxed-out runner, moving at exactly their own (lowest possible) damage
	# threshold speed for one full checkpoint segment, deals GROUND_DAMAGE_TARGET_FRACTION of
	# the ground's total health by the time they cross it. Uses this runner's own speeds, so
	# that target is exact for a max-stat runner and an approximation for anyone else.
	var reference_speed := _get_ground_damage_reference_speed(base_walk_speed)
	var ticks_to_cross := (GROUND_DAMAGE_REFERENCE_SEGMENT_LENGTH / reference_speed) / GROUND_DAMAGE_TICK_INTERVAL
	var ground_health: float = GroundData.GROUND_HEALTH.get(ground_type, 100.0)
	var max_damage_per_tick := (ground_health * GROUND_DAMAGE_TARGET_FRACTION) / ticks_to_cross
	
	return lerp(0.0, max_damage_per_tick, strength_factor)

## Override
func _to_string() -> String:
	return "%s: \n" % i_name + str(stats)

# Static Functions
static func get_rank(given_stat: int) -> String:
	if given_stat < 101:
		return "G"
	elif given_stat < 201:
		return "F"
	elif given_stat < 401:
		return "E"
	elif given_stat < 601:
		return "D"
	elif given_stat < 801:
		return "C"
	elif given_stat < 1001:
		return "B"
	elif given_stat < 1101:
		return "A"
	elif given_stat < 1201:
		return "S"
	return "?"
