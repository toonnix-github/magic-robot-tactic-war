extends RefCounted
class_name MechBuildModel

const REQUIRED_PARTS := ["Head", "Body", "Left Arm", "Right Arm", "Legs"]
const WEAPON_ARM := "Right Arm"
const OFF_HAND_ARM := "Left Arm"

const WEAPON_HANDEDNESS := {
	"Sword": "1H",
	"Rifle": "1H",
	"Spear": "2H",
	"Sniper": "2H",
}

const OFF_HAND_EQUIPMENT_DATA := {
	"Shield": {
		"id": "Shield",
		"name": "Shield",
		"slot": OFF_HAND_ARM,
		"shield_max_hp": 25,
		"shield_hit_weight": 55,
	},
}

const PART_CATALOG := {
	"Head": {
		"aegis_head": {"name": "Aegis Head", "max_hp": 100, "accuracy": 0, "defense": 0, "speed": 0, "move": 0, "dodge": 0},
		"longview_head": {"name": "Longview Optics", "max_hp": 76, "accuracy": 10, "defense": 0, "speed": 0, "move": 0, "dodge": 0},
		"bulwark_head": {"name": "Bulwark Crown", "max_hp": 122, "accuracy": -5, "defense": 4, "speed": -1, "move": 0, "dodge": 0},
		"volt_head": {"name": "Volt Sensor", "max_hp": 88, "accuracy": 5, "defense": -2, "speed": 1, "move": 0, "dodge": 0},
	},
	"Body": {
		"aegis_body": {"name": "Aegis Core", "max_hp": 110, "accuracy": 0, "defense": 2, "speed": 0, "move": 0, "dodge": 0},
		"longview_body": {"name": "Longview Frame", "max_hp": 92, "accuracy": 4, "defense": -1, "speed": 1, "move": 0, "dodge": 0},
		"bulwark_body": {"name": "Bulwark Plating", "max_hp": 138, "accuracy": -3, "defense": 7, "speed": -2, "move": -1, "dodge": -2},
		"volt_body": {"name": "Volt Reactor", "max_hp": 86, "accuracy": 0, "defense": -2, "speed": 2, "move": 1, "dodge": 2},
	},
	"Left Arm": {
		"aegis_left_arm": {"name": "Aegis Left Arm", "max_hp": 100, "accuracy": 0, "defense": 1, "speed": 0, "move": 0, "dodge": 0},
		"longview_left_arm": {"name": "Longview Brace", "max_hp": 78, "accuracy": 6, "defense": -1, "speed": 1, "move": 0, "dodge": 0},
		"bulwark_left_arm": {"name": "Bulwark Guard Arm", "max_hp": 126, "accuracy": -4, "defense": 5, "speed": -1, "move": 0, "dodge": -1},
		"guard_left_arm": {"name": "Guard Utility Arm", "max_hp": 112, "accuracy": -1, "defense": 4, "speed": 0, "move": 0, "dodge": 0},
		"volt_left_arm": {"name": "Volt Relay Arm", "max_hp": 84, "accuracy": 3, "defense": -1, "speed": 1, "move": 0, "dodge": 1},
	},
	"Right Arm": {
		"aegis_right_arm": {"name": "Aegis Weapon Arm", "max_hp": 104, "accuracy": 1, "defense": 0, "speed": 0, "move": 0, "dodge": 0},
		"longview_right_arm": {"name": "Longview Steady Arm", "max_hp": 80, "accuracy": 8, "defense": -1, "speed": 0, "move": 0, "dodge": 0},
		"bulwark_right_arm": {"name": "Bulwark Heavy Arm", "max_hp": 128, "accuracy": -5, "defense": 4, "speed": -1, "move": 0, "dodge": -1},
		"volt_right_arm": {"name": "Volt Trigger Arm", "max_hp": 86, "accuracy": 4, "defense": -2, "speed": 1, "move": 0, "dodge": 1},
	},
	"Legs": {
		"aegis_legs": {"name": "Aegis Legs", "max_hp": 100, "accuracy": 0, "defense": 0, "speed": 0, "move": 0, "dodge": 0},
		"longview_legs": {"name": "Longview Stabilizers", "max_hp": 82, "accuracy": 3, "defense": 0, "speed": 0, "move": 0, "dodge": 4},
		"bulwark_legs": {"name": "Bulwark Treads", "max_hp": 132, "accuracy": -2, "defense": 3, "speed": -2, "move": -1, "dodge": -4},
		"sprinter_legs": {"name": "Sprinter Legs", "max_hp": 72, "accuracy": 0, "defense": -2, "speed": 2, "move": 1, "dodge": 6},
		"volt_legs": {"name": "Volt Striders", "max_hp": 84, "accuracy": 0, "defense": -1, "speed": 2, "move": 1, "dodge": 4},
	},
}

const PROTOTYPE_MECH_BUILDS := {
	"arlen": {
		"unit_id": "arlen",
		"pilot": "arlen",
		"mech": "Aegis-07",
		"parts": {
			"Head": "aegis_head",
			"Body": "aegis_body",
			"Left Arm": "aegis_left_arm",
			"Right Arm": "aegis_right_arm",
			"Legs": "aegis_legs",
		},
		"weapon": "Spear",
		"off_hand": "",
		"orbs": {
			"Right Arm": "fire_n",
		},
	},
	"mira": {
		"unit_id": "mira",
		"pilot": "mira",
		"mech": "Longview-02",
		"parts": {
			"Head": "longview_head",
			"Body": "longview_body",
			"Left Arm": "longview_left_arm",
			"Right Arm": "longview_right_arm",
			"Legs": "longview_legs",
		},
		"weapon": "Sniper",
		"off_hand": "",
		"orbs": {
			"Head": "lightning_r",
			"Right Arm": "water_r",
		},
	},
	"sera": {
		"unit_id": "sera",
		"pilot": "sera",
		"mech": "Volt-13",
		"parts": {
			"Head": "volt_head",
			"Body": "volt_body",
			"Left Arm": "volt_left_arm",
			"Right Arm": "volt_right_arm",
			"Legs": "volt_legs",
		},
		"weapon": "Rifle",
		"off_hand": "",
		"orbs": {
			"Right Arm": "fire_sr",
		},
	},
	"brann": {
		"unit_id": "brann",
		"pilot": "brann",
		"mech": "Bulwark-04",
		"parts": {
			"Head": "bulwark_head",
			"Body": "bulwark_body",
			"Left Arm": "bulwark_left_arm",
			"Right Arm": "bulwark_right_arm",
			"Legs": "bulwark_legs",
		},
		"weapon": "Sword",
		"off_hand": "Shield",
		"orbs": {
			"Left Arm": "earth_ssr",
		},
	},
}


func prototype_builds() -> Dictionary:
	return PROTOTYPE_MECH_BUILDS.duplicate(true)


func weapon_handedness(weapon_name: String) -> String:
	return str(WEAPON_HANDEDNESS.get(weapon_name, ""))


func part_catalog(part_name: String = "") -> Array:
	if part_name != "":
		var slot_catalog: Dictionary = PART_CATALOG.get(part_name, {})
		return _catalog_values(part_name, slot_catalog)

	var all_options: Array = []
	for slot_name in REQUIRED_PARTS:
		all_options.append_array(part_catalog(slot_name))
	return all_options


func build_stats(build: Dictionary) -> Dictionary:
	var stats := {
		"max_hp": 0,
		"accuracy": 0,
		"defense": 0,
		"speed": 0,
		"move": 3,
		"dodge": 10,
		"part_hp": {},
	}
	var parts: Dictionary = build.get("parts", {})
	for part_name in REQUIRED_PARTS:
		var part_id := str(parts.get(part_name, ""))
		var part_data: Dictionary = _part_data(part_name, part_id)
		var hp: int = int(part_data.get("max_hp", 0))
		stats["part_hp"][part_name] = hp
		stats["max_hp"] = int(stats["max_hp"]) + hp
		for stat_name in ["accuracy", "defense", "speed", "move", "dodge"]:
			stats[stat_name] = int(stats[stat_name]) + int(part_data.get(stat_name, 0))
	return stats


func part_delta(build: Dictionary, part_name: String, candidate_part_id: String, part_names: Array = []) -> Dictionary:
	var parts: Array = _part_names(part_names)
	var current_parts: Dictionary = build.get("parts", {})
	var current_part_id := str(current_parts.get(part_name, ""))
	var before_stats: Dictionary = build_stats(build)
	var swapped: Dictionary = swap_part(build, part_name, candidate_part_id, parts)
	var after_stats: Dictionary = build_stats(swapped)
	var before_part: Dictionary = _part_data(part_name, current_part_id)
	var after_part: Dictionary = _part_data(part_name, candidate_part_id)
	var stat_delta := {
		"max_hp": int(after_part.get("max_hp", 0)) - int(before_part.get("max_hp", 0)),
		"accuracy": int(after_stats["accuracy"]) - int(before_stats["accuracy"]),
		"defense": int(after_stats["defense"]) - int(before_stats["defense"]),
		"speed": int(after_stats["speed"]) - int(before_stats["speed"]),
		"move": int(after_stats["move"]) - int(before_stats["move"]),
		"dodge": int(after_stats["dodge"]) - int(before_stats["dodge"]),
	}
	var display_lines: Array[String] = []
	if int(stat_delta["max_hp"]) != 0:
		display_lines.append("%s HP %d -> %d" % [part_name, int(before_part.get("max_hp", 0)), int(after_part.get("max_hp", 0))])
	for stat_name in ["move", "speed", "dodge", "accuracy", "defense"]:
		if int(stat_delta[stat_name]) != 0:
			display_lines.append("%s %d -> %d" % [_stat_label(stat_name), int(before_stats[stat_name]), int(after_stats[stat_name])])

	return {
		"part_name": part_name,
		"from_part": current_part_id,
		"to_part": candidate_part_id,
		"from_name": str(before_part.get("name", current_part_id)),
		"to_name": str(after_part.get("name", candidate_part_id)),
		"stat_delta": stat_delta,
		"display_lines": display_lines,
		"valid": parts.has(part_name) and not after_part.is_empty(),
	}


func swap_part(build: Dictionary, part_name: String, candidate_part_id: String, part_names: Array = []) -> Dictionary:
	var swapped: Dictionary = build.duplicate(true)
	var parts: Array = _part_names(part_names)
	if not parts.has(part_name) or _part_data(part_name, candidate_part_id).is_empty():
		return swapped
	if not swapped.has("parts") or not (swapped["parts"] is Dictionary):
		swapped["parts"] = {}
	swapped["parts"][part_name] = candidate_part_id
	return swapped


func strictly_superior_options(part_name: String) -> Array:
	var options: Array = part_catalog(part_name)
	var superior: Array[String] = []
	for candidate in options:
		var candidate_id := str(candidate.get("id", ""))
		for other in options:
			var other_id := str(other.get("id", ""))
			if candidate_id == other_id:
				continue
			if _is_strictly_superior(candidate, other):
				superior.append(candidate_id)
				break
	return superior


func normalize_build(
	build: Dictionary,
	weapon_data: Dictionary,
	orb_data: Dictionary,
	part_names: Array = []
) -> Dictionary:
	var normalized: Dictionary = build.duplicate(true)
	var parts: Array = _part_names(part_names)
	if not normalized.has("parts") or not (normalized["parts"] is Dictionary):
		normalized["parts"] = {}
	if not normalized.has("orbs") or not (normalized["orbs"] is Dictionary):
		normalized["orbs"] = {}
	if not normalized.has("off_hand"):
		normalized["off_hand"] = ""

	var weapon_name := str(normalized.get("weapon", ""))
	if weapon_handedness(weapon_name) == "2H":
		normalized["off_hand"] = ""

	var cleaned_orbs := {}
	var source_orbs: Dictionary = normalized["orbs"]
	for part_name in parts:
		var orb_id := str(source_orbs.get(part_name, ""))
		if orb_id != "" and orb_data.has(orb_id):
			cleaned_orbs[part_name] = orb_id
	normalized["orbs"] = cleaned_orbs

	if not normalized.has("pilot"):
		normalized["pilot"] = str(normalized.get("unit_id", ""))
	return normalized


func validate_build(
	build: Dictionary,
	weapon_data: Dictionary,
	orb_data: Dictionary,
	part_names: Array = []
) -> Dictionary:
	var errors: Array[String] = []
	var parts: Array = _part_names(part_names)

	var weapon_name := str(build.get("weapon", ""))
	if weapon_name == "":
		errors.append("build must equip exactly one weapon")
	elif weapon_handedness(weapon_name) == "":
		errors.append("%s is not a Phase 2 weapon" % weapon_name)
	elif not weapon_data.has(weapon_name):
		errors.append("weapon data missing for %s" % weapon_name)

	var off_hand := str(build.get("off_hand", ""))
	if off_hand != "" and not OFF_HAND_EQUIPMENT_DATA.has(off_hand):
		errors.append("unknown off-hand equipment: %s" % off_hand)
	if off_hand != "" and weapon_handedness(weapon_name) == "2H":
		errors.append("2H weapons disable off-hand equipment")

	if not build.has("parts") or not (build["parts"] is Dictionary):
		errors.append("build must configure mech parts")
	else:
		var configured_parts: Dictionary = build["parts"]
		for part_name in parts:
			if not configured_parts.has(part_name):
				errors.append("missing mech part: %s" % part_name)
			elif str(configured_parts[part_name]) == "":
				errors.append("empty mech part id: %s" % part_name)
			elif _part_data(part_name, str(configured_parts[part_name])).is_empty():
				errors.append("unknown %s part: %s" % [part_name, str(configured_parts[part_name])])
		for configured_part in configured_parts.keys():
			if not parts.has(str(configured_part)):
				errors.append("unknown mech part slot: %s" % str(configured_part))

	if build.has("orbs"):
		if not (build["orbs"] is Dictionary):
			errors.append("orbs must be keyed by mech part")
		else:
			var configured_orbs: Dictionary = build["orbs"]
			for part_name in configured_orbs.keys():
				var part_key := str(part_name)
				var orb_id := str(configured_orbs[part_name])
				if not parts.has(part_key):
					errors.append("Orb assigned to unknown part: %s" % part_key)
				elif orb_id != "" and not orb_data.has(orb_id):
					errors.append("unknown Orb: %s" % orb_id)

	if str(build.get("pilot", "")) == "":
		errors.append("pilot passive identity must be separate and explicit")
	if build.has("pilot_commands") or build.has("active_pilot_commands"):
		errors.append("pilot passives must not add active pilot commands")

	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


func build_summary(
	build: Dictionary,
	weapon_data: Dictionary,
	orb_data: Dictionary,
	part_names: Array = []
) -> Dictionary:
	var normalized: Dictionary = normalize_build(build, weapon_data, orb_data, part_names)
	var parts: Array = _part_names(part_names)
	var weapon_name := str(normalized.get("weapon", ""))
	var handedness := weapon_handedness(weapon_name)
	var off_hand := str(normalized.get("off_hand", ""))
	var off_hand_data: Dictionary = OFF_HAND_EQUIPMENT_DATA.get(off_hand, {})
	var required_weapon_parts: Array[String] = [WEAPON_ARM]
	if handedness == "2H":
		required_weapon_parts = [OFF_HAND_ARM, WEAPON_ARM]

	return {
		"unit_id": str(normalized.get("unit_id", "")),
		"pilot_id": str(normalized.get("pilot", "")),
		"mech": str(normalized.get("mech", "")),
		"parts": normalized.get("parts", {}).duplicate(true),
		"weapon": weapon_name,
		"weapon_handedness": handedness,
		"weapon_arm": WEAPON_ARM if handedness == "1H" else ("Both Arms" if handedness == "2H" else ""),
		"weapon_required_parts": required_weapon_parts,
		"uses_both_arms": handedness == "2H",
		"off_hand": off_hand,
		"off_hand_slot": OFF_HAND_ARM,
		"off_hand_slot_enabled": handedness == "1H",
		"off_hand_equipment": off_hand_data.duplicate(true),
		"has_shield": off_hand == "Shield",
		"shield_max_hp": int(off_hand_data.get("shield_max_hp", 0)),
		"orb_slots": _orb_slots(normalized, parts),
		"validation": validate_build(normalized, weapon_data, orb_data, parts),
	}


func battle_loadout_for_build(
	build: Dictionary,
	weapon_data: Dictionary,
	orb_data: Dictionary,
	part_names: Array = []
) -> Dictionary:
	var summary: Dictionary = build_summary(build, weapon_data, orb_data, part_names)
	return {
		"pilot": str(summary["pilot_id"]),
		"weapon": str(summary["weapon"]),
		"off_hand": str(summary["off_hand"]),
		"has_shield": bool(summary["has_shield"]),
		"shield_max_hp": int(summary["shield_max_hp"]),
		"weapon_mount_part": WEAPON_ARM,
		"weapon_required_parts": summary["weapon_required_parts"].duplicate(true),
		"clear_orbs": true,
		"orbs": _equipped_orbs(summary["orb_slots"]),
		"parts": summary["parts"].duplicate(true),
	}


func _part_names(part_names: Array) -> Array:
	if part_names.is_empty():
		return REQUIRED_PARTS.duplicate()
	return part_names.duplicate()


func _orb_slots(build: Dictionary, part_names: Array) -> Dictionary:
	var slots := {}
	var equipped_orbs: Dictionary = build.get("orbs", {})
	for part_name in part_names:
		slots[part_name] = str(equipped_orbs.get(part_name, ""))
	return slots


func _equipped_orbs(orb_slots: Dictionary) -> Dictionary:
	var equipped := {}
	for part_name in orb_slots.keys():
		var orb_id := str(orb_slots[part_name])
		if orb_id != "":
			equipped[part_name] = orb_id
	return equipped


func _catalog_values(part_name: String, slot_catalog: Dictionary) -> Array:
	var values: Array = []
	for part_id in slot_catalog.keys():
		var item: Dictionary = slot_catalog[part_id].duplicate(true)
		item["id"] = str(part_id)
		item["part_name"] = part_name
		values.append(item)
	values.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))
	return values


func _part_data(part_name: String, part_id: String) -> Dictionary:
	var slot_catalog: Dictionary = PART_CATALOG.get(part_name, {})
	if not slot_catalog.has(part_id):
		return {}
	var item: Dictionary = slot_catalog[part_id].duplicate(true)
	item["id"] = part_id
	item["part_name"] = part_name
	return item


func _is_strictly_superior(candidate: Dictionary, other: Dictionary) -> bool:
	var has_better_stat := false
	for stat_name in ["max_hp", "accuracy", "defense", "speed", "move", "dodge"]:
		var candidate_value: int = int(candidate.get(stat_name, 0))
		var other_value: int = int(other.get(stat_name, 0))
		if candidate_value < other_value:
			return false
		if candidate_value > other_value:
			has_better_stat = true
	return has_better_stat


func _stat_label(stat_name: String) -> String:
	if stat_name == "max_hp":
		return "HP"
	return stat_name.capitalize()

func install_orb(build: Dictionary, part_name: String, orb_id: String, part_names: Array = []) -> Dictionary:
	var updated = build.duplicate(true)
	if not updated.has("orbs") or not (updated["orbs"] is Dictionary):
		updated["orbs"] = {}
	updated["orbs"][part_name] = orb_id
	return updated

func remove_orb(build: Dictionary, part_name: String, part_names: Array = []) -> Dictionary:
	var updated = build.duplicate(true)
	if updated.has("orbs") and (updated["orbs"] is Dictionary):
		updated["orbs"].erase(part_name)
	return updated
