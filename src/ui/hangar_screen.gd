extends Control
class_name HangarScreen

const GameDataScript := preload("res://src/data/game_data.gd")
const MechBuildModelScript := preload("res://src/data/mech_build_model.gd")

const DESIGN_SIZE := Vector2(1280, 590)
const UNIT_IDS := ["arlen", "mira", "sera", "brann"]
const PART_ROW_HEIGHT := 56.0

var current_unit_id := "arlen"
var build_model = MechBuildModelScript.new()
var game_data = GameDataScript.new()
var builds: Dictionary = build_model.prototype_builds()
var unit_tab_rects: Dictionary = {}
var nav_rects: Dictionary = {}
var highlighted_part_name := "Head"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = DESIGN_SIZE
	queue_redraw()


func select_unit(unit_id: String) -> bool:
	if not UNIT_IDS.has(unit_id) or not builds.has(unit_id):
		return false
	current_unit_id = unit_id
	queue_redraw()
	return true


func select_next_unit() -> String:
	var index: int = UNIT_IDS.find(current_unit_id)
	if index < 0:
		index = 0
	else:
		index = (index + 1) % UNIT_IDS.size()
	select_unit(UNIT_IDS[index])
	return current_unit_id


func select_previous_unit() -> String:
	var index: int = UNIT_IDS.find(current_unit_id)
	if index < 0:
		index = 0
	else:
		index = (index - 1 + UNIT_IDS.size()) % UNIT_IDS.size()
	select_unit(UNIT_IDS[index])
	return current_unit_id


func current_build_summary() -> Dictionary:
	return build_model.build_summary(
		_current_build(),
		GameDataScript.WEAPON_DATA,
		GameDataScript.ORB_DATA,
		GameDataScript.PART_NAMES
	)


func part_rows() -> Array:
	var summary: Dictionary = current_build_summary()
	var source_unit: Dictionary = _source_player_unit(current_unit_id)
	var rows: Array = []
	var orb_slots: Dictionary = summary.get("orb_slots", {})
	var parts: Dictionary = summary.get("parts", {})
	var required_weapon_parts: Array = summary.get("weapon_required_parts", [])

	for part_name in GameDataScript.PART_NAMES:
		var orb_id := str(orb_slots.get(part_name, ""))
		var occupied_by := ""
		if required_weapon_parts.has(part_name):
			occupied_by = "Both Arms" if bool(summary.get("uses_both_arms", false)) else str(summary.get("weapon", ""))
		elif part_name == MechBuildModelScript.OFF_HAND_ARM and str(summary.get("off_hand", "")) != "":
			occupied_by = str(summary.get("off_hand", ""))

		rows.append({
			"part_name": part_name,
			"part_id": str(parts.get(part_name, "")),
			"durability": _durability_label(part_name, str(parts.get(part_name, "")), source_unit),
			"orb_id": orb_id,
			"orb_state": _orb_label(orb_id),
			"occupied_by": occupied_by,
		})
	return rows


func weapon_panel_data() -> Dictionary:
	var summary: Dictionary = current_build_summary()
	var uses_both_arms := bool(summary.get("uses_both_arms", false))
	var off_hand := str(summary.get("off_hand", ""))
	var handedness := str(summary.get("weapon_handedness", ""))
	return {
		"weapon": str(summary.get("weapon", "")),
		"weapon_handedness": handedness,
		"arm_occupancy": "Both Arms" if uses_both_arms else "Right Arm weapon / Left Arm off-hand",
		"off_hand": "Disabled by 2H weapon" if uses_both_arms else (off_hand if off_hand != "" else "Empty"),
		"has_shield": bool(summary.get("has_shield", false)),
		"shield_max_hp": int(summary.get("shield_max_hp", 0)),
	}


func highlight_part(part_name: String) -> bool:
	if not GameDataScript.PART_NAMES.has(part_name):
		return false
	highlighted_part_name = part_name
	queue_redraw()
	return true


func available_part_options(part_name: String = "") -> Array:
	var slot_name := highlighted_part_name if part_name == "" else part_name
	return build_model.part_catalog(slot_name)


func preview_part_delta(part_name: String, candidate_part_id: String) -> Dictionary:
	return build_model.part_delta(_current_build(), part_name, candidate_part_id, GameDataScript.PART_NAMES)


func swap_part(part_name: String, candidate_part_id: String) -> bool:
	var before: Dictionary = _current_build()
	var after: Dictionary = build_model.swap_part(before, part_name, candidate_part_id, GameDataScript.PART_NAMES)
	if after == before:
		return false
	builds[current_unit_id] = after
	highlighted_part_name = part_name
	queue_redraw()
	return true


func layout_metrics() -> Dictionary:
	var rects: Dictionary = _layout_rects()
	var within_bounds := true
	var bounds := Rect2(Vector2.ZERO, DESIGN_SIZE)
	for rect in rects.values():
		if rect is Rect2:
			if not bounds.encloses(rect):
				within_bounds = false
				break
	return {
		"design_size": DESIGN_SIZE,
		"within_design_bounds": within_bounds,
		"part_row_height": PART_ROW_HEIGHT,
		"rects": rects,
	}


func _gui_input(event: InputEvent) -> void:
	var press_position = _event_press_position(event)
	if press_position == null:
		return

	if nav_rects.get("previous", Rect2()).has_point(press_position):
		select_previous_unit()
		accept_event()
		return
	if nav_rects.get("next", Rect2()).has_point(press_position):
		select_next_unit()
		accept_event()
		return

	for unit_id in unit_tab_rects.keys():
		if unit_tab_rects[unit_id].has_point(press_position):
			select_unit(str(unit_id))
			accept_event()
			return


func _draw() -> void:
	var rects: Dictionary = _layout_rects()
	unit_tab_rects.clear()
	nav_rects.clear()

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.09, 0.10), true)
	_draw_panel(rects["header"], Color(0.10, 0.13, 0.14))
	_draw_title()
	_draw_unit_tabs(rects["tabs"])
	_draw_unit_identity(rects["identity"])
	_draw_weapon_panel(rects["weapon"])
	_draw_parts_panel(rects["parts"])
	_draw_part_options(rects["options"])


func _draw_title() -> void:
	draw_string(_font(), _p(32, 45), "HANGAR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(22), Color(0.94, 0.96, 0.95))
	draw_string(_font(), _p(32, 68), "Build Your Mech", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.60, 0.68, 0.70))


func _draw_unit_tabs(tab_area: Rect2) -> void:
	var tab_width: float = 150.0
	var x: float = tab_area.position.x
	for unit_key in UNIT_IDS:
		var unit_id := str(unit_key)
		var rect := Rect2(Vector2(x, tab_area.position.y), Vector2(tab_width, tab_area.size.y))
		unit_tab_rects[unit_id] = rect
		var active: bool = unit_id == current_unit_id
		draw_rect(rect, Color(0.19, 0.27, 0.27) if active else Color(0.12, 0.15, 0.16), true)
		draw_rect(rect, Color(0.46, 0.65, 0.56) if active else Color(0.25, 0.31, 0.32), false, 1.5)
		_draw_centered_text(rect, _pilot_name(unit_id), 13, Color(0.93, 0.96, 0.95) if active else Color(0.64, 0.70, 0.71))
		x += tab_width + 10.0

	nav_rects["previous"] = Rect2(Vector2(tab_area.position.x - 54.0, tab_area.position.y), Vector2(42.0, tab_area.size.y))
	nav_rects["next"] = Rect2(Vector2(x + 2.0, tab_area.position.y), Vector2(42.0, tab_area.size.y))
	for key in ["previous", "next"]:
		var rect: Rect2 = nav_rects[key]
		draw_rect(rect, Color(0.12, 0.15, 0.16), true)
		draw_rect(rect, Color(0.25, 0.31, 0.32), false, 1.5)
		_draw_centered_text(rect, "<" if key == "previous" else ">", 16, Color(0.78, 0.84, 0.84))


func _draw_unit_identity(rect: Rect2) -> void:
	_draw_panel(rect, Color(0.11, 0.14, 0.15))
	var summary: Dictionary = current_build_summary()
	draw_string(_font(), rect.position + Vector2(22, 34), _pilot_name(current_unit_id), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(24), Color(0.94, 0.96, 0.95))
	draw_string(_font(), rect.position + Vector2(22, 62), str(summary.get("mech", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(14), Color(0.63, 0.70, 0.71))
	draw_string(_font(), rect.position + Vector2(22, 94), _role_line(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.86, 0.77, 0.52))


func _draw_weapon_panel(rect: Rect2) -> void:
	_draw_panel(rect, Color(0.12, 0.14, 0.15))
	var data: Dictionary = weapon_panel_data()
	draw_string(_font(), rect.position + Vector2(20, 28), "WEAPON", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.55, 0.62, 0.64))
	draw_string(_font(), rect.position + Vector2(20, 57), "%s / %s" % [str(data["weapon"]), str(data["weapon_handedness"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(19), Color(0.94, 0.96, 0.95))
	draw_string(_font(), rect.position + Vector2(20, 87), str(data["arm_occupancy"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.65, 0.72, 0.73))
	draw_string(_font(), rect.position + Vector2(20, 116), "OFF-HAND", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.55, 0.62, 0.64))
	draw_string(_font(), rect.position + Vector2(20, 144), str(data["off_hand"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(17), Color(0.55, 0.76, 0.80) if bool(data["has_shield"]) else Color(0.67, 0.70, 0.70))


func _draw_parts_panel(rect: Rect2) -> void:
	_draw_panel(rect, Color(0.10, 0.12, 0.13))
	draw_string(_font(), rect.position + Vector2(20, 30), "MECH PARTS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.55, 0.62, 0.64))
	var y := rect.position.y + 50.0
	for row in part_rows():
		var row_rect := Rect2(Vector2(rect.position.x + 16.0, y), Vector2(rect.size.x - 32.0, PART_ROW_HEIGHT - 8.0))
		var selected := str(row["part_name"]) == highlighted_part_name
		draw_rect(row_rect, Color(0.17, 0.22, 0.21) if selected else Color(0.14, 0.17, 0.18), true)
		draw_rect(row_rect, Color(0.46, 0.65, 0.56) if selected else Color(0.24, 0.30, 0.31), false, 1.0)
		draw_string(_font(), row_rect.position + Vector2(12, 21), str(row["part_name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.88, 0.91, 0.90))
		draw_string(_font(), row_rect.position + Vector2(112, 21), str(row["part_id"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.65, 0.72, 0.72))
		draw_string(_font(), row_rect.position + Vector2(350, 21), str(row["durability"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.74, 0.83, 0.74))
		draw_string(_font(), row_rect.position + Vector2(450, 21), str(row["orb_state"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.56, 0.75, 0.82))
		draw_string(_font(), row_rect.position + Vector2(640, 21), str(row["occupied_by"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(12), Color(0.86, 0.77, 0.52))
		y += PART_ROW_HEIGHT


func _draw_part_options(rect: Rect2) -> void:
	_draw_panel(rect, Color(0.12, 0.14, 0.15))
	draw_string(_font(), rect.position + Vector2(20, 28), "PART OPTIONS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.55, 0.62, 0.64))
	draw_string(_font(), rect.position + Vector2(20, 52), highlighted_part_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(17), Color(0.94, 0.96, 0.95))
	var y := rect.position.y + 78.0
	for option in available_part_options(highlighted_part_name).slice(0, 3):
		var option_id := str(option.get("id", ""))
		var delta: Dictionary = preview_part_delta(highlighted_part_name, option_id)
		var line := str(option.get("name", option_id))
		var delta_lines: Array = delta.get("display_lines", [])
		if not delta_lines.is_empty():
			line += " / " + str(delta_lines[0])
		draw_string(_font(), Vector2(rect.position.x + 20.0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(11), Color(0.72, 0.79, 0.78))
		y += 34.0


func _layout_rects() -> Dictionary:
	return {
		"header": Rect2(Vector2(18, 18), Vector2(1244, 86)),
		"tabs": Rect2(Vector2(356, 40), Vector2(630, 42)),
		"identity": Rect2(Vector2(26, 128), Vector2(300, 414)),
		"weapon": Rect2(Vector2(350, 128), Vector2(300, 206)),
		"options": Rect2(Vector2(350, 352), Vector2(300, 190)),
		"parts": Rect2(Vector2(674, 128), Vector2(580, 348)),
	}


func _current_build() -> Dictionary:
	return builds.get(current_unit_id, {}).duplicate(true)


func _source_player_unit(unit_id: String) -> Dictionary:
	for unit in GameDataScript.PLAYER_UNIT_DATA:
		if str(unit.get("id", "")) == unit_id:
			return unit
	return {}


func _durability_label(part_name: String, part_id: String, source_unit: Dictionary) -> String:
	for option in build_model.part_catalog(part_name):
		if str(option.get("id", "")) == part_id:
			return "%d HP" % int(option.get("max_hp", 0))
	var parts: Dictionary = source_unit.get("parts", {})
	var ratio := float(parts.get(part_name, 1.0))
	return "%d HP" % int(round(ratio * 100.0))


func _orb_label(orb_id: String) -> String:
	if orb_id == "":
		return "Empty"
	var orb_data: Dictionary = GameDataScript.ORB_DATA.get(orb_id, {})
	return str(orb_data.get("name", orb_id))


func _pilot_name(unit_id: String) -> String:
	var pilot: Dictionary = GameDataScript.PILOT_DATA.get(unit_id, {})
	return str(pilot.get("name", unit_id.capitalize()))


func _role_line() -> String:
	var pilot: Dictionary = GameDataScript.PILOT_DATA.get(current_unit_id, {})
	var passive: Dictionary = pilot.get("passive", {})
	return str(passive.get("name", "Passive Ready"))


func _event_press_position(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return event.position
	if event is InputEventScreenTouch and event.pressed:
		return event.position
	return null


func _draw_panel(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)
	draw_rect(rect, Color(0.25, 0.31, 0.32), false, 1.5)


func _draw_centered_text(rect: Rect2, text: String, size_pt: int, color: Color) -> void:
	draw_string(_font(), rect.position + Vector2(0, rect.size.y * 0.5 + _font_size(size_pt) * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, _font_size(size_pt), color)


func _font() -> Font:
	return ThemeDB.fallback_font


func _font_size(size_pt: int) -> int:
	var scale_factor: float = min(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y) if size.x > 0.0 and size.y > 0.0 else 1.0
	return max(9, int(round(float(size_pt) * scale_factor)))


func _p(x: float, y: float) -> Vector2:
	var scale := Vector2(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y) if size.x > 0.0 and size.y > 0.0 else Vector2.ONE
	return Vector2(x * scale.x, y * scale.y)

func available_orb_options(part_name: String) -> Array:
	var options: Array = []
	for orb_id in GameDataScript.ORB_DATA.keys():
		var orb = GameDataScript.ORB_DATA[orb_id].duplicate(true)
		orb["id"] = orb_id
		options.append(orb)
	return options

func install_orb(part_name: String, orb_id: String) -> bool:
	if not builds.has(current_unit_id): return false
	builds[current_unit_id] = build_model.install_orb(builds[current_unit_id], part_name, orb_id, [])
	queue_redraw()
	return true

func remove_orb(part_name: String) -> bool:
	if not builds.has(current_unit_id): return false
	builds[current_unit_id] = build_model.remove_orb(builds[current_unit_id], part_name, [])
	queue_redraw()
	return true

