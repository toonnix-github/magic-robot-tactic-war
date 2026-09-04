extends RefCounted
class_name CombatController

func initialize_part_state(unit, part_names: Array, part_max_hp: int) -> void:
	var source_parts: Dictionary = unit["parts"]
	var part_state := {}
	for part_name in part_names:
		var ratio := float(source_parts[part_name])
		part_state[part_name] = {
			"max_hp": part_max_hp,
			"hp": int(round(ratio * float(part_max_hp))),
			"destroyed": ratio <= 0.0,
			"orb": null,
			"orb_disabled": false,
		}
	unit["parts"] = part_state
	unit["hp"] = overall_hp_ratio(unit, part_names)


func damage_part(unit, part_name: String, amount: int, turn_log: Array, part_names: Array, head_destroyed_hit_penalty: int) -> Dictionary:
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
		apply_part_consequence(unit, part_name, turn_log, head_destroyed_hit_penalty)

	unit["hp"] = overall_hp_ratio(unit, part_names)
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


func damage_shield(unit, amount: int, turn_log: Array) -> Dictionary:
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


func miss_damage_result(target, part_name: String) -> Dictionary:
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


func resolve_weapon_attack(
	attacker,
	target,
	preview: Dictionary,
	part_name: String,
	seed: int,
	damage_override: int,
	part_seed: int,
	part_names: Array,
	weapon_data: Dictionary,
	terrain_adjusted_damage: Callable,
	calculate_attack_damage: Callable,
	damage_part: Callable,
	resolve_orb_proc: Callable
) -> Dictionary:
	var resolved_part: String = part_name
	var resolved_part_seed: int = seed if part_seed < 0 else part_seed
	if resolved_part == "" or not bool(weapon_data["allow_manual_part"]):
		resolved_part = roll_part_for_weapon(weapon_data, part_names, resolved_part_seed)
	if not part_names.has(resolved_part):
		resolved_part = roll_part_for_weapon(weapon_data, part_names, resolved_part_seed)

	var hit_percent: int = int(preview["hit_percent"])
	var hit: bool = roll_hit(hit_percent, seed)
	var damage_result: Dictionary = miss_damage_result(target, resolved_part)
	var orb_proc: Dictionary = {
		"triggered": false,
		"status": "",
		"orb_id": "",
		"seed": seed,
	}
	if hit:
		var damage: int = damage_override if damage_override >= 0 else int(weapon_data["damage"])
		var adjusted_damage: int = int(terrain_adjusted_damage.call(
			target,
			int(calculate_attack_damage.call(attacker, damage, target, resolved_part))
		))
		damage_result = damage_part.call(target, resolved_part, adjusted_damage)
		orb_proc = resolve_orb_proc.call(attacker, target, seed)

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


func apply_part_consequence(unit, part_name: String, turn_log: Array, head_destroyed_hit_penalty: int) -> void:
	var part: Dictionary = unit["parts"][part_name]
	part["destroyed"] = true
	part["orb_disabled"] = true

	if part_name == "Head":
		unit["accuracy_modifier"] = head_destroyed_hit_penalty
	elif part_name == "Legs":
		unit["current_move_range"] = 0
		unit["dodge"] = 0
	elif part_name == "Body":
		unit["defeated"] = true
		unit["in_battle"] = false
		turn_log.append("%s:defeated" % unit["id"])
	elif part_name == unit["weapon_mount_part"]:
		unit["weapon_disabled"] = true


func active_orbs(unit, part_names: Array, orb_data: Dictionary) -> Array:
	var active := []
	if unit == null:
		return active
	for part_name in part_names:
		var part: Dictionary = unit["parts"][part_name]
		if part["orb"] == null or bool(part["orb_disabled"]) or bool(part["destroyed"]):
			continue
		var orb: Dictionary = orb_data.get(str(part["orb"]), {})
		if orb.is_empty():
			continue
		var active_orb: Dictionary = orb.duplicate(true)
		active_orb["id"] = str(part["orb"])
		active_orb["host_part"] = part_name
		active.append(active_orb)
	return active


func has_status(unit, status: String) -> bool:
	return unit != null and unit.has("statuses") and unit["statuses"].has(status)


func remove_status(unit, status: String) -> bool:
	if unit == null or not unit.has("statuses"):
		return false
	var index: int = unit["statuses"].find(status)
	if index >= 0:
		unit["statuses"].remove_at(index)
		return true
	return false


func resolve_turn_start_statuses(unit, burn_damage: int, turn_log: Array, part_names: Array, head_destroyed_hit_penalty: int) -> Dictionary:
	var result := {
		"burned": false,
		"burn_damage": 0,
		"defeated": false,
		"message": "",
	}
	if unit == null or not is_unit_in_battle(unit):
		return result

	if has_status(unit, "Burn"):
		var dmg_result := damage_part(unit, "Body", burn_damage, turn_log, part_names, head_destroyed_hit_penalty)
		var damage_applied: int = int(dmg_result.get("damage_applied", 0))
		result["burned"] = true
		result["burn_damage"] = damage_applied
		turn_log.append("%s:status:Burn:%d" % [unit["id"], damage_applied])
		result["message"] = "%s takes %d Burn damage to Body" % [unit["name"], damage_applied]
		remove_status(unit, "Burn")
		if not is_unit_in_battle(unit):
			result["defeated"] = true
	return result


func overall_hp_ratio(unit, part_names: Array) -> float:
	if unit == null:
		return 0.0
	var hp_total := 0
	var max_total := 0
	for part_name in part_names:
		var part: Dictionary = unit["parts"][part_name]
		hp_total += int(part["hp"])
		max_total += int(part["max_hp"])
	return float(hp_total) / max(1.0, float(max_total))


func is_unit_in_battle(unit) -> bool:
	return unit != null and bool(unit.get("in_battle", true)) and not bool(unit.get("defeated", false))

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
