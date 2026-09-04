extends RefCounted
class_name CombatController

func validate_weapon_data(data: Dictionary, part_names: Array) -> Dictionary:
	var errors: Array[String] = []
	if not data.has("name") or str(data.get("name", "")) == "":
		errors.append("missing or empty weapon name")
	if int(data.get("range_min", 0)) <= 0:
		errors.append("range_min must be >= 1")
	if int(data.get("range_max", 0)) < int(data.get("range_min", 0)):
		errors.append("range_max must be >= range_min")
	if int(data.get("damage", 0)) <= 0:
		errors.append("damage must be > 0")
	if data.has("part_weights") and data["part_weights"] is Dictionary:
		var weights: Dictionary = data["part_weights"]
		var total_weight := 0
		for part_name in weights.keys():
			if not part_names.has(str(part_name)):
				errors.append("invalid part name in part_weights: %s" % str(part_name))
			var w := int(weights[part_name])
			if w < 0:
				errors.append("negative weight for part: %s" % str(part_name))
			total_weight += w
		if total_weight != 100:
			errors.append("part_weights total must be 100, got %d" % total_weight)
	else:
		errors.append("missing or invalid part_weights")
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


func validate_all_weapons_data(weapon_data: Dictionary, part_names: Array) -> Dictionary:
	var all_valid := true
	var weapon_errors := {}
	for weapon_name in weapon_data.keys():
		var res: Dictionary = validate_weapon_data(weapon_data[weapon_name], part_names)
		if not bool(res.get("valid", false)):
			all_valid = false
			weapon_errors[weapon_name] = res.get("errors", [])
	return {
		"valid": all_valid,
		"errors": weapon_errors,
	}


func roll_part_for_weapon(weapon_data: Dictionary, part_names: Array, seed: int) -> String:
	var weights: Dictionary = weapon_data["part_weights"]
	var total_weight := 0
	for part_name in part_names:
		total_weight += int(weights.get(part_name, 0))
	if total_weight <= 0:
		return "Body"

	var roll: int = absi(seed) % total_weight
	var cursor := 0
	for part_name in part_names:
		cursor += int(weights.get(part_name, 0))
		if roll < cursor:
			return part_name
	return "Body"


func roll_hit(hit_percent: int, seed: int) -> bool:
	return absi(seed) % 100 < clamp(hit_percent, 0, 100)


func volley_part_seed(seed: int, shot_index: int) -> int:
	return seed + shot_index * 29
