extends Control

signal presented_attack_completed

const PROTOTYPE_VERSION := "0.1"
const GRID_COLUMNS := 10
const GRID_ROWS := 7
const MOVE_RANGE := 3
const PRIMARY_ACTIONS := ["Move", "Attack", "Wait"]
const INITIATIVE_ROUND := 100.0
const PART_MAX_HP := 100
const PLACEHOLDER_ATTACK_DAMAGE := 25
const PLACEHOLDER_HIT_PERCENT := 80
const HEAD_DESTROYED_HIT_PENALTY := -30
const HEIGHT_HIT_PER_LEVEL := 5
const HEIGHT_HIT_CAP := 15
const COVER_DODGE_BONUS := 10
const COVER_DAMAGE_REDUCTION_PERCENT := 10
const ENEMY_ACTIVATION_HIGHLIGHT_SECONDS := 0.12
const ENEMY_MOVE_STEP_SECONDS := 0.12
const PLACEHOLDER_WEAPON_RANGES := {
	"Sword": 1,
	"Spear": 2,
	"Sniper": 6,
	"Rifle": 5,
	"Shield": 1,
	"Blade": 1,
	"Commander": 5,
}
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
		"part_weights": {"Body": 100},
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
	"Shield": {
		"name": "Shield",
		"range_min": 1,
		"range_max": 1,
		"damage": PLACEHOLDER_ATTACK_DAMAGE,
		"hit_percent": PLACEHOLDER_HIT_PERCENT,
		"allow_manual_part": true,
		"pattern": "single",
		"blockable": false,
		"shield_max_hp": 25,
		"shield_hit_weight": 55,
		"part_weights": {"Body": 100},
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

const BURN_DAMAGE := 10

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

const MISSIONS_DATA := {
	"ancient_ruins": {
		"id": "ancient_ruins",
		"name": "Ancient Ruins",
		"objective": "defeat_commander",
		"objective_label": "Defeat Commander",
		"commander_id": "commander",
		"cover_tiles": [Vector2i(3, 2), Vector2i(5, 4), Vector2i(6, 2), Vector2i(8, 1)],
	},
	"crystal_quarry": {
		"id": "crystal_quarry",
		"name": "Crystal Quarry",
		"objective": "defeat_all",
		"objective_label": "Defeat All Enemies",
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
		"commander_id": "commander",
		"cover_tiles": [Vector2i(3, 2), Vector2i(5, 4), Vector2i(7, 1), Vector2i(7, 5)],
	},
}


const DESIGN_SIZE := Vector2(1311.0, 603.0)
const TILE_SIZE := Vector2(77.0, 41.0)
const TILE_SPACING := Vector2(80.0, 44.0)
const ELEVATION_STEP := 9.0
const GRID_ORIGIN := Vector2(228.0, 140.0)
const PART_NAMES := ["Head", "Body", "Left Arm", "Right Arm", "Legs"]
const DIRECTIONS := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

enum TurnState {
	TURN_START,
	AWAITING_COMMAND,
	SELECTING_MOVE,
	MOVE_PREVIEW,
	MOVE_COMPLETE,
	SELECTING_ATTACK,
	ACTION_COMPLETE,
	TURN_END,
}

var current_mission := "ancient_ruins"
var mission_swapped_sides := false
var units := []

var active_unit = null
var selected_unit = null
var selected_action := "Move"
var reachable_tiles := {}
var targetable_tiles := {}
var attack_overlay_tiles := {}
var action_rects := {}
var preview_move_destination = null
var preview_move_path: Array[Vector2i] = []
var move_confirm_rect := Rect2()
var move_cancel_rect := Rect2()
var turn_state: int = TurnState.TURN_START

var initiative_timeline: Array[String] = []
var turn_log: Array[String] = []
var turn_number := 1
var last_action_message := "Ready"
var target_preview := {}
var last_attack_result := {}
var last_enemy_attack_result := {}
var terrain_tiles := {}
var auto_battle := false
var simulation_seed := 1337
var reward_seed := 4242
var _is_activating := false
var enemy_presentation_enabled := true
var enemy_presentation_active := false
var enemy_presentation_log: Array[String] = []
var attack_presentation_enabled := true
var attack_presentation_active := false
var attack_feedback_step_seconds := 0.12
var attack_feedback_queue: Array[String] = []
var attack_feedback_log: Array[String] = []
var attack_feedback_attacker_id := ""
var attack_feedback_target_id := ""



func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_mission("ancient_ruins")
	print("Magic Robot Tactic War combat prototype v%s" % PROTOTYPE_VERSION)
	print("Graybox battle milestone loaded: 7x10 grid, selection, movement, and Phase 1 HUD.")


func _load_mission(mission_id: String, swapped_sides: bool = false) -> void:
	if not MISSIONS_DATA.has(mission_id):
		return
	current_mission = mission_id
	mission_swapped_sides = swapped_sides
	turn_number = 1
	turn_log.clear()
	enemy_presentation_log.clear()
	enemy_presentation_active = false
	attack_feedback_log.clear()
	attack_feedback_queue.clear()
	attack_presentation_active = false
	attack_feedback_attacker_id = ""
	attack_feedback_target_id = ""
	last_action_message = "Ready"
	_create_terrain()
	_create_units()
	_apply_default_orb_loadouts()
	_initialize_initiative()
	_begin_next_activation()




func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()



func _gui_input(event: InputEvent) -> void:
	var press_position = _event_press_position(event)
	if press_position == null:
		return
	if _input_locked():
		accept_event()
		return

	if turn_state == TurnState.MOVE_PREVIEW:
		if move_confirm_rect.has_point(press_position):
			_confirm_move()
			accept_event()
			return
		elif move_cancel_rect.has_point(press_position):
			_cancel_move_preview()
			accept_event()
			return

	for action in PRIMARY_ACTIONS:
		if action_rects.has(action) and action_rects[action].has_point(press_position):
			_select_action(action)
			accept_event()
			return

	var tapped_unit = _unit_at_position(press_position)
	if tapped_unit != null:
		if turn_state == TurnState.MOVE_PREVIEW:
			if _is_active_unit(tapped_unit):
				_cancel_move_preview()
				accept_event()
				return
		elif selected_action == "Attack" and turn_state == TurnState.SELECTING_ATTACK:
			if _is_active_unit(tapped_unit):
				_cancel_attack_selection()
			elif selected_unit != null and selected_unit["id"] == tapped_unit["id"] and _is_attack_target_legal(active_unit, tapped_unit):
				_confirm_attack_target(tapped_unit)
			else:
				_inspect_target(tapped_unit)
			accept_event()
			return

		_inspect_unit(tapped_unit)
		accept_event()
		return


	_handle_grid_tap(press_position)
	accept_event()


func _draw() -> void:
	_draw_background()
	_draw_battlefield()
	_draw_selected_unit_panel()
	_draw_initiative_strip()
	_draw_mission_panel()
	_draw_part_status_panel()
	_draw_enemy_inspection_panel()
	_draw_action_bar()


func _create_units() -> void:
	var player_units := [
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
			"weapon": "Shield",
			"team": "player",
			"letter": "B",
			"grid": Vector2i(2, 6),
			"color": Color(0.55, 0.64, 0.61),
			"hp": 0.92,
			"parts": {"Head": 0.89, "Body": 0.96, "Left Arm": 0.87, "Right Arm": 0.86, "Legs": 0.91},
		},
	]

	var enemy_units := []
	var speed_by_id := {
		"arlen": 10,
		"mira": 9,
		"sera": 8,
		"brann": 5,
	}
	var initial_time_by_id := {
		"arlen": 0.0,
		"mira": 2.0,
		"sera": 4.0,
		"brann": 6.0,
	}

	if current_mission == "crystal_quarry":
		enemy_units = [
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
		]
		speed_by_id["scavenger_alpha"] = 8
		speed_by_id["scavenger_beta"] = 7
		speed_by_id["scavenger_gamma"] = 7
		speed_by_id["scavenger_delta"] = 5
		initial_time_by_id["scavenger_alpha"] = 1.0
		initial_time_by_id["scavenger_beta"] = 3.0
		initial_time_by_id["scavenger_gamma"] = 3.5
		initial_time_by_id["scavenger_delta"] = 5.0
	elif current_mission == "ascending_ridge":
		enemy_units = [
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
				"weapon": "Shield",
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
		]
		speed_by_id["enemy_blade"] = 8
		speed_by_id["enemy_ridge_guard"] = 5
		speed_by_id["enemy_rifle"] = 7
		speed_by_id["commander"] = 6
		speed_by_id["enemy_sniper"] = 4
		initial_time_by_id["enemy_blade"] = 1.0
		initial_time_by_id["enemy_ridge_guard"] = 2.5
		initial_time_by_id["enemy_rifle"] = 3.0
		initial_time_by_id["commander"] = 5.0
		initial_time_by_id["enemy_sniper"] = 7.0
	else:
		enemy_units = [
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
		]
		speed_by_id["enemy_blade"] = 8
		speed_by_id["enemy_rifle"] = 7
		speed_by_id["enemy_spear"] = 7
		speed_by_id["commander"] = 6
		speed_by_id["enemy_sniper"] = 4
		initial_time_by_id["enemy_blade"] = 1.0
		initial_time_by_id["enemy_rifle"] = 3.0
		initial_time_by_id["enemy_spear"] = 3.5
		initial_time_by_id["commander"] = 5.0
		initial_time_by_id["enemy_sniper"] = 7.0

	units = player_units + enemy_units

	if mission_swapped_sides:
		for unit in units:
			unit["grid"] = Vector2i(GRID_COLUMNS - 1 - unit["grid"].x, unit["grid"].y)


	for unit in units:
		unit["speed"] = speed_by_id[unit["id"]]
		unit["initiative_time"] = initial_time_by_id[unit["id"]]
		unit["accuracy_modifier"] = 0
		unit["base_move_range"] = MOVE_RANGE
		unit["current_move_range"] = MOVE_RANGE
		unit["dodge"] = 10
		unit["weapon_mount_part"] = _weapon_mount_part(unit)
		unit["weapon_disabled"] = false
		var weapon_data := _weapon_data_for(unit)
		unit["shield_max_hp"] = int(weapon_data.get("shield_max_hp", 0))
		unit["shield_hp"] = int(unit["shield_max_hp"])
		unit["shield_disabled"] = int(unit["shield_max_hp"]) <= 0
		unit["defeated"] = false
		unit["in_battle"] = true
		unit["statuses"] = []
		unit["has_moved"] = false
		unit["has_attacked"] = false
		unit["activation_complete"] = false
		_initialize_part_state(unit)


func _select_unit(unit) -> void:
	selected_unit = unit
	target_preview.clear()
	targetable_tiles.clear()
	attack_overlay_tiles.clear()
	if _is_active_unit(unit):
		if _can_move(unit):
			selected_action = "Move"
			turn_state = TurnState.SELECTING_MOVE
			reachable_tiles = _calculate_reachable_tiles(unit)
		else:
			selected_action = "Attack" if _can_attack(unit) else "Wait"
			reachable_tiles.clear()
	else:
		reachable_tiles.clear()
	queue_redraw()


func _select_action(action: String) -> void:
	if _input_locked():
		return
	if not PRIMARY_ACTIONS.has(action):
		return

	if action != "Move" and turn_state == TurnState.MOVE_PREVIEW:
		_cancel_move_preview()

	if action == "Move":
		if _can_move(active_unit):
			selected_action = action
			turn_state = TurnState.SELECTING_MOVE
			selected_unit = active_unit
			reachable_tiles = _calculate_reachable_tiles(active_unit)
			attack_overlay_tiles.clear()
	elif action == "Attack":
		selected_action = action
		reachable_tiles.clear()
		if active_unit != null and _is_active_unit(active_unit) and _is_unit_in_battle(active_unit) and not bool(active_unit["weapon_disabled"]) and not bool(active_unit["has_attacked"]) and not bool(active_unit["activation_complete"]):
			turn_state = TurnState.SELECTING_ATTACK
			selected_unit = active_unit
			_refresh_attack_overlay()
			target_preview.clear()
	elif action == "Wait":
		selected_action = action
		reachable_tiles.clear()
		targetable_tiles.clear()
		attack_overlay_tiles.clear()
		target_preview.clear()
		if _can_wait(active_unit):
			_try_wait_active_unit()
	queue_redraw()


func _handle_grid_tap(position: Vector2) -> void:
	if _input_locked():
		return
	var grid = _grid_at_position(position)
	if grid == null:
		return

	if active_unit == null or active_unit["team"] != "player":
		return

	if selected_action == "Move":
		if turn_state == TurnState.MOVE_PREVIEW and preview_move_destination != null and grid == preview_move_destination:
			_confirm_move()
		elif turn_state == TurnState.SELECTING_MOVE or turn_state == TurnState.MOVE_PREVIEW:
			_preview_move_destination(grid)
		queue_redraw()
	elif selected_action == "Attack" and turn_state == TurnState.SELECTING_ATTACK:
		if attack_overlay_tiles.has(_grid_key(grid)):
			var entry: Dictionary = attack_overlay_tiles[_grid_key(grid)]
			var reason := str(entry.get("reason", ""))
			if reason != "":
				last_action_message = reason

				queue_redraw()
				return
		_cancel_attack_selection()



func _initialize_initiative() -> void:
	turn_log.clear()
	turn_number = 1
	active_unit = null
	selected_unit = null
	selected_action = "Move"
	reachable_tiles.clear()
	targetable_tiles.clear()
	target_preview.clear()
	last_attack_result.clear()
	last_enemy_attack_result.clear()
	turn_state = TurnState.TURN_START
	for unit in units:
		unit["has_moved"] = false
		unit["has_attacked"] = false
		unit["activation_complete"] = false
		if not unit.has("in_battle"):
			unit["in_battle"] = not bool(unit.get("defeated", false))
	_rebuild_initiative_timeline()


func _rebuild_initiative_timeline() -> void:
	var ordered_units := units.duplicate()
	ordered_units.sort_custom(func(a, b):
		var a_time := float(a["initiative_time"])
		var b_time := float(b["initiative_time"])
		if is_equal_approx(a_time, b_time):
			return str(a["id"]) < str(b["id"])
		return a_time < b_time
	)

	initiative_timeline.clear()
	for unit in ordered_units:
		if _is_unit_in_battle(unit):
			initiative_timeline.append(str(unit["id"]))


func _begin_next_activation() -> void:
	if _is_battle_over():
		return

	_is_activating = true
	for _index in range(units.size() * 4):
		_rebuild_initiative_timeline()
		if initiative_timeline.is_empty():
			_is_activating = false
			return

		var next_unit = _unit_by_id(initiative_timeline[0])
		if next_unit == null:
			_is_activating = false
			return

		_begin_activation(next_unit)
		if not _is_unit_in_battle(next_unit):
			_finish_activation(next_unit)
			if _is_battle_over():
				_is_activating = false
				return
			continue

		if next_unit["team"] == "player":
			if not auto_battle:
				_is_activating = false
				return
			_resolve_ai_activation(next_unit)
		else:
			if auto_battle or not enemy_presentation_enabled:
				_resolve_enemy_activation(next_unit)
			else:
				var enemy_plan := _plan_ai_activation(next_unit)
				_is_activating = false
				_present_enemy_activation.call_deferred(next_unit, enemy_plan)
				return
		if _is_battle_over():
			_is_activating = false
			return

	_is_activating = false


func _begin_activation(unit) -> void:
	if not _is_unit_in_battle(unit):
		return

	active_unit = unit
	selected_unit = unit
	unit["has_moved"] = false
	unit["has_attacked"] = false
	unit["activation_complete"] = false
	turn_state = TurnState.TURN_START
	reachable_tiles.clear()
	targetable_tiles.clear()
	attack_overlay_tiles.clear()
	target_preview.clear()
	_clear_move_preview()

	_resolve_turn_start_statuses(unit)
	if not _is_unit_in_battle(unit):
		turn_state = TurnState.ACTION_COMPLETE
		queue_redraw()
		return

	if unit["team"] == "player":
		turn_state = TurnState.AWAITING_COMMAND
		selected_action = "Move" if _can_move(unit) else "Wait"
		if selected_action == "Move":
			turn_state = TurnState.SELECTING_MOVE
			reachable_tiles = _calculate_reachable_tiles(unit)
	else:
		selected_action = "Wait"

	queue_redraw()


func _resolve_enemy_activation(unit) -> void:
	var plan := _plan_ai_activation(unit)
	_resolve_planned_ai_activation_fast(unit, plan)


func _resolve_ai_activation(unit) -> Dictionary:
	if unit == null or not _is_unit_in_battle(unit):
		return {}

	var plan := _plan_ai_activation(unit)
	_resolve_planned_ai_activation_fast(unit, plan)
	return plan


func _plan_ai_activation(unit) -> Dictionary:
	var decision := _decide_ai_action(unit)
	var path := []
	if decision.get("move_to") != null:
		path = _movement_path_to(unit, decision["move_to"])
	decision["path"] = path
	decision["start_grid"] = unit["grid"] if unit != null else Vector2i.ZERO
	return decision


func _resolve_planned_ai_activation_fast(unit, plan: Dictionary) -> Dictionary:
	if unit == null or not _is_unit_in_battle(unit):
		return {}
	var move_to = plan.get("move_to")
	if move_to != null and _can_move(unit):
		_try_move_active_unit(move_to)
	var attacked := false
	if str(plan.get("action", "")) == "Attack" and plan.get("target") != null and _can_attack(unit):
		var sim_seed := _next_simulation_seed()
		attacked = _try_attack_active_unit(plan["target"], "", sim_seed)

	if not attacked:
		if str(unit.get("team", "")) == "enemy":
			unit["activation_complete"] = true
			turn_log.append("%s:enemy_wait" % unit["id"])
			last_action_message = "%s holds position" % unit["name"]
			_finish_activation(unit)
		else:
			_try_wait_active_unit()

	return plan


func _present_enemy_activation(unit, plan: Dictionary) -> void:
	if unit == null or not _is_unit_in_battle(unit):
		return
	if auto_battle:
		_resolve_planned_ai_activation_fast(unit, plan)
		return

	enemy_presentation_active = true
	_is_activating = true
	selected_unit = unit
	active_unit = unit
	last_action_message = "%s activates" % unit["name"]
	enemy_presentation_log.append("%s:activate" % unit["id"])
	queue_redraw()
	await get_tree().create_timer(ENEMY_ACTIVATION_HIGHLIGHT_SECONDS).timeout

	var path: Array = plan.get("path", [])
	for step in path:
		unit["grid"] = step
		last_action_message = "%s moves" % unit["name"]
		enemy_presentation_log.append("%s:presentation_move:(%d,%d)" % [unit["id"], step.x, step.y])
		queue_redraw()
		await get_tree().create_timer(ENEMY_MOVE_STEP_SECONDS).timeout

	if not path.is_empty():
		unit["has_moved"] = true
		var final_grid: Vector2i = path[path.size() - 1]
		turn_log.append("%s:move:(%d,%d)" % [unit["id"], final_grid.x, final_grid.y])
		reachable_tiles.clear()
		targetable_tiles.clear()
		target_preview.clear()
		turn_state = TurnState.MOVE_COMPLETE

	var attacked := false
	if str(plan.get("action", "")) == "Attack" and plan.get("target") != null and _can_attack(unit):
		var sim_seed := _next_simulation_seed()
		var preview := _attack_preview(unit, plan["target"])
		if bool(preview["legal"]):
			var attack_res := _resolve_attack_result(unit, plan["target"], preview, "", sim_seed)
			if attack_presentation_enabled:
				await _present_attack_feedback(unit, plan["target"], attack_res)
			_finish_activation(unit)
			attacked = true

	if not attacked and _is_unit_in_battle(unit):
		unit["activation_complete"] = true
		turn_log.append("%s:enemy_wait" % unit["id"])
		last_action_message = "%s holds position" % unit["name"]
		_finish_activation(unit)

	enemy_presentation_active = false
	_is_activating = false
	queue_redraw()
	if not _is_battle_over():
		_begin_next_activation()


func _decide_ai_action(unit) -> Dictionary:
	if unit == null or not _is_unit_in_battle(unit):
		return {"action": "Wait", "move_to": null, "target": null}

	var opponents := _opponents_of(unit)
	if opponents.is_empty():
		return {"action": "Wait", "move_to": null, "target": null}

	var can_move_now := _can_move(unit)
	var candidate_tiles: Array[Vector2i] = [unit["grid"]]
	if can_move_now:
		var reachable := _calculate_reachable_tiles(unit)
		for key in reachable.keys():
			candidate_tiles.append(_grid_from_key(key))

	var best_attack_option: Dictionary = {}
	var original_grid: Vector2i = unit["grid"]

	for tile in candidate_tiles:
		unit["grid"] = tile
		var valid_targets := _valid_attack_targets(unit)
		for target in valid_targets:
			var preview := _attack_preview(unit, target)
			if not bool(preview.get("legal", false)):
				continue
			var score := _score_attack_option(unit, target, tile, preview)
			if best_attack_option.is_empty() or score > float(best_attack_option["score"]):
				best_attack_option = {
					"score": score,
					"move_to": tile if tile != original_grid else null,
					"target": target,
					"preview": preview,
					"action": "Attack",
				}

	unit["grid"] = original_grid

	if not best_attack_option.is_empty():
		return best_attack_option

	if can_move_now and candidate_tiles.size() > 1:
		var target_opponent = _primary_objective_target(unit)
		if target_opponent != null:
			var best_move_tile: Vector2i = original_grid
			var best_move_score := -999999.0
			for tile in candidate_tiles:
				var score := _score_move_tile(unit, tile, target_opponent["grid"])
				if score > best_move_score:
					best_move_score = score
					best_move_tile = tile
			if best_move_tile != original_grid:
				return {"action": "Wait", "move_to": best_move_tile, "target": null}

	return {"action": "Wait", "move_to": null, "target": null}


func _score_attack_option(attacker, target, candidate_grid: Vector2i, preview: Dictionary) -> float:
	var score := 100.0
	var hit_percent := int(preview.get("hit_percent", 0))
	score += float(hit_percent) * 1.5

	if str(target.get("id", "")) == "commander":
		score += 80.0

	var damage := int(preview.get("damage", 0))
	score += float(damage) * 2.0

	if target.get("parts", {}).has("Body"):
		var body_hp: int = int(target["parts"]["Body"]["hp"])
		if damage >= body_hp:
			score += 150.0

	var weapon_arm: String = _weapon_mount_part(target)
	if target.get("parts", {}).has(weapon_arm):
		var arm_hp: int = int(target["parts"][weapon_arm]["hp"])
		if damage >= arm_hp:
			score += 35.0

	var weapon_data := _weapon_data_for(attacker)
	if _intercepting_shield_for(attacker, target, weapon_data) != null:
		score -= 50.0

	if _has_cover(target["grid"]):
		score -= 15.0

	if _has_cover(candidate_grid):
		score += 10.0
	score += float(_height_at(candidate_grid)) * 3.0
	score -= float(_grid_distance(attacker["grid"], candidate_grid)) * 0.5
	return score


func _score_move_tile(unit, candidate_grid: Vector2i, target_grid: Vector2i) -> float:
	var dist := float(_grid_distance(candidate_grid, target_grid))
	var score: float = 100.0 - dist * 10.0
	if _has_cover(candidate_grid):
		score += 5.0
	score += float(_height_at(candidate_grid)) * 2.0
	return score


func _movement_path_to(unit, destination: Vector2i) -> Array:
	var path := []
	if unit == null or not _is_unit_in_battle(unit):
		return path
	var start: Vector2i = unit["grid"]
	if start == destination:
		return path

	var visited := {}
	var previous := {}
	var frontier := [start]
	visited[_grid_key(start)] = true

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		for direction in DIRECTIONS:
			var next_grid: Vector2i = current + direction
			var key := _grid_key(next_grid)
			if not _is_in_bounds(next_grid) or visited.has(key):
				continue
			if not _can_traverse_step(current, next_grid):
				continue
			if _occupied_by_opponent(next_grid, str(unit["team"])):
				continue
			if _occupied_by_any_unit(next_grid) and next_grid != destination:
				continue
			visited[key] = true
			previous[key] = current
			if next_grid == destination:
				var cursor := destination
				while cursor != start:
					path.push_front(cursor)
					cursor = previous[_grid_key(cursor)]
				return path
			frontier.append(next_grid)
	return path


func _opponents_of(unit) -> Array:
	var opps := []
	if unit == null:
		return opps
	for other in units:
		if _is_unit_in_battle(other) and other["team"] != unit["team"]:
			opps.append(other)
	return opps


func _primary_objective_target(unit):
	var opps := _opponents_of(unit)
	if opps.is_empty():
		return null
	if str(unit.get("team", "")) == "player":
		for opp in opps:
			if str(opp.get("id", "")) == "commander":
				return opp
	var closest = opps[0]
	var min_dist := _grid_distance(unit["grid"], closest["grid"])
	for opp in opps:
		var d := _grid_distance(unit["grid"], opp["grid"])
		if d < min_dist:
			min_dist = d
			closest = opp
	return closest


func _finish_activation(unit) -> void:
	turn_state = TurnState.ACTION_COMPLETE
	reachable_tiles.clear()
	targetable_tiles.clear()
	attack_overlay_tiles.clear()
	target_preview.clear()
	_clear_move_preview()
	_schedule_future_activation(unit)
	turn_state = TurnState.TURN_END
	active_unit = null
	turn_number += 1
	if _is_battle_over():
		var winner := _battle_winner()
		var res_marker := "mission_result:%s:%s" % [current_mission, winner]
		if not turn_log.has(res_marker):
			turn_log.append(res_marker)
	if not _is_activating and not auto_battle:
		_begin_next_activation()



func _schedule_future_activation(unit) -> void:
	unit["initiative_time"] = float(unit["initiative_time"]) + ceil(INITIATIVE_ROUND / float(unit["speed"]))
	_rebuild_initiative_timeline()


func _can_move(unit) -> bool:
	return (
		unit != null
		and _is_active_unit(unit)
		and _is_unit_in_battle(unit)
		and _movement_range_for(unit) > 0
		and not bool(unit["has_moved"])
		and not bool(unit["activation_complete"])
	)


func _can_attack(unit) -> bool:
	return (
		unit != null
		and _is_active_unit(unit)
		and _is_unit_in_battle(unit)
		and not bool(unit["weapon_disabled"])
		and not bool(unit["has_attacked"])
		and not bool(unit["activation_complete"])
		and not _valid_attack_targets(unit).is_empty()
	)


func _can_wait(unit) -> bool:
	return (
		unit != null
		and _is_active_unit(unit)
		and _is_unit_in_battle(unit)
		and not bool(unit["activation_complete"])
	)



func _is_action_legal(action: String) -> bool:
	if action == "Move":
		return _can_move(active_unit)
	if action == "Attack":
		return _can_attack(active_unit)
	if action == "Wait":
		return _can_wait(active_unit)
	return false


func _input_locked() -> bool:
	return enemy_presentation_active or attack_presentation_active


func _clear_move_preview() -> void:
	preview_move_destination = null
	preview_move_path.clear()
	move_confirm_rect = Rect2()
	move_cancel_rect = Rect2()


func _preview_move_destination(destination: Vector2i) -> bool:
	if active_unit == null or not _can_move(active_unit):
		return false

	if reachable_tiles.is_empty():
		reachable_tiles = _calculate_reachable_tiles(active_unit)

	var key := _grid_key(destination)
	if not reachable_tiles.has(key) or _occupied_by_any_unit(destination):
		return false

	preview_move_destination = destination
	preview_move_path = _calculate_move_path(active_unit, destination)
	turn_state = TurnState.MOVE_PREVIEW
	last_action_message = "Previewing move to (%d, %d). Confirm or Cancel." % [destination.x, destination.y]

	if _can_attack(active_unit):
		attack_overlay_tiles = _calculate_attack_overlay_tiles(active_unit, destination)
	else:
		attack_overlay_tiles.clear()

	queue_redraw()
	return true


func _confirm_move() -> bool:
	if active_unit == null or preview_move_destination == null or turn_state != TurnState.MOVE_PREVIEW:
		return false

	var destination: Vector2i = preview_move_destination
	_clear_move_preview()
	return _try_move_active_unit(destination)


func _cancel_move_preview() -> void:
	if active_unit == null:
		_clear_move_preview()
		return

	_clear_move_preview()
	turn_state = TurnState.SELECTING_MOVE
	selected_action = "Move"
	reachable_tiles = _calculate_reachable_tiles(active_unit)
	attack_overlay_tiles.clear()
	targetable_tiles.clear()
	target_preview.clear()
	last_action_message = "Move preview cancelled"
	queue_redraw()


func _calculate_move_path(unit, destination: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if unit == null:
		return path
	var start: Vector2i = unit["grid"]
	if start == destination:
		path.append(start)
		return path

	var move_range: int = _movement_range_for(unit)
	var queue: Array[Vector2i] = [start]
	var came_from := {}
	var dist := {}
	came_from[_grid_key(start)] = null
	dist[_grid_key(start)] = 0

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == destination:
			break
		if dist[_grid_key(current)] >= move_range:
			continue

		for direction in DIRECTIONS:
			var next_grid: Vector2i = current + direction
			if not _is_in_bounds(next_grid):
				continue
			if not _can_traverse_step(current, next_grid):
				continue
			if _occupied_by_opponent(next_grid, str(unit["team"])):
				continue
			var next_key := _grid_key(next_grid)
			if not came_from.has(next_key):
				came_from[next_key] = current
				dist[next_key] = dist[_grid_key(current)] + 1
				queue.append(next_grid)

	if not came_from.has(_grid_key(destination)):
		return path

	var cursor: Variant = destination
	while cursor != null:
		path.append(cursor)
		cursor = came_from[_grid_key(cursor)]
	path.reverse()
	return path


func _try_move_active_unit(grid: Vector2i) -> bool:
	if _input_locked() and not auto_battle and active_unit != null and str(active_unit.get("team", "")) == "player":
		return false
	if not _can_move(active_unit):
		return false

	if reachable_tiles.is_empty():
		reachable_tiles = _calculate_reachable_tiles(active_unit)

	var key := _grid_key(grid)
	if not reachable_tiles.has(key) or _occupied_by_any_unit(grid):
		return false

	active_unit["grid"] = grid
	active_unit["has_moved"] = true
	turn_log.append("%s:move:(%d,%d)" % [active_unit["id"], grid.x, grid.y])
	reachable_tiles.clear()
	targetable_tiles.clear()
	attack_overlay_tiles.clear()
	target_preview.clear()
	_clear_move_preview()
	turn_state = TurnState.MOVE_COMPLETE
	selected_action = "Attack" if _can_attack(active_unit) else "Wait"
	last_action_message = "%s moved" % active_unit["name"]
	return true



func _try_attack_active_unit(target = null, part_name := "", seed := 0) -> bool:
	if _input_locked() and not auto_battle and active_unit != null and str(active_unit.get("team", "")) == "player":
		return false
	if not _can_attack(active_unit):
		return false

	var acting_unit = active_unit
	var chosen_target = target
	if chosen_target == null:
		var valid_targets := _valid_attack_targets(acting_unit)
		if valid_targets.is_empty():
			return false
		chosen_target = valid_targets[0]

	var preview := _attack_preview(acting_unit, chosen_target)
	target_preview = preview
	if not bool(preview["legal"]):
		return false

	_resolve_attack(acting_unit, chosen_target, preview, part_name, seed)
	return true


func _confirm_attack_target(target, part_name := "", seed := 0) -> bool:
	if target == null or active_unit == null:
		return false

	target_preview = _attack_preview(active_unit, target)
	selected_unit = target
	if not bool(target_preview["legal"]):
		last_action_message = _attack_target_reason(active_unit, target)
		queue_redraw()
		return false

	var resolved := _try_attack_active_unit(target, part_name, seed)
	queue_redraw()
	return resolved


func _cancel_attack_selection() -> void:
	if active_unit == null:
		return

	selected_unit = active_unit
	targetable_tiles.clear()
	attack_overlay_tiles.clear()
	target_preview.clear()
	if _can_move(active_unit):
		selected_action = "Move"
		turn_state = TurnState.SELECTING_MOVE
		reachable_tiles = _calculate_reachable_tiles(active_unit)
	else:
		selected_action = "Attack" if _can_attack(active_unit) else "Wait"
		turn_state = TurnState.AWAITING_COMMAND
		reachable_tiles.clear()
	queue_redraw()


func _preview_attack_target(target) -> Dictionary:
	if active_unit == null:
		target_preview.clear()
		return target_preview

	target_preview = _attack_preview(active_unit, target)
	selected_unit = target
	if not bool(target_preview.get("legal", false)):
		last_action_message = _attack_target_reason(active_unit, target)
	queue_redraw()
	return target_preview


func _resolve_attack(attacker, target, preview: Dictionary, part_name := "", seed := 0) -> Dictionary:
	var attack_res := _resolve_attack_result(attacker, target, preview, part_name, seed)
	if (
		attack_presentation_enabled
		and not auto_battle
		and not _is_activating
		and str(attacker.get("team", "")) == "player"
	):
		_is_activating = true
		attack_presentation_active = true
		attack_feedback_attacker_id = str(attacker["id"])
		attack_feedback_target_id = str(target["id"])
		_present_attack_then_finish.call_deferred(attacker, target, attack_res)
	else:
		_finish_activation(attacker)
	return attack_res


func _resolve_attack_result(attacker, target, preview: Dictionary, part_name := "", seed := 0) -> Dictionary:
	attacker["has_attacked"] = true
	attacker["activation_complete"] = true
	turn_log.append("%s:attack" % attacker["id"])
	if str(attacker.get("team", "")) == "enemy":
		turn_log.append("%s:enemy_attack" % attacker["id"])
	var weapon_data := _weapon_data_for(attacker)
	var attack_res: Dictionary = {}
	if str(weapon_data.get("pattern", "single")) == "line_2":
		attack_res = _resolve_spear_attack(attacker, target, preview, seed)
	elif str(weapon_data.get("pattern", "single")) == "volley":
		attack_res = _resolve_rifle_attack(attacker, target, preview, seed)
	else:
		attack_res = _resolve_blockable_shot(attacker, target, preview, part_name, seed, int(weapon_data["damage"]), seed)

	if attack_res.get("intercepted", false):
		var shield_u = attack_res.get("shield_unit")
		var s_id: String = str(shield_u["id"]) if shield_u != null else "shield"
		turn_log.append("%s:shield_intercept:%s" % [s_id, target["id"]])

	if attack_res.has("hit"):
		if bool(attack_res["hit"]):
			turn_log.append("%s:hit:%s" % [attacker["id"], target["id"]])
		else:
			turn_log.append("%s:miss:%s" % [attacker["id"], target["id"]])
	elif attack_res.has("shots"):
		var any_hit := false
		for shot in attack_res["shots"]:
			if bool(shot.get("hit", false)):
				any_hit = true
				break
		if any_hit:
			turn_log.append("%s:hit:%s" % [attacker["id"], target["id"]])
		else:
			turn_log.append("%s:miss:%s" % [attacker["id"], target["id"]])
	elif attack_res.has("results"):
		for res in attack_res["results"]:
			var sub_t = res.get("target")
			if sub_t != null:
				if bool(res.get("hit", false)):
					turn_log.append("%s:hit:%s" % [attacker["id"], sub_t["id"]])
				else:
					turn_log.append("%s:miss:%s" % [attacker["id"], sub_t["id"]])

	if attack_res.has("orb_proc") and bool(attack_res["orb_proc"].get("triggered", false)):
		turn_log.append("%s:orb_proc:%s" % [attacker["id"], str(attack_res["orb_proc"].get("orb_id", "orb"))])
	elif attack_res.has("shots"):
		for shot in attack_res["shots"]:
			if shot.has("orb_proc") and bool(shot["orb_proc"].get("triggered", false)):
				turn_log.append("%s:orb_proc:%s" % [attacker["id"], str(shot["orb_proc"].get("orb_id", "orb"))])
				break

	if str(attacker.get("team", "")) == "player":
		last_attack_result = attack_res
	else:
		last_enemy_attack_result = attack_res

	if attack_res.has("results"):
		last_action_message = "%s strikes a line with %s" % [attacker["name"], attack_res["weapon"]]
	else:
		last_action_message = "%s hits %s %s" % [attacker["name"], target["name"], attack_res["part_name"]] if bool(attack_res["hit"]) else "%s misses %s" % [attacker["name"], target["name"]]
	if attack_res.has("orb_proc") and bool(attack_res["orb_proc"].get("triggered", false)):
		last_action_message += " + %s" % str(attack_res["orb_proc"]["status"])
	elif attack_res.has("shots"):
		for shot in attack_res["shots"]:
			if shot.has("orb_proc") and bool(shot["orb_proc"].get("triggered", false)):
				last_action_message += " + %s" % str(shot["orb_proc"]["status"])
				break
	return attack_res




func _present_attack_then_finish(attacker, target, result: Dictionary) -> void:
	await _present_attack_feedback(attacker, target, result)
	_finish_activation(attacker)
	_is_activating = false
	queue_redraw()
	if not _is_battle_over():
		_begin_next_activation()
	presented_attack_completed.emit()


func _present_attack_feedback(attacker, target, result: Dictionary) -> void:
	if not attack_presentation_enabled or auto_battle:
		return

	attack_presentation_active = true
	attack_feedback_attacker_id = str(attacker["id"]) if attacker != null else ""
	attack_feedback_target_id = str(target["id"]) if target != null else ""
	attack_feedback_queue = _build_attack_feedback_sequence(attacker, target, result)
	for line in attack_feedback_queue:
		last_action_message = line
		attack_feedback_log.append(line)
		queue_redraw()
		await get_tree().create_timer(attack_feedback_step_seconds).timeout
	attack_feedback_queue.clear()
	attack_feedback_attacker_id = ""
	attack_feedback_target_id = ""
	attack_presentation_active = false
	queue_redraw()


func _build_attack_feedback_sequence(attacker, target, result: Dictionary) -> Array[String]:
	var sequence: Array[String] = []
	var attacker_name := _unit_name_for_id(str(result.get("attacker_id", "")))
	if attacker != null:
		attacker_name = str(attacker["name"])
	var target_name := _unit_name_for_id(str(result.get("original_target_id", result.get("target_id", ""))))
	if target != null:
		target_name = str(target["name"])
	sequence.append("%s / %s -> %s" % [attacker_name, str(result.get("weapon", "Attack")), target_name])

	if result.has("shots"):
		for shot in result["shots"]:
			sequence.append(_attack_feedback_line(attacker, target, shot, "SHOT %d" % int(shot.get("shot_index", 0))))
			_append_attack_feedback_consequences(sequence, shot)
	elif result.has("results"):
		for lane_result in result["results"]:
			sequence.append(_attack_feedback_line(attacker, _unit_by_id(str(lane_result.get("target_id", ""))), lane_result, "TILE %d" % int(lane_result.get("tile_index", 0))))
			_append_attack_feedback_consequences(sequence, lane_result)
	else:
		sequence.append(_attack_feedback_line(attacker, target, result))
		_append_attack_feedback_consequences(sequence, result)

	return sequence


func _attack_feedback_line(attacker, target, result: Dictionary, label := "") -> String:
	var prefix := "%s / " % label if label != "" else ""
	if not bool(result.get("hit", false)):
		return "%sMISS" % prefix

	var part_name := str(result.get("part_name", "Part"))
	var damage := int(result.get("damage_applied", 0))
	if part_name == "Shield":
		var shield_name := _unit_name_for_id(str(result.get("target_id", "")))
		if bool(result.get("intercepted", false)):
			return "%sSHIELD INTERCEPT / %s Shield -%d" % [prefix, shield_name, damage]
		return "%sHIT / %s Shield -%d" % [prefix, shield_name, damage]
	return "%sHIT / %s -%d" % [prefix, part_name, damage]


func _append_attack_feedback_consequences(sequence: Array[String], result: Dictionary) -> void:
	if not bool(result.get("hit", false)):
		return

	var part_name := str(result.get("part_name", ""))
	if bool(result.get("destroyed_now", false)):
		if part_name == "Body":
			sequence.append("BODY DESTROYED / %s DEFEATED" % _unit_name_for_id(str(result.get("target_id", ""))))
		elif part_name == "Shield":
			sequence.append("SHIELD BROKEN / %s" % _unit_name_for_id(str(result.get("target_id", ""))))
		else:
			sequence.append("%s DESTROYED" % part_name.to_upper())

	var orb_proc: Dictionary = result.get("orb_proc", {})
	if bool(orb_proc.get("triggered", false)):
		sequence.append("ORB PROC / %s" % str(orb_proc.get("status", "")))


func _try_wait_active_unit() -> bool:
	if _input_locked() and not auto_battle and active_unit != null and str(active_unit.get("team", "")) == "player":
		return false
	if not _can_wait(active_unit):
		return false

	var acting_unit = active_unit
	acting_unit["activation_complete"] = true
	turn_log.append("%s:wait" % acting_unit["id"])
	last_action_message = "%s waits" % acting_unit["name"]
	_finish_activation(acting_unit)
	return true


func _valid_attack_targets(unit) -> Array:
	var targets := []
	if unit == null or not _is_unit_in_battle(unit) or bool(unit["weapon_disabled"]):
		return targets

	for other in units:
		if _is_attack_target_legal(unit, other):
			targets.append(other)
	return targets


func _initialize_part_state(unit) -> void:
	var source_parts: Dictionary = unit["parts"]
	var part_state := {}
	for part_name in PART_NAMES:
		var ratio := float(source_parts[part_name])
		part_state[part_name] = {
			"max_hp": PART_MAX_HP,
			"hp": int(round(ratio * float(PART_MAX_HP))),
			"destroyed": ratio <= 0.0,
			"orb": null,
			"orb_disabled": false,
		}
	unit["parts"] = part_state
	unit["hp"] = _overall_hp_ratio(unit)


func _damage_part(unit, part_name: String, amount: int) -> Dictionary:
	if unit == null or not unit["parts"].has(part_name):
		return {}

	var part: Dictionary = unit["parts"][part_name]
	var hp_before := int(part["hp"])
	var hp_after: int = max(0, hp_before - max(0, amount))
	part["hp"] = hp_after
	var destroyed_now := hp_before > 0 and hp_after == 0
	if hp_before > hp_after:
		turn_log.append("%s:damage:%s:%d" % [unit["id"], part_name, hp_before - hp_after])
	if destroyed_now:
		turn_log.append("%s:destroy:%s" % [unit["id"], part_name])
	if hp_after == 0:
		_apply_part_consequence(unit, part_name)

	unit["hp"] = _overall_hp_ratio(unit)
	return {
		"unit_id": str(unit["id"]),
		"part_name": part_name,
		"damage_requested": amount,
		"damage_applied": hp_before - hp_after,
		"hp_before": hp_before,
		"hp_after": hp_after,
		"destroyed": bool(part["destroyed"]),
		"destroyed_now": destroyed_now,
		"orb_disabled": bool(part["orb_disabled"]),
	}


func _damage_shield(unit, amount: int) -> Dictionary:
	if unit == null or int(unit.get("shield_max_hp", 0)) <= 0:
		return {}

	var hp_before := int(unit["shield_hp"])
	var hp_after: int = max(0, hp_before - max(0, amount))
	unit["shield_hp"] = hp_after
	if hp_before > hp_after:
		turn_log.append("%s:damage:Shield:%d" % [unit["id"], hp_before - hp_after])
	if hp_before > 0 and hp_after == 0:
		turn_log.append("%s:destroy:Shield" % unit["id"])
	if hp_after == 0:
		unit["shield_disabled"] = true
	return {
		"unit_id": str(unit["id"]),
		"part_name": "Shield",
		"damage_requested": amount,
		"damage_applied": hp_before - hp_after,
		"hp_before": hp_before,
		"hp_after": hp_after,
		"destroyed": hp_after == 0,
		"destroyed_now": hp_before > 0 and hp_after == 0,
		"orb_disabled": false,
	}



func _resolve_blockable_shot(attacker, target, preview: Dictionary, part_name := "", hit_seed := 0, damage := 0, part_seed := 0) -> Dictionary:
	var weapon_data := _weapon_data_for(attacker)
	var shield_unit = _intercepting_shield_for(attacker, target, weapon_data)
	if shield_unit != null:
		return _resolve_shield_damage(attacker, shield_unit, target, preview, hit_seed, damage, true)
	if _should_hit_shield(target, weapon_data, part_seed):
		return _resolve_shield_damage(attacker, target, target, preview, hit_seed, damage, false)
	return _resolve_weapon_attack(attacker, target, preview, part_name, hit_seed, damage, part_seed)


func _resolve_shield_damage(attacker, shield_unit, original_target, preview: Dictionary, hit_seed: int, damage: int, intercepted: bool) -> Dictionary:
	var hit_percent := int(preview["hit_percent"])
	var hit := _roll_hit(hit_percent, hit_seed)
	var damage_result := _shield_damage_result(shield_unit)
	var orb_proc := _empty_orb_proc()
	if hit:
		damage_result = _damage_shield(shield_unit, _terrain_adjusted_damage(shield_unit, _orb_adjusted_damage(attacker, damage)))
		orb_proc = _resolve_orb_proc(attacker, shield_unit, hit_seed)
	return {
		"attacker_id": str(attacker["id"]),
		"target_id": str(shield_unit["id"]),
		"original_target_id": str(original_target["id"]),
		"weapon": str(_weapon_data_for(attacker)["name"]),
		"part_name": "Shield",
		"damage_requested": int(damage_result["damage_requested"]),
		"damage_applied": int(damage_result["damage_applied"]),
		"hp_before": int(damage_result["hp_before"]),
		"hp_after": int(damage_result["hp_after"]),
		"destroyed": bool(damage_result["destroyed"]),
		"destroyed_now": bool(damage_result["destroyed_now"]),
		"hit": hit,
		"hit_percent": hit_percent,
		"intercepted": intercepted,
		"shield_hp_before": int(damage_result["hp_before"]),
		"shield_hp_after": int(damage_result["hp_after"]),
		"orb_proc": orb_proc,
	}


func _shield_damage_result(unit) -> Dictionary:
	return {
		"unit_id": str(unit["id"]),
		"part_name": "Shield",
		"damage_requested": 0,
		"damage_applied": 0,
		"hp_before": int(unit.get("shield_hp", 0)),
		"hp_after": int(unit.get("shield_hp", 0)),
		"destroyed": not _shield_is_active(unit),
		"destroyed_now": false,
		"orb_disabled": false,
	}


func _resolve_weapon_attack(attacker, target, preview: Dictionary, part_name := "", seed := 0, damage_override := -1, part_seed := -1) -> Dictionary:
	var weapon_data := _weapon_data_for(attacker)
	var resolved_part := part_name
	var resolved_part_seed: int = seed if part_seed < 0 else part_seed
	if resolved_part == "" or not bool(weapon_data["allow_manual_part"]):
		resolved_part = _roll_part_for_weapon(weapon_data, resolved_part_seed)
	if not PART_NAMES.has(resolved_part):
		resolved_part = _roll_part_for_weapon(weapon_data, resolved_part_seed)

	var hit_percent := int(preview["hit_percent"])
	var hit := _roll_hit(hit_percent, seed)
	var damage_result := _miss_damage_result(target, resolved_part)
	var orb_proc := _empty_orb_proc()
	if hit:
		var damage: int = damage_override if damage_override >= 0 else int(weapon_data["damage"])
		damage_result = _damage_part(target, resolved_part, _terrain_adjusted_damage(target, _orb_adjusted_damage(attacker, damage)))
		orb_proc = _resolve_orb_proc(attacker, target, seed)

	return {
		"attacker_id": str(attacker["id"]),
		"target_id": str(target["id"]),
		"weapon": str(weapon_data["name"]),
		"part_name": str(damage_result["part_name"]),
		"damage_requested": int(damage_result["damage_requested"]),
		"damage_applied": int(damage_result["damage_applied"]),
		"hp_before": int(damage_result["hp_before"]),
		"hp_after": int(damage_result["hp_after"]),
		"destroyed": bool(damage_result["destroyed"]),
		"destroyed_now": bool(damage_result["destroyed_now"]),
		"hit": hit,
		"hit_percent": hit_percent,
		"hit_seed": seed,
		"part_seed": resolved_part_seed,
		"orb_proc": orb_proc,
	}


func _resolve_spear_attack(attacker, target, preview: Dictionary, seed := 0) -> Dictionary:
	var weapon_data := _weapon_data_for(attacker)
	var direction := _spear_direction(attacker, target)
	var lane_targets := _line_attack_targets(attacker, direction, int(weapon_data["range_max"]))
	var results := []
	for lane_target in lane_targets:
		var tile_index: int = int(lane_target["tile_index"])
		var lane_preview := _attack_preview(attacker, lane_target["unit"])
		var damage: int = int(weapon_data["damage"]) if tile_index == 1 else int(weapon_data["secondary_damage"])
		var result := _resolve_weapon_attack(attacker, lane_target["unit"], lane_preview, "", seed + tile_index - 1, damage, seed + tile_index - 1)
		result["tile_index"] = tile_index
		result["grid"] = lane_target["grid"]
		results.append(result)

	var total_damage := 0
	var any_hit := false
	for result in results:
		total_damage += int(result["damage_applied"])
		any_hit = any_hit or bool(result["hit"])

	var primary_result := _miss_damage_result(target, "Body")
	if not results.is_empty():
		primary_result = results[0]

	return {
		"attacker_id": str(attacker["id"]),
		"target_id": str(target["id"]),
		"weapon": str(weapon_data["name"]),
		"part_name": str(primary_result["part_name"]),
		"damage_requested": int(weapon_data["damage"]),
		"damage_applied": total_damage,
		"hp_before": int(primary_result["hp_before"]),
		"hp_after": int(primary_result["hp_after"]),
		"destroyed": bool(primary_result["destroyed"]),
		"destroyed_now": bool(primary_result.get("destroyed_now", false)),
		"hit": any_hit,
		"hit_percent": int(preview["hit_percent"]),
		"direction": direction,
		"results": results,
	}


func _resolve_rifle_attack(attacker, target, preview: Dictionary, seed := 0) -> Dictionary:
	var weapon_data := _weapon_data_for(attacker)
	var shots := []
	var shot_count := int(weapon_data["shot_count"])
	for shot_index in range(shot_count):
		var hit_seed: int = seed + shot_index
		var part_seed: int = _volley_part_seed(seed, shot_index)
		var shot := _resolve_blockable_shot(attacker, target, preview, "", hit_seed, int(weapon_data["damage"]), part_seed)
		shot["shot_index"] = shot_index + 1
		shots.append(shot)

	var total_damage := 0
	var any_hit := false
	var primary_result := _miss_damage_result(target, "Body")
	for shot in shots:
		total_damage += int(shot["damage_applied"])
		any_hit = any_hit or bool(shot["hit"])
		if bool(shot["hit"]) and not bool(primary_result.get("hit_selected", false)):
			primary_result = shot
			primary_result["hit_selected"] = true

	return {
		"attacker_id": str(attacker["id"]),
		"target_id": str(target["id"]),
		"weapon": str(weapon_data["name"]),
		"part_name": str(primary_result["part_name"]),
		"damage_requested": int(weapon_data["damage"]) * shot_count,
		"damage_applied": total_damage,
		"hp_before": int(primary_result["hp_before"]),
		"hp_after": int(primary_result["hp_after"]),
		"destroyed": bool(primary_result["destroyed"]),
		"destroyed_now": bool(primary_result.get("destroyed_now", false)),
		"hit": any_hit,
		"hit_percent": int(preview["hit_percent"]),
		"shots": shots,
	}


func _volley_part_seed(seed: int, shot_index: int) -> int:
	return seed + shot_index * 29


func _miss_damage_result(target, part_name: String) -> Dictionary:
	var part: Dictionary = target["parts"][part_name]
	return {
		"unit_id": str(target["id"]),
		"part_name": part_name,
		"damage_requested": 0,
		"damage_applied": 0,
		"hp_before": int(part["hp"]),
		"hp_after": int(part["hp"]),
		"destroyed": bool(part["destroyed"]),
		"destroyed_now": false,
		"orb_disabled": bool(part["orb_disabled"]),
	}


func _apply_part_consequence(unit, part_name: String) -> void:
	var part: Dictionary = unit["parts"][part_name]
	part["destroyed"] = true
	part["orb_disabled"] = true

	if part_name == "Head":
		unit["accuracy_modifier"] = HEAD_DESTROYED_HIT_PENALTY
	elif part_name == "Legs":
		unit["current_move_range"] = 0
		unit["dodge"] = 0
	elif part_name == "Body":
		unit["defeated"] = true
		unit["in_battle"] = false
		turn_log.append("%s:defeated" % unit["id"])
		if active_unit != null and active_unit["id"] == unit["id"]:
			active_unit = null

	elif part_name == unit["weapon_mount_part"]:
		unit["weapon_disabled"] = true


func _install_orb(unit, part_name: String, orb_id: String) -> bool:
	if unit == null or not unit["parts"].has(part_name) or not ORB_DATA.has(orb_id):
		return false
	var part: Dictionary = unit["parts"][part_name]
	part["orb"] = orb_id
	part["orb_disabled"] = bool(part["destroyed"])
	return true


func _orb_data_for(orb_ref) -> Dictionary:
	if orb_ref is Dictionary:
		return orb_ref
	if ORB_DATA.has(str(orb_ref)):
		return ORB_DATA[str(orb_ref)]
	return {}


func _active_orbs(unit) -> Array:
	var active := []
	if unit == null:
		return active
	for part_name in PART_NAMES:
		var part: Dictionary = unit["parts"][part_name]
		if part["orb"] == null or bool(part["orb_disabled"]) or bool(part["destroyed"]):
			continue
		var orb := _orb_data_for(part["orb"])
		if orb.is_empty():
			continue
		var active_orb: Dictionary = orb.duplicate(true)
		active_orb["id"] = str(part["orb"])
		active_orb["host_part"] = part_name
		active.append(active_orb)
	return active


func _orb_effects(unit, effect_type := "") -> Array:
	var effects := []
	for orb in _active_orbs(unit):
		for effect in orb["effects"]:
			if effect_type == "" or str(effect.get("type", "")) == effect_type:
				var active_effect: Dictionary = effect.duplicate(true)
				active_effect["orb_id"] = str(orb["id"])
				active_effect["element"] = str(orb["element"])
				active_effect["rarity"] = str(orb["rarity"])
				effects.append(active_effect)
	return effects


func _orb_damage_modifier_percent(unit) -> int:
	var modifier := 0
	for effect in _orb_effects(unit, "damage_percent"):
		modifier += int(effect.get("percent", 0))
	return modifier


func _orb_hit_modifier(unit) -> int:
	var modifier := 0
	for effect in _orb_effects(unit, "hit_bonus"):
		modifier += int(effect.get("amount", 0))
	return modifier


func _orb_adjusted_damage(unit, damage: int) -> int:
	var modifier := _orb_damage_modifier_percent(unit)
	return int(round(float(max(0, damage)) * (100.0 + float(modifier)) / 100.0))


func _resolve_orb_proc(attacker, target, seed: int) -> Dictionary:
	var proc_effects := _orb_effects(attacker, "proc_status")
	for index in range(proc_effects.size()):
		var effect: Dictionary = proc_effects[index]
		var chance := int(effect.get("chance_percent", 0))
		if absi(seed + index * 37) % 100 < chance:
			var status := str(effect.get("status", ""))
			_apply_status(target, status)
			return {
				"triggered": true,
				"status": status,
				"orb_id": str(effect["orb_id"]),
				"seed": seed,
			}
	return _empty_orb_proc(seed)


func _empty_orb_proc(seed := 0) -> Dictionary:
	return {
		"triggered": false,
		"status": "",
		"orb_id": "",
		"seed": seed,
	}


func _apply_status(unit, status: String) -> bool:
	if unit == null or status == "":
		return false
	if not unit.has("statuses"):
		unit["statuses"] = []
	if not unit["statuses"].has(status):
		unit["statuses"].append(status)
		turn_log.append("%s:apply_status:%s" % [unit["id"], status])
	return true


func _has_status(unit, status: String) -> bool:
	return unit != null and unit.has("statuses") and unit["statuses"].has(status)


func _remove_status(unit, status: String) -> bool:
	if unit == null or not unit.has("statuses"):
		return false
	var index: int = unit["statuses"].find(status)
	if index >= 0:
		unit["statuses"].remove_at(index)
		return true
	return false


func _resolve_turn_start_statuses(unit) -> Dictionary:
	var result := {
		"burned": false,
		"burn_damage": 0,
		"defeated": false,
	}
	if unit == null or not _is_unit_in_battle(unit):
		return result

	if _has_status(unit, "Burn"):
		var dmg_result := _damage_part(unit, "Body", BURN_DAMAGE)
		var damage_applied: int = int(dmg_result.get("damage_applied", 0))
		result["burned"] = true
		result["burn_damage"] = damage_applied
		turn_log.append("%s:status:Burn:%d" % [unit["id"], damage_applied])
		last_action_message = "%s takes %d Burn damage to Body" % [unit["name"], damage_applied]
		_remove_status(unit, "Burn")
		if not _is_unit_in_battle(unit):
			result["defeated"] = true
	return result


func _apply_default_orb_loadouts() -> void:
	for unit in units:
		if str(unit.get("team", "")) == "player":
			_apply_default_orb_loadout(unit)


func _apply_default_orb_loadout(unit) -> void:
	if unit == null or not DEFAULT_ORB_LOADOUTS.has(str(unit.get("id", ""))):
		return
	var loadout: Dictionary = DEFAULT_ORB_LOADOUTS[str(unit["id"])]
	for part_name in loadout:
		_install_orb(unit, str(part_name), str(loadout[part_name]))


func _part_hp_ratio(unit, part_name: String) -> float:
	if unit == null or not unit["parts"].has(part_name):
		return 0.0
	var part: Dictionary = unit["parts"][part_name]
	return float(part["hp"]) / max(1.0, float(part["max_hp"]))


func _overall_hp_ratio(unit) -> float:
	if unit == null:
		return 0.0
	var hp_total := 0
	var max_total := 0
	for part_name in PART_NAMES:
		var part: Dictionary = unit["parts"][part_name]
		hp_total += int(part["hp"])
		max_total += int(part["max_hp"])
	return float(hp_total) / max(1.0, float(max_total))


func _is_unit_in_battle(unit) -> bool:
	return unit != null and bool(unit.get("in_battle", true)) and not bool(unit.get("defeated", false))


func _movement_range_for(unit) -> int:
	if unit == null:
		return 0
	return max(0, int(unit.get("current_move_range", MOVE_RANGE)))


func _weapon_mount_part(unit) -> String:
	if unit != null and str(unit["weapon"]) == "Shield":
		return "Left Arm"
	return "Right Arm"


func _weapon_data_for(unit) -> Dictionary:
	if unit != null and WEAPON_DATA.has(str(unit["weapon"])):
		return WEAPON_DATA[str(unit["weapon"])]
	return {
		"name": str(unit["weapon"]) if unit != null else "Unknown",
		"range_min": 1,
		"range_max": 4,
		"damage": PLACEHOLDER_ATTACK_DAMAGE,
		"hit_percent": PLACEHOLDER_HIT_PERCENT,
		"allow_manual_part": true,
		"pattern": "single",
		"blockable": false,
		"part_weights": {"Body": 100},
	}


func _roll_part_for_weapon(weapon_data: Dictionary, seed: int) -> String:
	var weights: Dictionary = weapon_data["part_weights"]
	var total_weight := 0
	for part_name in PART_NAMES:
		total_weight += int(weights.get(part_name, 0))
	if total_weight <= 0:
		return "Body"

	var roll: int = absi(seed) % total_weight
	var cursor := 0
	for part_name in PART_NAMES:
		cursor += int(weights.get(part_name, 0))
		if roll < cursor:
			return part_name
	return "Body"


func _roll_hit(hit_percent: int, seed: int) -> bool:
	return absi(seed) % 100 < clamp(hit_percent, 0, 100)


func _shield_is_active(unit) -> bool:
	return (
		unit != null
		and _is_unit_in_battle(unit)
		and int(unit.get("shield_max_hp", 0)) > 0
		and int(unit.get("shield_hp", 0)) > 0
		and not bool(unit.get("shield_disabled", false))
	)


func _should_hit_shield(target, weapon_data: Dictionary, seed: int) -> bool:
	if not _shield_is_active(target) or not bool(weapon_data.get("blockable", false)):
		return false
	var shield_data := _weapon_data_for(target)
	return absi(seed) % 100 < int(shield_data.get("shield_hit_weight", 0))


func _can_shield_intercept(shield_unit, attacker, target, weapon_data: Dictionary = {}) -> bool:
	if attacker == null or target == null or shield_unit == null:
		return false
	var attack_data := weapon_data if not weapon_data.is_empty() else _weapon_data_for(attacker)
	if not bool(attack_data.get("blockable", false)):
		return false
	if not _shield_is_active(shield_unit):
		return false
	if shield_unit["team"] != target["team"] or shield_unit["team"] == attacker["team"]:
		return false

	var shield_to_target: Vector2i = target["grid"] - shield_unit["grid"]
	if abs(shield_to_target.x) + abs(shield_to_target.y) != 1:
		return false

	var attacker_to_shield: Vector2i = shield_unit["grid"] - attacker["grid"]
	if attacker_to_shield == Vector2i.ZERO:
		return false
	if attacker_to_shield.x != 0 and attacker_to_shield.y != 0:
		return false

	var x_step: int = 0
	var y_step: int = 0
	if attacker_to_shield.x > 0:
		x_step = 1
	elif attacker_to_shield.x < 0:
		x_step = -1
	if attacker_to_shield.y > 0:
		y_step = 1
	elif attacker_to_shield.y < 0:
		y_step = -1
	return Vector2i(x_step, y_step) == shield_to_target


func _intercepting_shield_for(attacker, target, weapon_data: Dictionary = {}):
	for unit in units:
		if unit["id"] != target["id"] and _can_shield_intercept(unit, attacker, target, weapon_data):
			return unit
	return null


func _calculate_targetable_tiles(unit) -> Dictionary:
	var targetable := {}
	for target in _valid_attack_targets(unit):
		targetable[_grid_key(target["grid"])] = _attack_preview(unit, target)
	return targetable


func _refresh_attack_overlay() -> void:
	if active_unit == null:
		attack_overlay_tiles.clear()
		targetable_tiles.clear()
		return
	attack_overlay_tiles = _calculate_attack_overlay_tiles(active_unit)
	targetable_tiles = _calculate_targetable_tiles(active_unit)


func _calculate_attack_overlay_tiles(attacker, from_grid = null) -> Dictionary:
	var overlay := {}
	if attacker == null:
		return overlay
	for row in range(GRID_ROWS):
		for col in range(GRID_COLUMNS):
			var grid := Vector2i(col, row)
			overlay[_grid_key(grid)] = _attack_overlay_for_tile(attacker, grid, from_grid)
	return overlay


func _attack_overlay_for_tile(attacker, grid: Vector2i, from_grid = null) -> Dictionary:
	var origin: Vector2i = attacker["grid"] if from_grid == null else from_grid
	var weapon_data := _weapon_data_for(attacker)
	var pattern := str(weapon_data.get("pattern", "single"))
	var min_range := int(weapon_data.get("range_min", 1))
	var max_range := int(weapon_data.get("range_max", 1))
	var target_unit = _unit_at_grid(grid)
	if from_grid != null and target_unit == attacker:
		target_unit = null
	var delta: Vector2i = grid - origin
	var distance: int = absi(delta.x) + absi(delta.y)

	var status := "outside_range"
	var reason := "Out of range"
	var in_pattern := false

	if distance == 0:
		status = "outside_range"
		reason = "Self"
	elif pattern == "line_2":
		if (delta.x == 0 or delta.y == 0) and distance >= 1 and distance <= max_range:
			in_pattern = true
		else:
			status = "outside_range"
			reason = "Out of range"
	else:
		if distance < min_range:
			status = "minimum_range"
			reason = "Minimum range %d" % min_range
		elif distance <= max_range:
			in_pattern = true
		else:
			status = "outside_range"
			reason = "Out of range"

	if in_pattern:
		if not _has_line_of_sight(origin, grid):
			status = "los_blocked"
			reason = "LOS blocked"
		elif target_unit != null and _is_unit_in_battle(target_unit):
			if target_unit["team"] != attacker["team"]:
				if _is_attack_target_legal(attacker, target_unit, origin):
					status = "legal_target"
					reason = "Legal target"
				else:
					status = "invalid_target"
					reason = _attack_target_reason(attacker, target_unit, origin)
			else:
				status = "weapon_area"
				reason = "Ally"
		else:
			status = "weapon_area"
			reason = ""

	return {
		"grid": grid,
		"status": status,
		"legal": status == "legal_target",
		"reason": reason,
		"pattern": pattern,
		"target_unit": target_unit,
		"target_id": str(target_unit["id"]) if target_unit != null else "",
	}


func _attack_target_reason(attacker, target, origin = null) -> String:
	if attacker == null or target == null:
		return ""
	if bool(attacker.get("weapon_disabled", false)):
		return "Weapon disabled"
	if attacker.get("team") == target.get("team"):
		return "Ally"
	var from_pos: Vector2i = attacker["grid"] if origin == null else origin
	var weapon_data := _weapon_data_for(attacker)
	var distance: int = _grid_distance(from_pos, target["grid"])
	var min_range := int(weapon_data.get("range_min", 1))
	var max_range := int(weapon_data.get("range_max", 1))
	var pattern := str(weapon_data.get("pattern", "single"))

	if pattern == "line_2":
		if distance < 1 or distance > max_range or _spear_direction(attacker, target, from_pos) == Vector2i.ZERO:
			return "Out of range"
	else:
		if distance < min_range:
			return "Minimum range %d" % min_range
		if distance > max_range:
			return "Out of range"

	if not _has_line_of_sight(from_pos, target["grid"]):
		return "LOS blocked"
	if _is_attack_target_legal(attacker, target, from_pos):
		return "Legal target"
	return "Invalid target"



func _attack_preview(attacker, target) -> Dictionary:
	var distance := _grid_distance(attacker["grid"], target["grid"]) if attacker != null and target != null else 0
	var weapon_data := _weapon_data_for(attacker)
	var attack_min_range := int(weapon_data["range_min"])
	var attack_range := _attack_range_for(attacker)
	var legal := _is_attack_target_legal(attacker, target)
	var base_hit := int(weapon_data["hit_percent"]) if attacker != null else 0
	var accuracy_modifier := int(attacker.get("accuracy_modifier", 0)) if attacker != null else 0
	var height_modifier := _height_hit_modifier(attacker, target)
	var cover_dodge_modifier := -int(_terrain_at(target["grid"]).get("cover_dodge_bonus", 0)) if target != null and _has_cover(target["grid"]) else 0
	var orb_hit_modifier := _orb_hit_modifier(attacker)
	var hit_percent: int = int(clamp(base_hit + accuracy_modifier + height_modifier + cover_dodge_modifier + orb_hit_modifier, 0, 100))
	var base_damage := int(weapon_data.get("damage", 0))
	var orb_damage_modifier_percent := _orb_damage_modifier_percent(attacker)
	var preview := {
		"attacker_id": str(attacker["id"]) if attacker != null else "",
		"target_id": str(target["id"]) if target != null else "",
		"distance": distance,
		"min_range": attack_min_range,
		"range": attack_range,
		"hit_percent": hit_percent if legal else 0,
		"base_hit_percent": base_hit,
		"height_hit_modifier": height_modifier,
		"cover_dodge_modifier": cover_dodge_modifier,
		"orb_hit_modifier": orb_hit_modifier,
		"orb_damage_modifier_percent": orb_damage_modifier_percent,
		"damage": _terrain_adjusted_damage(target, _orb_adjusted_damage(attacker, base_damage)) if legal else 0,
		"base_damage": base_damage,
		"legal": legal,
		"weapon_pattern": str(weapon_data.get("pattern", "single")),
	}
	if str(weapon_data.get("pattern", "single")) == "line_2":
		var direction := _spear_direction(attacker, target)
		preview["direction"] = direction
		var affected_tiles := []
		var affected_target_ids := []
		if direction != Vector2i.ZERO:
			for lane_target in _line_attack_targets(attacker, direction, attack_range):
				affected_tiles.append(lane_target["grid"])
				affected_target_ids.append(str(lane_target["unit"]["id"]))
		preview["affected_tiles"] = affected_tiles
		preview["affected_target_ids"] = affected_target_ids
	return preview


func _is_attack_target_legal(attacker, target, origin = null) -> bool:
	if attacker == null or target == null:
		return false
	if not _is_unit_in_battle(attacker) or not _is_unit_in_battle(target):
		return false
	if bool(attacker["weapon_disabled"]):
		return false
	if attacker["team"] == target["team"]:
		return false
	var from_pos: Vector2i = attacker["grid"] if origin == null else origin
	var weapon_data := _weapon_data_for(attacker)
	if str(weapon_data.get("pattern", "single")) == "line_2":
		return _spear_direction(attacker, target, from_pos) != Vector2i.ZERO
	var distance: int = _grid_distance(from_pos, target["grid"])
	if distance < int(weapon_data["range_min"]) or distance > int(weapon_data["range_max"]):
		return false
	return _has_line_of_sight(from_pos, target["grid"])


func _attack_range_for(unit) -> int:
	if unit == null:
		return 0
	return int(_weapon_data_for(unit)["range_max"])


func _spear_direction(attacker, target, origin = null) -> Vector2i:
	if attacker == null or target == null:
		return Vector2i.ZERO

	var from_pos: Vector2i = attacker["grid"] if origin == null else origin
	var delta: Vector2i = target["grid"] - from_pos
	var distance: int = abs(delta.x) + abs(delta.y)
	if distance < 1 or distance > int(_weapon_data_for(attacker)["range_max"]):
		return Vector2i.ZERO
	if delta.x != 0 and delta.y != 0:
		return Vector2i.ZERO

	var x_step: int = 0
	var y_step: int = 0
	if delta.x > 0:
		x_step = 1
	elif delta.x < 0:
		x_step = -1
	if delta.y > 0:
		y_step = 1
	elif delta.y < 0:
		y_step = -1
	return Vector2i(x_step, y_step)


func _line_attack_targets(attacker, direction: Vector2i, max_tiles: int) -> Array:
	var affected := []
	if attacker == null or direction == Vector2i.ZERO:
		return affected

	for tile_index in range(1, max_tiles + 1):
		var grid: Vector2i = attacker["grid"] + direction * tile_index
		if not _is_in_bounds(grid):
			continue
		var unit = _unit_at_grid(grid)
		if unit != null and unit["team"] != attacker["team"]:
			affected.append({"unit": unit, "tile_index": tile_index, "grid": grid})
	return affected


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _is_active_unit(unit) -> bool:
	return active_unit != null and unit != null and active_unit["id"] == unit["id"]


func _calculate_reachable_tiles(unit) -> Dictionary:
	if not _is_unit_in_battle(unit):
		return {}

	var visited := {}
	var frontier := [{"grid": unit["grid"], "distance": 0}]
	visited[_grid_key(unit["grid"])] = 0
	var move_range := _movement_range_for(unit)

	while not frontier.is_empty():
		var current = frontier.pop_front()
		if current["distance"] >= move_range:
			continue

		for direction in DIRECTIONS:
			var next_grid = current["grid"] + direction
			if not _is_in_bounds(next_grid):
				continue
			if not _can_traverse_step(current["grid"], next_grid):
				continue
			if _occupied_by_opponent(next_grid, str(unit["team"])):
				continue

			var next_distance = current["distance"] + 1
			var key := _grid_key(next_grid)
			if not visited.has(key) or next_distance < visited[key]:
				visited[key] = next_distance
				frontier.append({"grid": next_grid, "distance": next_distance})

	var reachable := {}
	for key in visited.keys():
		var grid := _grid_from_key(key)
		# allies may be traversed, but no unit may end movement on an occupied tile.
		if grid != unit["grid"] and not _occupied_by_any_unit(grid):
			reachable[key] = visited[key]
	return reachable


func _occupied_by_opponent(grid: Vector2i, team: String) -> bool:
	for unit in units:
		if _is_unit_in_battle(unit) and unit["grid"] == grid and unit["team"] != team:
			return true
	return false


func _occupied_by_any_unit(grid: Vector2i) -> bool:
	for unit in units:
		if _is_unit_in_battle(unit) and unit["grid"] == grid:
			return true
	return false


func _unit_at_grid(grid: Vector2i):
	for unit in units:
		if _is_unit_in_battle(unit) and unit["grid"] == grid:
			return unit
	return null


func _unit_at_position(position: Vector2):
	for index in range(units.size() - 1, -1, -1):
		var unit = units[index]
		if not _is_unit_in_battle(unit):
			continue
		var center := _tile_center(unit["grid"])
		if position.distance_to(center) <= _unit_radius() * 1.35:
			return unit
	return null


func _grid_at_position(position: Vector2):
	for row in range(GRID_ROWS - 1, -1, -1):
		for column in range(GRID_COLUMNS - 1, -1, -1):
			var grid := Vector2i(column, row)
			if _tile_rect(grid).has_point(position):
				return grid
	return null


func _is_in_bounds(grid) -> bool:
	return grid.x >= 0 and grid.x < GRID_COLUMNS and grid.y >= 0 and grid.y < GRID_ROWS


func _create_terrain() -> void:
	terrain_tiles.clear()
	var mission_data: Dictionary = MISSIONS_DATA.get(current_mission, {})
	var covers: Array = mission_data.get("cover_tiles", [Vector2i(3, 2), Vector2i(5, 4), Vector2i(6, 2), Vector2i(8, 1)])
	for tile in covers:
		_set_tile_terrain(tile, {"cover": true})


func _set_tile_terrain(grid: Vector2i, data: Dictionary) -> void:
	if not _is_in_bounds(grid):
		return
	var key := _grid_key(grid)
	var tile: Dictionary = terrain_tiles.get(key, {}).duplicate(true)
	for property in data.keys():
		tile[property] = data[property]
	terrain_tiles[key] = tile


func _terrain_at(grid) -> Dictionary:
	var terrain := {
		"height": _default_height_at(grid),
		"cover": false,
		"cover_dodge_bonus": COVER_DODGE_BONUS,
		"cover_damage_reduction_percent": COVER_DAMAGE_REDUCTION_PERCENT,
		"blocks_los": false,
	}
	if grid != null and _is_in_bounds(grid):
		var override: Dictionary = terrain_tiles.get(_grid_key(grid), {})
		for property in override.keys():
			terrain[property] = override[property]
	terrain["height"] = int(clamp(int(terrain["height"]), 0, 4))
	return terrain


func _default_height_at(grid) -> int:
	if grid == null:
		return 0
	if current_mission == "ancient_ruins":
		if grid.x <= 3:
			return 0
		elif grid.x <= 6:
			return 1
		else:
			return 2
	elif current_mission == "crystal_quarry":
		if grid.x >= 3 and grid.x <= 7:
			return 0
		return 1
	elif current_mission == "ascending_ridge":
		if grid.x <= 1:
			return 0
		elif grid.x <= 3:
			return 1
		elif grid.x <= 5:
			return 2
		elif grid.x <= 7:
			return 3
		else:
			return 4
	return int(clamp(floor(float(grid.x) / 2.0), 0.0, 4.0))





func _height_at(grid) -> int:
	return int(_terrain_at(grid)["height"])


func _height_hit_modifier(attacker, target) -> int:
	if attacker == null or target == null:
		return 0
	var height_delta: int = _height_at(attacker["grid"]) - _height_at(target["grid"])
	return int(clamp(height_delta * HEIGHT_HIT_PER_LEVEL, -HEIGHT_HIT_CAP, HEIGHT_HIT_CAP))


func _has_cover(grid) -> bool:
	return bool(_terrain_at(grid).get("cover", false))


func _terrain_adjusted_damage(target, damage: int) -> int:
	var adjusted: int = max(0, damage)
	if target == null or not _has_cover(target["grid"]):
		return adjusted
	var reduction := int(_terrain_at(target["grid"]).get("cover_damage_reduction_percent", 0))
	return int(round(float(adjusted) * (100.0 - float(reduction)) / 100.0))


func _can_traverse_step(from_grid: Vector2i, to_grid: Vector2i) -> bool:
	return abs(_height_at(to_grid) - _height_at(from_grid)) <= 1


func _blocks_los(grid) -> bool:
	return bool(_terrain_at(grid).get("blocks_los", false))


func _has_line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	for grid in _line_grids_between(a, b):
		if _blocks_los(grid):
			return false
	return true


func _line_grids_between(a: Vector2i, b: Vector2i) -> Array:
	var between := []
	var steps: int = max(abs(b.x - a.x), abs(b.y - a.y))
	if steps <= 1:
		return between

	for step in range(1, steps):
		var t := float(step) / float(steps)
		var grid := Vector2i(
			int(round(lerp(float(a.x), float(b.x), t))),
			int(round(lerp(float(a.y), float(b.y), t)))
		)
		if grid != a and grid != b and (between.is_empty() or between[between.size() - 1] != grid):
			between.append(grid)
	return between


func _event_press_position(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return event.position
	if event is InputEventScreenTouch and event.pressed:
		return event.position
	return null


func _grid_key(grid) -> String:
	return "%s,%s" % [grid.x, grid.y]


func _grid_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func _scale() -> Vector2:
	return size / DESIGN_SIZE


func _p(x: float, y: float) -> Vector2:
	var s := _scale()
	return Vector2(x * s.x, y * s.y)


func _r(x: float, y: float, width: float, height: float) -> Rect2:
	var s := _scale()
	return Rect2(Vector2(x * s.x, y * s.y), Vector2(width * s.x, height * s.y))


func _tile_rect(grid) -> Rect2:
	var s := _scale()
	var elevation_offset := float(_height_at(grid)) * ELEVATION_STEP * s.y
	var position := Vector2(
		(GRID_ORIGIN.x + float(grid.x) * TILE_SPACING.x) * s.x,
		(GRID_ORIGIN.y + float(grid.y) * TILE_SPACING.y) * s.y - elevation_offset
	)
	return Rect2(position, Vector2(TILE_SIZE.x * s.x, TILE_SIZE.y * s.y))


func _tile_center(grid) -> Vector2:
	var rect := _tile_rect(grid)
	return rect.position + rect.size * 0.5


func _unit_radius() -> float:
	var s := _scale()
	return min(18.0 * s.x, 18.0 * s.y)


func _font() -> Font:
	return get_theme_default_font()


func _font_size(base_size: int) -> int:
	return max(8, int(round(float(base_size) * min(_scale().x, _scale().y))))


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.09, 0.11), true)
	draw_rect(_r(11, 11, 1289, 581), Color(0.20, 0.27, 0.30), false, 2.0)


func _draw_battlefield() -> void:
	draw_rect(_r(190, 104, 930, 405), Color(0.08, 0.13, 0.15), true)
	draw_rect(_r(190, 104, 930, 405), Color(0.20, 0.27, 0.30), false, 2.0)

	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			_draw_tile(Vector2i(column, row))

	for key in terrain_tiles.keys():
		var terrain_grid := _grid_from_key(key)
		var rect := _tile_rect(terrain_grid)
		if _blocks_los(terrain_grid):
			draw_rect(rect.grow(-12.0 * min(_scale().x, _scale().y)), Color(0.32, 0.30, 0.31), true)
			draw_rect(rect.grow(-12.0 * min(_scale().x, _scale().y)), Color(0.55, 0.51, 0.48), false, 1.5)
		if _has_cover(terrain_grid):
			_draw_cover(terrain_grid)

	for unit in units:
		if _is_unit_in_battle(unit):
			_draw_unit(unit)
	_draw_movement_preview()
	_draw_attack_feedback_markers()


func _draw_tile(grid: Vector2i) -> void:
	var rect := _tile_rect(grid)
	var height := _height_at(grid)
	var side_depth := float(height) * ELEVATION_STEP * _scale().y
	if side_depth > 0.0:
		var side_rect := Rect2(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.size.x, side_depth))
		draw_rect(side_rect, Color(0.09, 0.15, 0.17), true)
		draw_rect(side_rect, Color(0.18, 0.25, 0.27), false, 1.0)

	var top_color := Color(0.15 + height * 0.035, 0.22 + height * 0.035, 0.25 + height * 0.025)
	draw_rect(rect, top_color, true)
	draw_rect(rect, Color(0.34, 0.41, 0.44), false, 1.0)

	if reachable_tiles.has(_grid_key(grid)):
		draw_rect(rect.grow(-3.0 * min(_scale().x, _scale().y)), Color(0.22, 0.43, 0.48, 0.82), true)
		draw_rect(rect.grow(-3.0 * min(_scale().x, _scale().y)), Color(0.53, 0.71, 0.75), false, 2.0)

	if (turn_state == TurnState.SELECTING_ATTACK or turn_state == TurnState.MOVE_PREVIEW) and attack_overlay_tiles.has(_grid_key(grid)):
		var entry: Dictionary = attack_overlay_tiles[_grid_key(grid)]
		var status := str(entry.get("status", ""))
		var inset: float = 4.0 * min(_scale().x, _scale().y)
		if status == "legal_target":
			draw_rect(rect.grow(-inset), Color(0.68, 0.18, 0.18, 0.65), true)
			draw_rect(rect.grow(-inset), Color(0.96, 0.45, 0.42), false, 2.5)
		elif status == "weapon_area":
			draw_rect(rect.grow(-inset), Color(0.55, 0.25, 0.25, 0.28), true)
			draw_rect(rect.grow(-inset), Color(0.78, 0.40, 0.40, 0.55), false, 1.0)
		elif status == "minimum_range":
			draw_rect(rect.grow(-inset), Color(0.35, 0.28, 0.20, 0.35), true)
			draw_rect(rect.grow(-inset), Color(0.60, 0.45, 0.25, 0.50), false, 1.0)
		elif status == "los_blocked":
			draw_rect(rect.grow(-inset), Color(0.28, 0.20, 0.32, 0.40), true)
			draw_rect(rect.grow(-inset), Color(0.50, 0.35, 0.55, 0.55), false, 1.0)
	elif targetable_tiles.has(_grid_key(grid)):
		draw_rect(rect.grow(-5.0 * min(_scale().x, _scale().y)), Color(0.49, 0.22, 0.22, 0.62), true)
		draw_rect(rect.grow(-5.0 * min(_scale().x, _scale().y)), Color(0.85, 0.50, 0.48), false, 2.0)



func _draw_cover(grid: Vector2i) -> void:
	var rect := _tile_rect(grid)
	var cover_rect := Rect2(
		rect.position + Vector2(rect.size.x * 0.30, rect.size.y * 0.18),
		Vector2(rect.size.x * 0.42, rect.size.y * 0.54)
	)
	draw_rect(cover_rect, Color(0.49, 0.55, 0.47), true)
	draw_rect(cover_rect, Color(0.69, 0.73, 0.66), false, 1.0)


func _draw_unit(unit) -> void:
	var center := _tile_center(unit["grid"])
	var radius := _unit_radius()

	if _is_active_unit(unit):
		draw_arc(center, radius * 1.78, 0.0, TAU, 40, Color(0.96, 0.86, 0.48), 3.0, true)

	if targetable_tiles.has(_grid_key(unit["grid"])):
		draw_arc(center, radius * 1.70, 0.0, TAU, 40, Color(0.85, 0.50, 0.48), 2.5, true)

	if selected_unit != null and selected_unit["id"] == unit["id"]:
		draw_arc(center, radius * 1.48, 0.0, TAU, 40, Color(0.53, 0.71, 0.75), 2.5, true)

	var fill_color: Color = unit["color"]
	if unit["team"] == "enemy":
		fill_color = Color(0.73, 0.34, 0.34)

	draw_circle(center, radius, fill_color)
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.90, 0.94, 0.95), 2.0, true)
	_draw_centered_text(Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), str(unit["letter"]), 12, Color.WHITE)


func _draw_attack_feedback_markers() -> void:
	if not attack_presentation_active:
		return

	var attacker = _unit_by_id(attack_feedback_attacker_id)
	var target = _unit_by_id(attack_feedback_target_id)
	var radius := _unit_radius()
	if attacker != null:
		draw_arc(_tile_center(attacker["grid"]), radius * 2.10, 0.0, TAU, 40, Color(0.96, 0.86, 0.48), 3.0, true)
	if target != null:
		draw_arc(_tile_center(target["grid"]), radius * 2.25, 0.0, TAU, 40, Color(0.92, 0.32, 0.28), 3.0, true)


func _draw_movement_preview() -> void:
	if turn_state != TurnState.MOVE_PREVIEW or preview_move_destination == null or active_unit == null:
		return

	if preview_move_path.size() > 1:
		var points: PackedVector2Array = []
		for step in preview_move_path:
			points.append(_tile_center(step))
		draw_polyline(points, Color(0.96, 0.86, 0.48, 0.90), 3.0, true)
		for i in range(1, preview_move_path.size() - 1):
			var pt := _tile_center(preview_move_path[i])
			draw_circle(pt, 4.0 * min(_scale().x, _scale().y), Color(0.96, 0.86, 0.48, 0.85))

	var dest_rect := _tile_rect(preview_move_destination)
	draw_rect(dest_rect.grow(-2.0 * min(_scale().x, _scale().y)), Color(0.96, 0.86, 0.48), false, 2.5)

	var ghost_center := _tile_center(preview_move_destination)
	var radius := _unit_radius()
	var unit_color: Color = active_unit["color"]
	var ghost_color := Color(unit_color.r, unit_color.g, unit_color.b, 0.50)
	draw_circle(ghost_center, radius, ghost_color)
	draw_arc(ghost_center, radius, 0.0, TAU, 40, Color(0.90, 0.94, 0.95, 0.75), 2.0, true)
	_draw_centered_text(
		Rect2(ghost_center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)),
		str(active_unit["letter"]),
		12,
		Color(1.0, 1.0, 1.0, 0.85)
	)


func _draw_selected_unit_panel() -> void:
	var rect := _r(30, 30, 235, 92)
	_draw_panel(rect)
	if selected_unit == null:
		return

	var portrait_center := _p(74, 76)
	var portrait_radius: float = min(28.0 * _scale().x, 28.0 * _scale().y)
	draw_circle(portrait_center, portrait_radius, Color(0.18, 0.25, 0.29))
	draw_arc(portrait_center, portrait_radius, 0.0, TAU, 40, Color(0.42, 0.50, 0.54), 2.0, true)
	_draw_centered_text(Rect2(portrait_center - Vector2(portrait_radius, portrait_radius), Vector2(portrait_radius * 2.0, portrait_radius * 2.0)), str(selected_unit["letter"]), 16, Color(0.86, 0.90, 0.92))

	draw_string(_font(), _p(115, 58), str(selected_unit["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(18), Color(0.95, 0.97, 0.97))
	draw_string(_font(), _p(115, 79), "%s / %s" % [selected_unit["mech"], selected_unit["weapon"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.62, 0.69, 0.73))
	if _is_active_unit(selected_unit):
		draw_string(_font(), _p(222, 55), "ACTIVE", HORIZONTAL_ALIGNMENT_RIGHT, 25.0 * _scale().x, _font_size(9), Color(0.96, 0.86, 0.48))
	_draw_bar(_r(115, 92, 122, 8), _overall_hp_ratio(selected_unit), Color(0.46, 0.65, 0.56))


func _draw_initiative_strip() -> void:
	_draw_panel(_r(476, 27, 360, 58))
	draw_string(_font(), _p(494, 48), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.56, 0.63, 0.67))
	var count: int = min(initiative_timeline.size(), 6)
	for index in range(count):
		var unit = _unit_by_id(initiative_timeline[index])
		if unit == null:
			continue
		var center := _p(532 + index * 48, 58)
		var radius: float = min((16.0 if index == 0 else 14.0) * _scale().x, (16.0 if index == 0 else 14.0) * _scale().y)
		draw_circle(center, radius, unit["color"])
		if index == 0:
			draw_arc(center, radius * 1.30, 0.0, TAU, 40, Color(0.96, 0.86, 0.48), 2.0, true)
		_draw_centered_text(Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), str(unit["letter"]), 11, Color.WHITE)


func _draw_mission_panel() -> void:
	_draw_panel(_r(1030, 30, 248, 92))
	var mission_data: Dictionary = MISSIONS_DATA.get(current_mission, {})
	var objective_label := str(mission_data.get("objective_label", "Defeat Commander"))
	var detail := last_action_message
	if not target_preview.is_empty():
		var state := "LEGAL" if bool(target_preview["legal"]) else "ILLEGAL"
		var h_mod := int(target_preview.get("height_hit_modifier", 0))
		var pattern := str(target_preview.get("weapon_pattern", "single"))
		var mod_str := ""
		if h_mod != 0:
			mod_str = " (H%+d%%)" % h_mod
		detail = "Hit %d%%%s · %s · %s" % [int(target_preview["hit_percent"]), mod_str, pattern.to_upper(), state]

	elif _is_battle_over():
		if _battle_winner() == "player":
			var loot: Dictionary = _roll_mission_loot(current_mission, reward_seed)
			if not loot.is_empty():
				detail = "VICTORY · +%d Cr · %s" % [int(loot.get("credits", 0)), str(loot.get("orb_drop", ""))]
			else:
				detail = "VICTORY"
		else:
			detail = "DEFEAT"
	draw_string(_font(), _p(1052, 55), "TURN %02d" % turn_number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.56, 0.63, 0.67))
	draw_string(_font(), _p(1052, 80), objective_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(15), Color(0.95, 0.97, 0.97))
	draw_string(_font(), _p(1052, 101), detail, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(11), Color(0.62, 0.69, 0.73))




func _part_hp_text(unit, part_name: String) -> String:
	if unit == null or not unit.get("parts", {}).has(part_name):
		return "0 / 0"
	var part: Dictionary = unit["parts"][part_name]
	var hp := int(part.get("hp", 0))
	var max_hp := int(part.get("max_hp", PART_MAX_HP))
	if bool(part.get("destroyed", false)) or hp <= 0:
		return "0 / %d DESTROYED" % max_hp
	return "%d / %d" % [hp, max_hp]


func _shield_hp_text(unit) -> String:
	if unit == null or int(unit.get("shield_max_hp", 0)) <= 0:
		return ""
	var hp := int(unit.get("shield_hp", 0))
	var max_hp := int(unit.get("shield_max_hp", 0))
	if hp <= 0 or not _shield_is_active(unit):
		return "0 / %d BROKEN" % max_hp
	return "%d / %d" % [hp, max_hp]


func _draw_part_status_panel() -> void:
	if selected_unit == null:
		return

	var has_shield: bool = int(selected_unit.get("shield_max_hp", 0)) > 0
	var panel_h: float = 142.0 if has_shield else 126.0
	_draw_panel(_r(30, 396, 235, panel_h))
	draw_string(_font(), _p(48, 416), "PART STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.56, 0.63, 0.67))
	var y := 436.0
	for index in range(PART_NAMES.size()):
		var part_name: String = PART_NAMES[index]
		var part: Dictionary = selected_unit["parts"][part_name]
		var p_hp := int(part.get("hp", 0))
		var destroyed: bool = bool(part.get("destroyed", false)) or p_hp <= 0
		var label_color := Color(0.78, 0.82, 0.84) if not destroyed else Color(0.88, 0.48, 0.46)
		draw_string(_font(), _p(48, y), _short_part_name(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), label_color)
		if part.get("orb") != null:
			var orb_data := _orb_data_for(part["orb"])
			var elem := str(orb_data.get("element", ""))
			var orb_col := Color(0.95, 0.50, 0.25) if elem == "Fire" else (Color(0.35, 0.65, 0.95) if elem == "Water" else (Color(0.95, 0.85, 0.25) if elem == "Lightning" else Color(0.65, 0.75, 0.45)))
			if destroyed or bool(part.get("orb_disabled", false)):
				orb_col = Color(0.40, 0.40, 0.40)
			draw_circle(_p(40, y - 3.0), 2.5 * min(_scale().x, _scale().y), orb_col)
		_draw_bar(_r(96, y - 8.0, 68, 7), _part_hp_ratio(selected_unit, part_name), Color(0.46, 0.65, 0.56) if not destroyed else Color(0.76, 0.32, 0.31))
		var hp_str := _part_hp_text(selected_unit, part_name)
		draw_string(_font(), _p(170, y), hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), label_color)
		y += 15.0

	if has_shield:
		var s_hp := int(selected_unit.get("shield_hp", 0))
		var s_max := int(selected_unit.get("shield_max_hp", 0))
		var s_active := _shield_is_active(selected_unit)
		var s_col := Color(0.53, 0.71, 0.75) if s_active else Color(0.76, 0.32, 0.31)
		draw_string(_font(), _p(48, y), "Shield", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), s_col)
		_draw_bar(_r(96, y - 8.0, 68, 7), float(s_hp) / float(s_max) if s_max > 0 else 0.0, Color(0.40, 0.60, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		var s_str := _shield_hp_text(selected_unit)
		draw_string(_font(), _p(170, y), s_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), s_col)


func _inspect_target(target) -> Dictionary:
	if target == null:
		return {}
	selected_unit = target
	if active_unit != null:
		return _preview_attack_target(target)
	queue_redraw()
	return {}


func _inspect_unit(unit) -> void:
	if unit == null:
		return
	selected_unit = unit
	if active_unit != null and turn_state == TurnState.SELECTING_ATTACK:
		_preview_attack_target(unit)
	else:
		queue_redraw()


func _target_inspection_data(unit) -> Dictionary:
	if unit == null:
		return {}

	var terrain := _terrain_at(unit["grid"])
	var height := _height_at(unit["grid"])
	var has_cov := _has_cover(unit["grid"])
	var terrain_desc := "H%d" % height
	if has_cov:
		terrain_desc += " · Cover"

	var consequences: Array[String] = []
	if bool(unit.get("weapon_disabled", false)):
		consequences.append("Weapon disabled (%s)" % str(unit.get("weapon_mount_part", "Arm")))
	if int(unit.get("accuracy_modifier", 0)) < 0:
		consequences.append("Accuracy reduced (%+d%%)" % int(unit["accuracy_modifier"]))
	if int(unit.get("current_move_range", 0)) == 0 and bool(unit.get("parts", {}).get("Legs", {}).get("destroyed", false)):
		consequences.append("Legs destroyed: mobility lost")

	var part_details := {}
	for part_name in PART_NAMES:
		var part: Dictionary = unit["parts"].get(part_name, {})
		part_details[part_name] = {
			"hp": int(part.get("hp", 0)),
			"max_hp": int(part.get("max_hp", PART_MAX_HP)),
			"destroyed": bool(part.get("destroyed", false)),
		}

	var orbs_info: Array[String] = []
	for orb in _active_orbs(unit):
		orbs_info.append("%s (%s)" % [str(orb.get("name", orb.get("id", ""))), str(orb.get("element", ""))])

	var statuses_info: Array[String] = []
	for st in unit.get("statuses", []):
		if st is Dictionary:
			statuses_info.append(str(st.get("name", st.get("id", ""))))
		else:
			statuses_info.append(str(st))

	var data := {
		"id": str(unit.get("id", "")),
		"name": str(unit.get("name", "")),
		"mech": str(unit.get("mech", "")),
		"weapon": str(unit.get("weapon", "")),
		"team": str(unit.get("team", "")),
		"grid": unit["grid"],
		"height": height,
		"has_cover": has_cov,
		"terrain_desc": terrain_desc,
		"consequences": consequences,
		"parts": part_details,
		"shield_hp": int(unit.get("shield_hp", 0)),
		"shield_max_hp": int(unit.get("shield_max_hp", 0)),
		"has_shield": int(unit.get("shield_max_hp", 0)) > 0,
		"shield_active": _shield_is_active(unit),
		"statuses": statuses_info,
		"orbs": orbs_info,
	}

	if active_unit != null and str(active_unit.get("id", "")) != str(unit.get("id", "")):
		var preview: Dictionary = _attack_preview(active_unit, unit)
		data["attack_preview"] = preview
		var interceptor = _intercepting_shield_for(active_unit, unit, _weapon_data_for(active_unit))
		data["shield_interceptor"] = interceptor
		if interceptor != null:
			data["shield_warning"] = "Protected by %s's Shield" % str(interceptor.get("name", "Ally"))
		else:
			data["shield_warning"] = ""
	else:
		data["attack_preview"] = {}
		data["shield_interceptor"] = null
		data["shield_warning"] = ""

	return data


func _draw_enemy_inspection_panel() -> void:
	if selected_unit == null or selected_unit == active_unit:
		return
	if selected_unit["team"] != "enemy" and turn_state != TurnState.SELECTING_ATTACK:
		return

	var panel_rect := _r(960, 126, 310, 385)
	_draw_panel(panel_rect)

	var data: Dictionary = _target_inspection_data(selected_unit)
	var is_enemy: bool = str(selected_unit.get("team", "")) == "enemy"
	var header_title := "TARGET INSPECTION" if turn_state == TurnState.SELECTING_ATTACK else ("ENEMY INTEL" if is_enemy else "ALLY INTEL")
	var header_color := Color(0.85, 0.65, 0.40) if turn_state == TurnState.SELECTING_ATTACK else Color(0.56, 0.63, 0.67)
	draw_string(_font(), _p(976, 148), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), header_color)

	draw_string(_font(), _p(976, 170), str(selected_unit["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(16), Color(0.95, 0.97, 0.97))
	draw_string(_font(), _p(976, 188), "%s · %s" % [selected_unit["mech"], selected_unit["weapon"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(11), Color(0.62, 0.69, 0.73))
	draw_string(_font(), _p(976, 204), str(data.get("terrain_desc", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.70, 0.75, 0.77))

	var y := 220.0
	for part_name in PART_NAMES:
		var p_info: Dictionary = data["parts"][part_name]
		var p_hp: int = int(p_info["hp"])
		var p_max: int = int(p_info["max_hp"])
		var destroyed: bool = bool(p_info["destroyed"])
		var label_col := Color(0.78, 0.82, 0.84) if not destroyed else Color(0.88, 0.48, 0.46)
		draw_string(_font(), _p(976, y), _short_part_name(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), label_col)
		_draw_bar(_r(1030, y - 8.0, 130, 7), float(p_hp) / float(p_max) if p_max > 0 else 0.0, Color(0.46, 0.65, 0.56) if not destroyed else Color(0.76, 0.32, 0.31))
		var hp_text := _part_hp_text(selected_unit, part_name)
		draw_string(_font(), _p(1170, y), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), label_col)
		y += 15.0

	if bool(data.get("has_shield", false)):
		var s_hp: int = int(data["shield_hp"])
		var s_max: int = int(data["shield_max_hp"])
		var s_active: bool = bool(data["shield_active"])
		draw_string(_font(), _p(976, y), "Shield", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.53, 0.71, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		_draw_bar(_r(1030, y - 8.0, 130, 7), float(s_hp) / float(s_max) if s_max > 0 else 0.0, Color(0.40, 0.60, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		var s_text := _shield_hp_text(selected_unit)
		draw_string(_font(), _p(1170, y), s_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), Color(0.53, 0.71, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		y += 15.0

	for c in data.get("consequences", []):
		draw_string(_font(), _p(976, y), "⚠ " + str(c), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), Color(0.96, 0.76, 0.40))
		y += 13.0

	var statuses: Array = data.get("statuses", [])
	if not statuses.is_empty():
		draw_string(_font(), _p(976, y), "Status: " + ", ".join(statuses), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), Color(0.96, 0.58, 0.35))
		y += 13.0

	var orbs: Array = data.get("orbs", [])
	if not orbs.is_empty():
		draw_string(_font(), _p(976, y), "Orbs: " + ", ".join(orbs), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), Color(0.45, 0.75, 0.90))
		y += 13.0

	if turn_state == TurnState.SELECTING_ATTACK and not data["attack_preview"].is_empty():
		var preview: Dictionary = data["attack_preview"]
		y += 4.0
		draw_line(_p(976, y), _p(1250, y), Color(0.25, 0.33, 0.36), 1.0)
		y += 14.0
		var legal: bool = bool(preview["legal"])
		var hit: int = int(preview["hit_percent"])
		var dmg: int = int(preview["damage"])
		var h_mod: int = int(preview.get("height_hit_modifier", 0))
		var c_mod: int = int(preview.get("cover_dodge_modifier", 0))
		var pat: String = str(preview.get("weapon_pattern", "single"))
		var status_text := "LEGAL TARGET" if legal else "INVALID TARGET"
		var status_color := Color(0.40, 0.78, 0.58) if legal else Color(0.88, 0.42, 0.42)
		draw_string(_font(), _p(976, y), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), status_color)
		y += 14.0
		var mod_notes := ""
		if h_mod != 0:
			mod_notes += " (H%+d%%)" % h_mod
		if c_mod != 0:
			mod_notes += " (Cover %+d%%)" % c_mod
		draw_string(_font(), _p(976, y), "Hit: %d%%%s · Est Dmg: %d" % [hit, mod_notes, dmg], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.93, 0.96, 0.96))
		y += 14.0
		draw_string(_font(), _p(976, y), "Pattern: %s · Range: %d-%d" % [pat.to_upper(), int(preview.get("min_range", 1)), int(preview.get("range", 1))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), Color(0.62, 0.69, 0.73))
		y += 14.0
		if str(data.get("shield_warning", "")) != "":
			draw_string(_font(), _p(976, y), "⚠ " + str(data["shield_warning"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(9), Color(0.96, 0.86, 0.48))


func _draw_action_bar() -> void:
	var bar_rect := _r(888, 521, 390, 62)
	_draw_panel(bar_rect)
	action_rects.clear()

	if turn_state == TurnState.MOVE_PREVIEW:
		move_confirm_rect = _r(906, 533, 205, 38)
		move_cancel_rect = _r(1123, 533, 137, 38)

		draw_rect(move_confirm_rect, Color(0.18, 0.42, 0.32), true)
		draw_rect(move_confirm_rect, Color(0.40, 0.78, 0.58), false, 2.0)
		_draw_centered_text(move_confirm_rect, "CONFIRM MOVE", 13, Color(0.95, 0.98, 0.96))

		draw_rect(move_cancel_rect, Color(0.38, 0.22, 0.22), true)
		draw_rect(move_cancel_rect, Color(0.72, 0.42, 0.42), false, 1.5)
		_draw_centered_text(move_cancel_rect, "CANCEL", 13, Color(0.95, 0.90, 0.90))
		return

	move_confirm_rect = Rect2()
	move_cancel_rect = Rect2()
	var widths := [104.0, 104.0, 124.0]
	var x := 906.0
	for index in range(PRIMARY_ACTIONS.size()):
		var action: String = PRIMARY_ACTIONS[index]
		var rect := _r(x, 533, widths[index], 38)
		action_rects[action] = rect
		var active: bool = action == selected_action
		var legal := _is_action_legal(action)
		var color := Color(0.16, 0.27, 0.30) if action == "Move" else Color(0.42, 0.24, 0.24) if action == "Attack" else Color(0.16, 0.20, 0.23)
		if active:
			color = color.lightened(0.18)
		if not legal:
			color = Color(0.12, 0.15, 0.16)
		draw_rect(rect, color, true)
		draw_rect(rect, Color(0.41, 0.53, 0.58) if active and legal else Color(0.32, 0.39, 0.42), false, 1.5)
		_draw_centered_text(rect, action.to_upper(), 13, Color(0.93, 0.96, 0.96) if legal else Color(0.48, 0.54, 0.56))
		x += widths[index] + 11.0


func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, Color(0.08, 0.12, 0.14, 0.96), true)
	draw_rect(rect, Color(0.25, 0.33, 0.36), false, 1.25)


func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
	draw_rect(rect, Color(0.20, 0.27, 0.30), true)
	var fill_rect := rect
	fill_rect.size.x *= clamp(ratio, 0.0, 1.0)
	draw_rect(fill_rect, fill_color, true)


func _draw_centered_text(rect: Rect2, text: String, base_size: int, color: Color) -> void:
	var font := _font()
	var size_px := _font_size(base_size)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_px)
	var position := rect.position + Vector2((rect.size.x - text_size.x) * 0.5, (rect.size.y + text_size.y * 0.52) * 0.5)
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_px, color)


func _short_part_name(part_name: String) -> String:
	if part_name == "Left Arm":
		return "L Arm"
	if part_name == "Right Arm":
		return "R Arm"
	return part_name


func _unit_by_id(id: String):
	for unit in units:
		if unit["id"] == id:
			return unit
	return null


func _unit_name_for_id(unit_id: String) -> String:
	var unit_ref = _unit_by_id(unit_id)
	if unit_ref == null:
		return unit_id
	var unit: Dictionary = unit_ref
	return str(unit["name"])


func _next_simulation_seed() -> int:
	simulation_seed = (simulation_seed * 1103515245 + 12345) & 0x7FFFFFFF
	return simulation_seed


func run_auto_battle(max_activations: int = 150, initial_seed: int = 1337) -> Dictionary:
	auto_battle = true
	simulation_seed = initial_seed
	var activations := 0
	while not _is_battle_over() and activations < max_activations:
		_rebuild_initiative_timeline()
		if initiative_timeline.is_empty():
			break
		var next_unit = _unit_by_id(initiative_timeline[0])
		if next_unit == null:
			break
		_begin_activation(next_unit)
		if str(next_unit.get("team", "")) == "player":
			_resolve_ai_activation(next_unit)
		else:
			_resolve_enemy_activation(next_unit)

		activations += 1
	var summary := _battle_summary(activations)
	auto_battle = false
	return summary


func set_debug_seed(seed_val: int) -> void:
	simulation_seed = seed_val


func configure_player_loadouts(loadouts: Dictionary) -> void:
	for unit_id in loadouts.keys():
		var unit: Dictionary = _unit_by_id(str(unit_id)) if _unit_by_id(str(unit_id)) is Dictionary else {}
		if not unit.is_empty() and str(unit.get("team", "")) == "player":
			var cfg: Dictionary = loadouts[unit_id]
			if cfg.has("weapon"):
				unit["weapon"] = cfg["weapon"]
				unit["weapon_mount_part"] = _weapon_mount_part(unit)
				var weapon_data := _weapon_data_for(unit)
				unit["shield_max_hp"] = int(weapon_data.get("shield_max_hp", 0))
				unit["shield_hp"] = int(unit["shield_max_hp"])
				unit["shield_disabled"] = int(unit["shield_max_hp"]) <= 0
			if cfg.has("orbs") and cfg["orbs"] is Dictionary:
				for part_name in cfg["orbs"]:
					_install_orb(unit, str(part_name), str(cfg["orbs"][part_name]))



func _battle_winner() -> String:

	var mission_data: Dictionary = MISSIONS_DATA.get(current_mission, {})
	var objective := str(mission_data.get("objective", "defeat_commander"))

	if objective == "defeat_commander":
		var commander_id := str(mission_data.get("commander_id", "commander"))
		var commander = _unit_by_id(commander_id)
		if commander != null and not _is_unit_in_battle(commander):
			return "player"

	var player_alive := false
	var enemy_alive := false
	for unit in units:
		if _is_unit_in_battle(unit):
			if unit["team"] == "player":
				player_alive = true
			elif unit["team"] == "enemy":
				enemy_alive = true
	if not player_alive:
		return "enemy"
	if not enemy_alive:
		return "player"
	return ""


func _is_battle_over() -> bool:
	return _battle_winner() != ""


func _battle_summary(activations: int = 0) -> Dictionary:
	var player_survivors := 0
	var enemy_survivors := 0
	var destroyed_parts := 0
	for unit in units:
		if _is_unit_in_battle(unit):
			if unit["team"] == "player":
				player_survivors += 1
			elif unit["team"] == "enemy":
				enemy_survivors += 1
		for part_name in PART_NAMES:
			if unit["parts"].has(part_name) and bool(unit["parts"][part_name]["destroyed"]):
				destroyed_parts += 1

	var commander = _unit_by_id("commander")
	var commander_defeated: bool = commander != null and not _is_unit_in_battle(commander)
	var loot := {}
	if _battle_winner() == "player":
		loot = _roll_mission_loot(current_mission, reward_seed)

	return {
		"mission_id": current_mission,
		"swapped_sides": mission_swapped_sides,
		"winner": _battle_winner(),
		"is_over": _is_battle_over(),

		"turns": turn_number,
		"activations": activations,
		"player_survivors": player_survivors,
		"enemy_survivors": enemy_survivors,
		"destroyed_parts": destroyed_parts,
		"commander_defeated": commander_defeated,
		"loot": loot,
		"turn_log": turn_log.duplicate(),
	}


func _roll_mission_loot(mission_id: String, loot_seed: int = 4242) -> Dictionary:
	var mission_data: Dictionary = MISSIONS_DATA.get(mission_id, {})
	var loot_table: Dictionary = mission_data.get("loot_table", {})
	if loot_table.is_empty():
		return {}

	var credits: int = int(loot_table.get("credits", 0))
	var arcane_ore: int = int(loot_table.get("arcane_ore", 0))
	var orb_fragments: int = int(loot_table.get("orb_fragments", 0))
	var orb_drops: Array = loot_table.get("orb_drops", [])

	var awarded_orb := ""
	if not orb_drops.is_empty():
		var total_weight := 0
		for drop in orb_drops:
			total_weight += int(drop.get("weight", 0))
		if total_weight > 0:
			var roll := (loot_seed * 1103515245 + 12345) & 0x7fffffff
			var pick := roll % total_weight
			var running := 0
			for drop in orb_drops:
				running += int(drop.get("weight", 0))
				if pick < running:
					awarded_orb = str(drop.get("orb", ""))
					break

	return {
		"credits": credits,
		"arcane_ore": arcane_ore,
		"orb_fragments": orb_fragments,
		"orb_drop": awarded_orb,
	}
