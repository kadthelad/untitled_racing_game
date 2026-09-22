class_name GroundData

enum GROUND_TYPES {
	GRASS,
	DIRT,
	SAND,
	CONCRETE,
}

const GROUND_COLOURS: Dictionary[GROUND_TYPES, Color] = {
	GROUND_TYPES.GRASS : Color.DARK_GREEN,
	GROUND_TYPES.DIRT : Color.SADDLE_BROWN,
	GROUND_TYPES.SAND : Color.BURLYWOOD,
	GROUND_TYPES.CONCRETE : Color.GRAY,
}

# Placeholder: every ground type has the same health for now, to be tuned per-type later.
const GROUND_HEALTH: Dictionary[GROUND_TYPES, float] = {
	GROUND_TYPES.GRASS : 100.0,
	GROUND_TYPES.DIRT : 100.0,
	GROUND_TYPES.SAND : 100.0,
	GROUND_TYPES.CONCRETE : 100.0,
}
