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
