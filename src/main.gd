extends Control

const PROTOTYPE_VERSION := "0.1"
const GRID_COLUMNS := 10
const GRID_ROWS := 7
const MOVE_RANGE := 3
const PRIMARY_ACTIONS := ["Move", "Attack", "Wait"]

const DESIGN_SIZE := Vector2(1311.0, 603.0)
const TILE_SIZE := Vector2(77.0, 41.0)
const TILE_SPACING := Vector2(80.0, 44.0)
const ELEVATION_STEP := 9.0
const GRID_ORIGIN := Vector2(228.0, 140.0)
const PART_NAMES := ["Head", "Body", "Left Arm", "Right Arm", "Legs"]
const DIRECTIONS := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

var units := []
var selected_unit = null
var selected_action := "Move"
var reachable_tiles := {}
var action_rects := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_units()
	_select_unit(units[0])
	print("Magic Robot Tactic War combat prototype v%s" % PROTOTYPE_VERSION)
	print("Graybox battle milestone loaded: 7x10 grid, selection, movement, and Phase 1 HUD.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press_position = _event_press_position(event)
	if press_position == null:
		return

	for action in PRIMARY_ACTIONS:
		if action_rects.has(action) and action_rects[action].has_point(press_position):
			_select_action(action)
			accept_event()
			return

	var tapped_unit = _unit_at_position(press_position)
	if tapped_unit != null:
		_select_unit(tapped_unit)
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
	_draw_action_bar()


func _create_units() -> void:
	units = [
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
		{
			"id": "enemy_blade",
			"name": "Enemy Blade",
			"mech": "Rust Frame",
			"weapon": "Blade",
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


func _select_unit(unit) -> void:
	selected_unit = unit
	selected_action = "Move"
	if selected_unit["team"] == "player":
		reachable_tiles = _calculate_reachable_tiles(selected_unit)
	else:
		reachable_tiles.clear()
	queue_redraw()


func _select_action(action: String) -> void:
	selected_action = action
	if selected_unit != null and selected_unit["team"] == "player" and selected_action == "Move":
		reachable_tiles = _calculate_reachable_tiles(selected_unit)
	else:
		reachable_tiles.clear()
	queue_redraw()


func _handle_grid_tap(position: Vector2) -> void:
	var grid = _grid_at_position(position)
	if grid == null:
		if selected_action == "Attack" and selected_unit != null:
			_select_unit(selected_unit)
		return

	if selected_unit == null or selected_unit["team"] != "player":
		return

	if selected_action == "Move":
		var key := _grid_key(grid)
		if reachable_tiles.has(key) and not _occupied_by_any_unit(grid):
			selected_unit["grid"] = grid
			reachable_tiles = _calculate_reachable_tiles(selected_unit)
			queue_redraw()


func _calculate_reachable_tiles(unit) -> Dictionary:
	var visited := {}
	var frontier := [{"grid": unit["grid"], "distance": 0}]
	visited[_grid_key(unit["grid"])] = 0

	while not frontier.is_empty():
		var current = frontier.pop_front()
		if current["distance"] >= MOVE_RANGE:
			continue

		for direction in DIRECTIONS:
			var next_grid = current["grid"] + direction
			if not _is_in_bounds(next_grid):
				continue
			if abs(_height_at(next_grid) - _height_at(current["grid"])) > 1:
				continue
			if _occupied_by_opponent(next_grid, str(selected_unit["team"])):
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
		if unit["grid"] == grid and unit["team"] != team:
			return true
	return false


func _occupied_by_any_unit(grid: Vector2i) -> bool:
	for unit in units:
		if unit["grid"] == grid:
			return true
	return false


func _unit_at_position(position: Vector2):
	for index in range(units.size() - 1, -1, -1):
		var unit = units[index]
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


func _height_at(grid) -> int:
	return int(floor(float(grid.x) / 2.0))


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

	_draw_cover(Vector2i(5, 4))
	_draw_cover(Vector2i(8, 1))

	for unit in units:
		_draw_unit(unit)


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

	if selected_unit != null and selected_unit["id"] == unit["id"]:
		draw_arc(center, radius * 1.48, 0.0, TAU, 40, Color(0.53, 0.71, 0.75), 2.5, true)

	var fill_color: Color = unit["color"]
	if unit["team"] == "enemy":
		fill_color = Color(0.73, 0.34, 0.34)

	draw_circle(center, radius, fill_color)
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.90, 0.94, 0.95), 2.0, true)
	_draw_centered_text(Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), str(unit["letter"]), 12, Color.WHITE)


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
	_draw_bar(_r(115, 92, 122, 8), float(selected_unit["hp"]), Color(0.46, 0.65, 0.56))


func _draw_initiative_strip() -> void:
	_draw_panel(_r(476, 27, 360, 58))
	draw_string(_font(), _p(494, 48), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.56, 0.63, 0.67))
	var order := ["arlen", "enemy_blade", "mira", "enemy_rifle", "sera", "commander"]
	for index in range(order.size()):
		var unit = _unit_by_id(order[index])
		if unit == null:
			continue
		var center := _p(532 + index * 48, 58)
		var radius: float = min((16.0 if index == 0 else 14.0) * _scale().x, (16.0 if index == 0 else 14.0) * _scale().y)
		draw_circle(center, radius, unit["color"])
		_draw_centered_text(Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), str(unit["letter"]), 11, Color.WHITE)


func _draw_mission_panel() -> void:
	_draw_panel(_r(1030, 30, 248, 92))
	draw_string(_font(), _p(1052, 55), "TURN 01", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.56, 0.63, 0.67))
	draw_string(_font(), _p(1052, 80), "Defeat Commander", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(15), Color(0.95, 0.97, 0.97))
	draw_string(_font(), _p(1052, 101), "Ancient Ruins graybox", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(11), Color(0.62, 0.69, 0.73))


func _draw_part_status_panel() -> void:
	if selected_unit == null:
		return

	_draw_panel(_r(30, 410, 176, 124))
	draw_string(_font(), _p(48, 433), "PART STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.56, 0.63, 0.67))
	for index in range(PART_NAMES.size()):
		var part_name: String = PART_NAMES[index]
		var y := 458.0 + index * 17.0
		draw_string(_font(), _p(48, y), _short_part_name(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size(10), Color(0.78, 0.82, 0.84))
		_draw_bar(_r(100, y - 8.0, 76, 7), float(selected_unit["parts"][part_name]), Color(0.46, 0.65, 0.56))


func _draw_action_bar() -> void:
	var bar_rect := _r(888, 521, 390, 62)
	_draw_panel(bar_rect)
	action_rects.clear()
	var widths := [104.0, 104.0, 124.0]
	var x := 906.0
	for index in range(PRIMARY_ACTIONS.size()):
		var action: String = PRIMARY_ACTIONS[index]
		var rect := _r(x, 533, widths[index], 38)
		action_rects[action] = rect
		var active: bool = action == selected_action
		var color := Color(0.16, 0.27, 0.30) if action == "Move" else Color(0.42, 0.24, 0.24) if action == "Attack" else Color(0.16, 0.20, 0.23)
		if active:
			color = color.lightened(0.18)
		draw_rect(rect, color, true)
		draw_rect(rect, Color(0.41, 0.53, 0.58) if active else Color(0.32, 0.39, 0.42), false, 1.5)
		_draw_centered_text(rect, action.to_upper(), 13, Color(0.93, 0.96, 0.96))
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
