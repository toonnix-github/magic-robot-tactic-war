extends RefCounted
class_name GameData

const MechBuildModelScript := preload("res://src/data/mech_build_model.gd")

const PROTOTYPE_VERSION := "0.1"
const GRID_COLUMNS := 10
const GRID_ROWS := 7
const MOVE_RANGE := 3
const PRIMARY_ACTIONS := ["Move", "Attack", "Wait"]
const PART_NAMES := ["Head", "Body", "Left Arm", "Right Arm", "Legs"]
const DIRECTIONS := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
const PLACEHOLDER_ATTACK_DAMAGE := 25
const PLACEHOLDER_HIT_PERCENT := 80

const PLACEHOLDER_WEAPON_RANGES := {
	"Sword": 1,
	"Spear": 2,
	"Sniper": 6,
	"Rifle": 5,
	"Blade": 1,
	"Commander": 5,
}

const WEAPON_HANDEDNESS := MechBuildModelScript.WEAPON_HANDEDNESS
const OFF_HAND_EQUIPMENT_DATA := MechBuildModelScript.OFF_HAND_EQUIPMENT_DATA

const WEAPON_DATA := {
	"Sword": {
		"name": "Sword",
		"range_min": 1,
		"range_max": 1,
		"damage": 45,
		"hit_percent": 80,
		"allow_manual_part": false,
		"pattern": "single",
		"blockable": false,
		"part_weights": {"Head": 20, "Body": 20, "Left Arm": 20, "Right Arm": 20, "Legs": 20},
	},
	"Spear": {
		"name": "Spear",
		"range_min": 1,
		"range_max": 2,
		"damage": 30,
		"secondary_damage": 22,
		"hit_percent": PLACEHOLDER_HIT_PERCENT,
		"allow_manual_part": false,
		"pattern": "line_2",
		"blockable": false,
		"part_weights": {"Head": 20, "Body": 20, "Left Arm": 20, "Right Arm": 20, "Legs": 20},
	},
	"Sniper": {
		"name": "Sniper",
		"range_min": 2,
		"range_max": 6,
		"damage": 35,
		"hit_percent": PLACEHOLDER_HIT_PERCENT,
		"allow_manual_part": false,
		"pattern": "single",
		"blockable": true,
		"part_weights": {"Head": 30, "Body": 10, "Left Arm": 20, "Right Arm": 20, "Legs": 20},
	},
	"Rifle": {
		"name": "Rifle",
		"range_min": 1,
		"range_max": 5,
		"damage": 10,
		"shot_count": 4,
		"hit_percent": PLACEHOLDER_HIT_PERCENT,
		"allow_manual_part": false,
		"pattern": "volley",
		"blockable": true,
		"part_weights": {"Head": 20, "Body": 20, "Left Arm": 20, "Right Arm": 20, "Legs": 20},
	},
	"Commander": {
		"name": "Commander",
		"range_min": 1,
		"range_max": 5,
		"damage": PLACEHOLDER_ATTACK_DAMAGE,
		"hit_percent": PLACEHOLDER_HIT_PERCENT,
		"allow_manual_part": true,
		"pattern": "single",
		"blockable": true,
		"part_weights": {"Body": 100},
	},
}

const ORB_DATA := {
	"fire_n": {
		"name": "Fire Spark",
		"element": "Fire",
		"rarity": "N",
		"effects": [
			{"type": "damage_percent", "percent": 10},
		],
	},
	"water_r": {
		"name": "Water Veil",
		"element": "Water",
		"rarity": "R",
		"effects": [
			{"type": "hit_bonus", "amount": 5},
			{"type": "proc_status", "status": "Chill", "chance_percent": 25},
		],
	},
	"lightning_r": {
		"name": "Lightning Fork",
		"element": "Lightning",
		"rarity": "R",
		"effects": [
			{"type": "hit_bonus", "amount": 5},
			{"type": "proc_status", "status": "Shock", "chance_percent": 50},
		],
	},
	"fire_sr": {
		"name": "Fire Brand",
		"element": "Fire",
		"rarity": "SR",
		"effects": [
			{"type": "damage_percent", "percent": 10},
			{"type": "hit_bonus", "amount": 5},
			{"type": "proc_status", "status": "Burn", "chance_percent": 35},
		],
	},
	"earth_ssr": {
		"name": "Earth Bulwark",
		"element": "Earth",
		"rarity": "SSR",
		"effects": [
			{"type": "damage_percent", "percent": 5},
			{"type": "hit_bonus", "amount": 5},
			{"type": "dodge_bonus", "amount": 5},
			{"type": "defense_bonus", "amount": 5},
			{"type": "proc_status", "status": "Rooted", "chance_percent": 20},
		],
	},
}

const DEFAULT_ORB_LOADOUTS := {
	"arlen": {
		"Right Arm": "fire_n",
	},
	"mira": {
		"Right Arm": "water_r",
		"Head": "lightning_r",
	},
	"sera": {
		"Right Arm": "fire_sr",
	},
	"brann": {
		"Left Arm": "earth_ssr",
	},
}

const PILOT_DATA := {
	"arlen": {
		"id": "arlen",
		"name": "Arlen",
		"title": "Breaker",
		"passive": {
			"id": "part_breaker",
			"name": "Part Breaker",
			"desc": "Attacks against damaged enemy parts deal +15% bonus damage.",
			"part_pressure_damage_percent": 15,
		},
	},
	"mira": {
		"id": "mira",
		"name": "Mira",
		"title": "Sharpshooter",
		"passive": {
			"id": "hawkeye",
			"name": "Hawkeye",
			"desc": "Attacks at distance 4 or greater gain +15% hit chance.",
			"long_range_hit_bonus": 15,
			"min_distance": 4,
		},
	},
	"sera": {
		"id": "sera",
		"name": "Sera",
		"title": "Spellweaver",
		"passive": {
			"id": "elemental_resonance",
			"name": "Elemental Resonance",
			"desc": "Increases Orb proc chance by +15%.",
			"orb_proc_bonus_percent": 15,
		},
	},
	"brann": {
		"id": "brann",
		"name": "Brann",
		"title": "Iron Wall",
		"passive": {
			"id": "guardian_stance",
			"name": "Guardian Stance",
			"desc": "Shield absorbs +5 damage and gains +15 Shield Max HP.",
			"shield_damage_reduction": 5,
			"shield_max_hp_bonus": 15,
		},
	},
}

const MISSIONS_DATA := {
	"ancient_ruins": {
		"id": "ancient_ruins",
		"name": "Ancient Ruins",
		"objective": "defeat_commander",
		"objective_label": "Defeat Commander",
		"purpose": "Baseline 7x10 combat, cover positions, stepped elevation up to H2.",
		"commander_id": "commander",
		"cover_tiles": [Vector2i(3, 2), Vector2i(5, 4), Vector2i(6, 2), Vector2i(8, 1)],
	},
	"crystal_quarry": {
		"id": "crystal_quarry",
		"name": "Crystal Quarry",
		"objective": "defeat_all",
		"objective_label": "Defeat All Enemies",
		"purpose": "Steeper terrain, H3 chokepoints, defeat-all objective, loot rewards.",
		"cover_tiles": [Vector2i(3, 1), Vector2i(3, 5), Vector2i(5, 3), Vector2i(7, 2)],
		"loot_table": {
			"credits": 500,
			"arcane_ore": 15,
			"orb_fragments": 8,
			"orb_drops": [
				{"orb": "Fire Orb", "weight": 35},
				{"orb": "Water Orb", "weight": 25},
				{"orb": "Electric Orb", "weight": 25},
				{"orb": "Earth Orb", "weight": 15},
			],
		},
	},
	"ascending_ridge": {
		"id": "ascending_ridge",
		"name": "Ascending Ridge",
		"objective": "defeat_commander",
		"objective_label": "Defeat Commander",
		"purpose": "Continuous slope H0-H4; test uphill assault vs downhill defense.",
		"commander_id": "commander",
		"cover_tiles": [Vector2i(3, 2), Vector2i(5, 4), Vector2i(7, 1), Vector2i(7, 5)],
	},
}

const PLAYER_UNIT_DATA := [
	{
		"id": "arlen",
		"name": "Arlen",
		"mech": "Aegis-07",
		"weapon": "Spear",
		"team": "player",
		"letter": "A",
		"grid": Vector2i(2, 3),
		"color": Color(0.47, 0.66, 0.56),
		"hp": 0.80,
		"parts": {"Head": 0.84, "Body": 0.91, "Left Arm": 0.74, "Right Arm": 0.83, "Legs": 0.78},
	},
	{
		"id": "mira",
		"name": "Mira",
		"mech": "Longview-02",
		"weapon": "Sniper",
		"team": "player",
		"letter": "M",
		"grid": Vector2i(1, 5),
		"color": Color(0.44, 0.58, 0.76),
		"hp": 0.88,
		"parts": {"Head": 0.94, "Body": 0.85, "Left Arm": 0.82, "Right Arm": 0.90, "Legs": 0.76},
	},
	{
		"id": "sera",
		"name": "Sera",
		"mech": "Volt-13",
		"weapon": "Rifle",
		"team": "player",
		"letter": "S",
		"grid": Vector2i(0, 1),
		"color": Color(0.59, 0.49, 0.76),
		"hp": 0.76,
		"parts": {"Head": 0.80, "Body": 0.78, "Left Arm": 0.69, "Right Arm": 0.74, "Legs": 0.79},
	},
	{
		"id": "brann",
		"name": "Brann",
		"mech": "Bulwark-04",
		"weapon": "Sword",
		"off_hand": "Shield",
		"team": "player",
		"letter": "B",
		"grid": Vector2i(2, 6),
		"color": Color(0.55, 0.64, 0.61),
		"hp": 0.92,
		"parts": {"Head": 0.89, "Body": 0.96, "Left Arm": 0.87, "Right Arm": 0.86, "Legs": 0.91},
	},
]

const MISSION_ENEMY_UNIT_DATA := {
	"ancient_ruins": [
		{
			"id": "enemy_blade",
			"name": "Enemy Blade",
			"mech": "Rust Frame",
			"weapon": "Sword",
			"team": "enemy",
			"letter": "E",
			"grid": Vector2i(7, 2),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.85,
			"parts": {"Head": 0.80, "Body": 0.85, "Left Arm": 0.78, "Right Arm": 0.76, "Legs": 0.82},
		},
		{
			"id": "enemy_rifle",
			"name": "Enemy Rifle",
			"mech": "Range Frame",
			"weapon": "Rifle",
			"team": "enemy",
			"letter": "R",
			"grid": Vector2i(8, 4),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.83,
			"parts": {"Head": 0.77, "Body": 0.83, "Left Arm": 0.81, "Right Arm": 0.79, "Legs": 0.84},
		},
		{
			"id": "enemy_sniper",
			"name": "Enemy Sniper",
			"mech": "Needle Frame",
			"weapon": "Sniper",
			"team": "enemy",
			"letter": "N",
			"grid": Vector2i(8, 1),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.78,
			"parts": {"Head": 0.82, "Body": 0.78, "Left Arm": 0.70, "Right Arm": 0.86, "Legs": 0.72},
		},
		{
			"id": "enemy_spear",
			"name": "Enemy Spear",
			"mech": "Pike Frame",
			"weapon": "Spear",
			"team": "enemy",
			"letter": "P",
			"grid": Vector2i(7, 5),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.82,
			"parts": {"Head": 0.80, "Body": 0.82, "Left Arm": 0.75, "Right Arm": 0.85, "Legs": 0.80},
		},
		{
			"id": "commander",
			"name": "Commander Kael",
			"mech": "High Ridge",
			"weapon": "Commander",
			"team": "enemy",
			"letter": "K",
			"grid": Vector2i(9, 3),
			"color": Color(0.72, 0.36, 0.36),
			"hp": 0.95,
			"parts": {"Head": 0.92, "Body": 0.95, "Left Arm": 0.90, "Right Arm": 0.90, "Legs": 0.86},
		},
	],
	"crystal_quarry": [
		{
			"id": "scavenger_alpha",
			"name": "Scavenger Alpha",
			"mech": "Scav-01",
			"weapon": "Sword",
			"team": "enemy",
			"letter": "A",
			"grid": Vector2i(6, 2),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.80,
			"parts": {"Head": 0.80, "Body": 0.80, "Left Arm": 0.75, "Right Arm": 0.75, "Legs": 0.80},
		},
		{
			"id": "scavenger_beta",
			"name": "Scavenger Beta",
			"mech": "Scav-02",
			"weapon": "Spear",
			"team": "enemy",
			"letter": "B",
			"grid": Vector2i(7, 4),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.80,
			"parts": {"Head": 0.80, "Body": 0.80, "Left Arm": 0.75, "Right Arm": 0.75, "Legs": 0.80},
		},
		{
			"id": "scavenger_gamma",
			"name": "Scavenger Gamma",
			"mech": "Scav-03",
			"weapon": "Rifle",
			"team": "enemy",
			"letter": "G",
			"grid": Vector2i(6, 5),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.80,
			"parts": {"Head": 0.80, "Body": 0.80, "Left Arm": 0.75, "Right Arm": 0.75, "Legs": 0.80},
		},
		{
			"id": "scavenger_delta",
			"name": "Scavenger Delta",
			"mech": "Scav-04",
			"weapon": "Sniper",
			"team": "enemy",
			"letter": "D",
			"grid": Vector2i(8, 3),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.75,
			"parts": {"Head": 0.75, "Body": 0.75, "Left Arm": 0.70, "Right Arm": 0.80, "Legs": 0.70},
		},
	],
	"ascending_ridge": [
		{
			"id": "enemy_blade",
			"name": "Enemy Blade",
			"mech": "Rust Frame",
			"weapon": "Sword",
			"team": "enemy",
			"letter": "E",
			"grid": Vector2i(6, 5),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.85,
			"parts": {"Head": 0.80, "Body": 0.85, "Left Arm": 0.78, "Right Arm": 0.76, "Legs": 0.82},
		},
		{
			"id": "enemy_ridge_guard",
			"name": "Ridge Guard",
			"mech": "Bulwark Frame",
			"weapon": "Sword",
			"off_hand": "Shield",
			"team": "enemy",
			"letter": "G",
			"grid": Vector2i(6, 3),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.90,
			"parts": {"Head": 0.85, "Body": 0.90, "Left Arm": 0.85, "Right Arm": 0.85, "Legs": 0.85},
		},
		{
			"id": "enemy_rifle",
			"name": "Enemy Rifle",
			"mech": "Range Frame",
			"weapon": "Rifle",
			"team": "enemy",
			"letter": "R",
			"grid": Vector2i(7, 4),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.83,
			"parts": {"Head": 0.77, "Body": 0.83, "Left Arm": 0.81, "Right Arm": 0.79, "Legs": 0.84},
		},
		{
			"id": "enemy_sniper",
			"name": "Enemy Sniper",
			"mech": "Needle Frame",
			"weapon": "Sniper",
			"team": "enemy",
			"letter": "N",
			"grid": Vector2i(8, 1),
			"color": Color(0.77, 0.43, 0.43),
			"hp": 0.78,
			"parts": {"Head": 0.82, "Body": 0.78, "Left Arm": 0.70, "Right Arm": 0.86, "Legs": 0.72},
		},
		{
			"id": "commander",
			"name": "Commander Kael",
			"mech": "High Ridge",
			"weapon": "Commander",
			"team": "enemy",
			"letter": "K",
			"grid": Vector2i(9, 3),
			"color": Color(0.72, 0.36, 0.36),
			"hp": 0.95,
			"parts": {"Head": 0.92, "Body": 0.95, "Left Arm": 0.90, "Right Arm": 0.90, "Legs": 0.86},
		},
	],
}

const UNIT_INITIATIVE_DATA := {
	"arlen": {"speed": 10, "initial_time": 0.0},
	"mira": {"speed": 9, "initial_time": 2.0},
	"sera": {"speed": 8, "initial_time": 4.0},
	"brann": {"speed": 5, "initial_time": 6.0},
	"enemy_blade": {"speed": 8, "initial_time": 1.0},
	"enemy_ridge_guard": {"speed": 5, "initial_time": 2.5},
	"enemy_rifle": {"speed": 7, "initial_time": 3.0},
	"enemy_spear": {"speed": 7, "initial_time": 3.5},
	"enemy_sniper": {"speed": 4, "initial_time": 7.0},
	"commander": {"speed": 6, "initial_time": 5.0},
	"scavenger_alpha": {"speed": 8, "initial_time": 1.0},
	"scavenger_beta": {"speed": 7, "initial_time": 3.0},
	"scavenger_gamma": {"speed": 7, "initial_time": 3.5},
	"scavenger_delta": {"speed": 5, "initial_time": 5.0},
}

const BENCHMARK_SEEDS: Array[int] = [42, 101, 777, 1337, 9999]

const SENSIBLE_LOADOUT := {
	"arlen": {
		"weapon": "Sword",
		"pilot": "arlen",
		"clear_orbs": true,
		"orbs": {
			"Right Arm": "fire_n",
		},
	},
	"mira": {
		"weapon": "Sniper",
		"pilot": "mira",
		"clear_orbs": true,
		"orbs": {
			"Right Arm": "water_r",
			"Head": "lightning_r",
		},
	},
	"sera": {
		"weapon": "Rifle",
		"pilot": "sera",
		"clear_orbs": true,
		"orbs": {
			"Right Arm": "fire_sr",
		},
	},
	"brann": {
		"weapon": "Sword",
		"off_hand": "Shield",
		"pilot": "brann",
		"clear_orbs": true,
		"orbs": {
			"Left Arm": "earth_ssr",
		},
	},
}

const MISMATCHED_LOADOUT := {
	"arlen": {
		"weapon": "Sniper",
		"pilot": "arlen",
		"clear_orbs": true,
		"orbs": {},
	},
	"mira": {
		"weapon": "Sword",
		"pilot": "mira",
		"clear_orbs": true,
		"orbs": {},
	},
	"sera": {
		"weapon": "Sword",
		"pilot": "sera",
		"clear_orbs": true,
		"orbs": {},
	},
	"brann": {
		"weapon": "Spear",
		"pilot": "brann",
		"clear_orbs": true,
		"orbs": {},
	},
}


func create_units_for_mission(mission_id: String, swapped_sides: bool, grid_columns: int = GRID_COLUMNS) -> Array:
	var mission_key: String = mission_id if MISSION_ENEMY_UNIT_DATA.has(mission_id) else "ancient_ruins"
	var created_units: Array = []

	for unit_data in PLAYER_UNIT_DATA:
		created_units.append(unit_data.duplicate(true))
	for unit_data in MISSION_ENEMY_UNIT_DATA[mission_key]:
		created_units.append(unit_data.duplicate(true))

	if swapped_sides:
		for unit in created_units:
			unit["grid"] = Vector2i(grid_columns - 1 - unit["grid"].x, unit["grid"].y)

	for unit in created_units:
		var initiative_data: Dictionary = UNIT_INITIATIVE_DATA.get(str(unit["id"]), {})
		unit["speed"] = int(initiative_data.get("speed", 5))
		unit["initiative_time"] = float(initiative_data.get("initial_time", 0.0))

	return created_units
