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


func resolve_blockable_shot(
	attacker,
	target,
	preview: Dictionary,
	part_name: String,
	hit_seed: int,
	damage: int,
	part_seed: int,
	part_names: Array,
	weapon_data: Dictionary,
	intercepting_shield_for: Callable,
	should_hit_shield: Callable,
	terrain_adjusted_damage: Callable,
	calculate_attack_damage: Callable,
	damage_part: Callable,
	damage_shield: Callable,
	pilot_shield_damage_reduction: Callable,
	resolve_orb_proc: Callable
) -> Dictionary:
	var shield_unit = intercepting_shield_for.call(attacker, target, weapon_data)
	if shield_unit != null:
		return resolve_shield_damage(
			attacker,
			shield_unit,
			target,
			preview,
			hit_seed,
			damage,
			true,
			weapon_data,
			terrain_adjusted_damage,
			calculate_attack_damage,
			damage_shield,
			pilot_shield_damage_reduction,
			resolve_orb_proc
		)
	if bool(should_hit_shield.call(target, weapon_data, part_seed)):
		return resolve_shield_damage(
			attacker,
			target,
			target,
			preview,
			hit_seed,
			damage,
			false,
			weapon_data,
			terrain_adjusted_damage,
			calculate_attack_damage,
			damage_shield,
			pilot_shield_damage_reduction,
			resolve_orb_proc
		)
	return resolve_weapon_attack(
		attacker,
		target,
		preview,
		part_name,
		hit_seed,
		damage,
		part_seed,
		part_names,
		weapon_data,
		terrain_adjusted_damage,
		calculate_attack_damage,
		damage_part,
		resolve_orb_proc
	)


func resolve_shield_damage(
	attacker,
	shield_unit,
	original_target,
	preview: Dictionary,
	hit_seed: int,
	damage: int,
	intercepted: bool,
	weapon_data: Dictionary,
	terrain_adjusted_damage: Callable,
	calculate_attack_damage: Callable,
	damage_shield: Callable,
	pilot_shield_damage_reduction: Callable,
	resolve_orb_proc: Callable
) -> Dictionary:
	var hit_percent: int = int(preview["hit_percent"])
	var hit: bool = roll_hit(hit_percent, hit_seed)
	var damage_result: Dictionary = shield_damage_result(shield_unit)
	var orb_proc: Dictionary = empty_orb_proc(hit_seed)
	if hit:
		var raw_dmg: int = int(calculate_attack_damage.call(attacker, damage, shield_unit, "Shield"))
		var terrain_dmg: int = int(terrain_adjusted_damage.call(shield_unit, raw_dmg))
		var reduction: int = int(pilot_shield_damage_reduction.call(shield_unit))
		var final_shield_dmg: int = int(max(1, terrain_dmg - reduction)) if reduction > 0 else terrain_dmg
		damage_result = damage_shield.call(shield_unit, final_shield_dmg)
		orb_proc = resolve_orb_proc.call(attacker, shield_unit, hit_seed)
	return {
		"attacker_id": str(attacker["id"]),
		"target_id": str(shield_unit["id"]),
		"original_target_id": str(original_target["id"]),
		"weapon": str(weapon_data["name"]),
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
		"shield_unit": shield_unit,
		"orb_proc": orb_proc,
	}


func shield_damage_result(unit) -> Dictionary:
	return {
		"unit_id": str(unit["id"]),
		"part_name": "Shield",
		"damage_requested": 0,
		"damage_applied": 0,
		"hp_before": int(unit.get("shield_hp", 0)),
		"hp_after": int(unit.get("shield_hp", 0)),
		"destroyed": int(unit.get("shield_hp", 0)) <= 0 or bool(unit.get("shield_disabled", false)),
		"destroyed_now": false,
		"orb_disabled": false,
	}


func resolve_spear_attack(
	attacker,
	target,
	preview: Dictionary,
	seed: int,
	part_names: Array,
	weapon_data: Dictionary,
	spear_direction: Callable,
	line_attack_targets: Callable,
	attack_preview: Callable,
	terrain_adjusted_damage: Callable,
	calculate_attack_damage: Callable,
	damage_part: Callable,
	resolve_orb_proc: Callable
) -> Dictionary:
	var direction: Vector2i = spear_direction.call(attacker, target)
	var lane_targets: Array = line_attack_targets.call(attacker, direction, int(weapon_data["range_max"]))
	var results: Array = []
	for lane_target in lane_targets:
		var tile_index: int = int(lane_target["tile_index"])
		var lane_preview: Dictionary = attack_preview.call(attacker, lane_target["unit"])
		var damage: int = int(weapon_data["damage"]) if tile_index == 1 else int(weapon_data["secondary_damage"])
		var result: Dictionary = resolve_weapon_attack(
			attacker,
			lane_target["unit"],
			lane_preview,
			"",
			seed + tile_index - 1,
			damage,
			seed + tile_index - 1,
			part_names,
			weapon_data,
			terrain_adjusted_damage,
			calculate_attack_damage,
			damage_part,
			resolve_orb_proc
		)
		result["tile_index"] = tile_index
		result["grid"] = lane_target["grid"]
		results.append(result)

	var total_damage: int = 0
	var any_hit: bool = false
	for result in results:
		total_damage += int(result["damage_applied"])
		any_hit = any_hit or bool(result["hit"])

	var primary_result: Dictionary = miss_damage_result(target, "Body")
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


func resolve_rifle_attack(
	attacker,
	target,
	preview: Dictionary,
	seed: int,
	part_names: Array,
	weapon_data: Dictionary,
	intercepting_shield_for: Callable,
	should_hit_shield: Callable,
	terrain_adjusted_damage: Callable,
	calculate_attack_damage: Callable,
	damage_part: Callable,
	damage_shield: Callable,
	pilot_shield_damage_reduction: Callable,
	resolve_orb_proc: Callable
) -> Dictionary:
	var shots: Array = []
	var shot_count: int = int(weapon_data["shot_count"])
	for shot_index in range(shot_count):
		var hit_seed: int = seed + shot_index
		var part_seed: int = volley_part_seed(seed, shot_index)
		var shot: Dictionary = resolve_blockable_shot(
			attacker,
			target,
			preview,
			"",
			hit_seed,
			int(weapon_data["damage"]),
			part_seed,
			part_names,
			weapon_data,
			intercepting_shield_for,
			should_hit_shield,
			terrain_adjusted_damage,
			calculate_attack_damage,
			damage_part,
			damage_shield,
			pilot_shield_damage_reduction,
			resolve_orb_proc
		)
		shot["shot_index"] = shot_index + 1
		shots.append(shot)

	var total_damage: int = 0
	var any_hit: bool = false
	var primary_result: Dictionary = miss_damage_result(target, "Body")
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
	elif unit.get("weapon_required_parts", [unit.get("weapon_mount_part", "Right Arm")]).has(part_name):
		unit["weapon_disabled"] = true
	elif part_name == str(unit.get("off_hand_part", "Left Arm")):
		unit["off_hand_disabled"] = true
		if str(unit.get("off_hand", "")) == "Shield":
			unit["shield_disabled"] = true


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


func orb_effects(unit, part_names: Array, orb_data: Dictionary, effect_type := "") -> Array:
	var effects: Array = []
	for orb in active_orbs(unit, part_names, orb_data):
		for effect in orb["effects"]:
			if effect_type == "" or str(effect.get("type", "")) == effect_type:
				var active_effect: Dictionary = effect.duplicate(true)
				active_effect["orb_id"] = str(orb["id"])
				active_effect["element"] = str(orb["element"])
				active_effect["rarity"] = str(orb["rarity"])
				effects.append(active_effect)
	return effects


func orb_damage_modifier_percent(unit, part_names: Array, orb_data: Dictionary) -> int:
	var modifier: int = 0
	for effect in orb_effects(unit, part_names, orb_data, "damage_percent"):
		modifier += int(effect.get("percent", 0))
	return modifier


func orb_hit_modifier(unit, part_names: Array, orb_data: Dictionary) -> int:
	var modifier: int = 0
	for effect in orb_effects(unit, part_names, orb_data, "hit_bonus"):
		modifier += int(effect.get("amount", 0))
	return modifier


func orb_adjusted_damage(unit, damage: int, part_names: Array, orb_data: Dictionary) -> int:
	var modifier: int = orb_damage_modifier_percent(unit, part_names, orb_data)
	return int(round(float(max(0, damage)) * (100.0 + float(modifier)) / 100.0))


func apply_status(unit, status: String, turn_log: Array) -> bool:
	if unit == null or status == "":
		return false
	if not unit.has("statuses"):
		unit["statuses"] = []
	if not unit["statuses"].has(status):
		unit["statuses"].append(status)
		turn_log.append("%s:apply_status:%s" % [unit["id"], status])
	return true


func resolve_orb_proc(
	attacker,
	target,
	seed: int,
	part_names: Array,
	orb_data: Dictionary,
	pilot_orb_proc_bonus: Callable,
	turn_log: Array
) -> Dictionary:
	var proc_effects: Array = orb_effects(attacker, part_names, orb_data, "proc_status")
	var pilot_bonus: int = int(pilot_orb_proc_bonus.call(attacker))
	for index in range(proc_effects.size()):
		var effect: Dictionary = proc_effects[index]
		var chance: int = int(effect.get("chance_percent", 0)) + pilot_bonus
		if absi(seed + index * 37) % 100 < chance:
			var status: String = str(effect.get("status", ""))
			apply_status(target, status, turn_log)
			return {
				"triggered": true,
				"status": status,
				"orb_id": str(effect["orb_id"]),
				"seed": seed,
			}
	return empty_orb_proc(seed)


func empty_orb_proc(seed := 0) -> Dictionary:
	return {
		"triggered": false,
		"status": "",
		"orb_id": "",
		"seed": seed,
	}


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
