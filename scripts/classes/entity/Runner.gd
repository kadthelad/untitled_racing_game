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
const STAMINA_DRAIN_MIN := 1.5
const STAMINA_REGEN_MAX := 12.0
const STAMINA_REGEN_MIN := 3.0
const FATIGUE_BUILDUP_MAX := 8.0
const FATIGUE_BUILDUP_MIN := 2.0

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
