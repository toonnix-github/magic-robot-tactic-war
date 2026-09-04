extends RefCounted
class_name BattleAI

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
