extends RefCounted
class_name GridController

func grid_key(grid) -> String:
	return "%d,%d" % [grid.x, grid.y]


func grid_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func is_in_bounds(grid, columns: int, rows: int) -> bool:
	return grid.x >= 0 and grid.x < columns and grid.y >= 0 and grid.y < rows


func default_height_at(grid, mission_id: String) -> int:
	if grid == null:
		return 0
	if mission_id == "ancient_ruins":
		if grid.x <= 3:
			return 0
		elif grid.x <= 6:
			return 1
		return 2
	if mission_id == "crystal_quarry":
		if grid.x >= 3 and grid.x <= 7:
			return 0
		return 1
	if mission_id == "ascending_ridge":
		if grid.x <= 1:
			return 0
		elif grid.x <= 3:
			return 1
		elif grid.x <= 5:
			return 2
		elif grid.x <= 7:
			return 3
		return 4
	return int(clamp(floor(float(grid.x) / 2.0), 0.0, 4.0))


func terrain_at(
	grid,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> Dictionary:
	var terrain := {
		"height": default_height_at(grid, mission_id),
		"cover": false,
		"cover_dodge_bonus": cover_dodge_bonus,
		"cover_damage_reduction_percent": cover_damage_reduction_percent,
		"blocks_los": false,
	}
	if grid != null and is_in_bounds(grid, columns, rows):
		var override: Dictionary = terrain_tiles.get(grid_key(grid), {})
		for property in override.keys():
			terrain[property] = override[property]
	terrain["height"] = int(clamp(int(terrain["height"]), 0, 4))
	return terrain


func height_at(
	grid,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> int:
	return int(terrain_at(grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows)["height"])


func height_hit_modifier(
	attacker,
	target,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int,
	hit_per_level: int,
	hit_cap: int
) -> int:
	if attacker == null or target == null:
		return 0
	var attacker_height := height_at(attacker["grid"], mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows)
	var target_height := height_at(target["grid"], mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows)
	return int(clamp((attacker_height - target_height) * hit_per_level, -hit_cap, hit_cap))


func has_cover(
	grid,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> bool:
	return bool(terrain_at(grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows).get("cover", false))


func terrain_adjusted_damage(
	target,
	damage: int,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> int:
	var adjusted: int = max(0, damage)
	if target == null or not has_cover(target["grid"], mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows):
		return adjusted
	var reduction := int(terrain_at(target["grid"], mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows).get("cover_damage_reduction_percent", 0))
	return int(round(float(adjusted) * (100.0 - float(reduction)) / 100.0))


func can_traverse_step(
	from_grid: Vector2i,
	to_grid: Vector2i,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> bool:
	var to_height := height_at(to_grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows)
	var from_height := height_at(from_grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows)
	return abs(to_height - from_height) <= 1


func blocks_los(
	grid,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> bool:
	return bool(terrain_at(grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows).get("blocks_los", false))


func line_grids_between(a: Vector2i, b: Vector2i) -> Array:
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


func has_line_of_sight(
	a: Vector2i,
	b: Vector2i,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int
) -> bool:
	for grid in line_grids_between(a, b):
		if blocks_los(grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows):
			return false
	return true


func occupied_by_opponent(grid: Vector2i, team: String, units: Array) -> bool:
	for unit in units:
		if is_unit_in_battle(unit) and unit["grid"] == grid and unit["team"] != team:
			return true
	return false


func occupied_by_any_unit(grid: Vector2i, units: Array) -> bool:
	for unit in units:
		if is_unit_in_battle(unit) and unit["grid"] == grid:
			return true
	return false


func is_unit_in_battle(unit) -> bool:
	return unit != null and bool(unit.get("in_battle", true)) and not bool(unit.get("defeated", false))


func calculate_reachable_tiles(
	unit,
	units: Array,
	move_range: int,
	mission_id: String,
	terrain_tiles: Dictionary,
	cover_dodge_bonus: int,
	cover_damage_reduction_percent: int,
	columns: int,
	rows: int,
	directions: Array
) -> Dictionary:
	if not is_unit_in_battle(unit):
		return {}

	var visited := {}
	var frontier := [{"grid": unit["grid"], "distance": 0}]
	visited[grid_key(unit["grid"])] = 0

	while not frontier.is_empty():
		var current = frontier.pop_front()
		if current["distance"] >= move_range:
			continue

		for direction in directions:
			var next_grid = current["grid"] + direction
			if not is_in_bounds(next_grid, columns, rows):
				continue
			if not can_traverse_step(current["grid"], next_grid, mission_id, terrain_tiles, cover_dodge_bonus, cover_damage_reduction_percent, columns, rows):
				continue
			if occupied_by_opponent(next_grid, str(unit["team"]), units):
				continue

			var next_distance = current["distance"] + 1
			var key := grid_key(next_grid)
			if not visited.has(key) or next_distance < visited[key]:
				visited[key] = next_distance
				frontier.append({"grid": next_grid, "distance": next_distance})

	var reachable := {}
	for key in visited.keys():
		var grid := grid_from_key(key)
		# allies may be traversed, but no unit may end movement on an occupied tile.
		if grid != unit["grid"] and not occupied_by_any_unit(grid, units):
			reachable[key] = visited[key]
	return reachable
