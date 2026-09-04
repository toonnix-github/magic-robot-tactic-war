extends RefCounted
class_name BattleAI

func plan_activation(scene, unit) -> Dictionary:
	var decision: Dictionary = decide_action(scene, unit)
	var path: Array = []
	if decision.get("move_to") != null:
		path = scene._movement_path_to(unit, decision["move_to"])
	decision["path"] = path
	decision["start_grid"] = unit["grid"] if unit != null else Vector2i.ZERO
	return decision


func decide_action(scene, unit) -> Dictionary:
	if unit == null or not scene._is_unit_in_battle(unit):
		return {"action": "Wait", "move_to": null, "target": null}

	var opponents: Array = scene._opponents_of(unit)
	if opponents.is_empty():
		return {"action": "Wait", "move_to": null, "target": null}

	var can_move_now: bool = scene._can_move(unit)
	var candidate_tiles: Array[Vector2i] = [unit["grid"]]
	if can_move_now:
		var reachable: Dictionary = scene._calculate_reachable_tiles(unit)
		for key in reachable.keys():
			candidate_tiles.append(scene._grid_from_key(key))

	var best_attack_option: Dictionary = {}
	var original_grid: Vector2i = unit["grid"]

	for tile in candidate_tiles:
		unit["grid"] = tile
		var valid_targets: Array = scene._valid_attack_targets(unit)
		for target in valid_targets:
			var preview: Dictionary = scene._attack_preview(unit, target)
			if not bool(preview.get("legal", false)):
				continue
			var score: float = scene._score_attack_option(unit, target, tile, preview)
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
		var target_opponent = scene._primary_objective_target(unit)
		if target_opponent != null:
			var best_move_tile: Vector2i = original_grid
			var best_move_score: float = -999999.0
			for tile in candidate_tiles:
				var score: float = scene._score_move_tile(unit, tile, target_opponent["grid"])
				if score > best_move_score:
					best_move_score = score
					best_move_tile = tile
			if best_move_tile != original_grid:
				return {"action": "Wait", "move_to": best_move_tile, "target": null}

	return {"action": "Wait", "move_to": null, "target": null}

func score_attack_option(
	target,
	candidate_grid: Vector2i,
	preview: Dictionary,
	target_weapon_arm: String,
	has_intercepting_shield: bool,
	target_has_cover: bool,
	candidate_has_cover: bool,
	candidate_height: int,
	attacker_grid: Vector2i
) -> float:
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

	if target.get("parts", {}).has(target_weapon_arm):
		var arm_hp: int = int(target["parts"][target_weapon_arm]["hp"])
		if damage >= arm_hp:
			score += 35.0

	if has_intercepting_shield:
		score -= 50.0

	if target_has_cover:
		score -= 15.0

	if candidate_has_cover:
		score += 10.0
	score += float(candidate_height) * 3.0
	score -= float(grid_distance(attacker_grid, candidate_grid)) * 0.5
	return score


func score_move_tile(candidate_grid: Vector2i, target_grid: Vector2i, has_cover: bool, height: int) -> float:
	var dist := float(grid_distance(candidate_grid, target_grid))
	var score: float = 100.0 - dist * 10.0
	if has_cover:
		score += 5.0
	score += float(height) * 2.0
	return score


func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
