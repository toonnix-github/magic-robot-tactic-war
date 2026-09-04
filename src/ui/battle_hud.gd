extends RefCounted
class_name BattleHud


func current_unit(scene):
	if scene == null:
		return null
	if scene.active_unit != null:
		return scene.active_unit
	return scene.selected_unit


func inspected_unit(scene):
	if scene == null:
		return null
	if scene.get("inspected_unit") != null and scene.inspected_unit != null and scene.inspected_unit != current_unit(scene):
		return scene.inspected_unit
	if scene.selected_unit != null and scene.selected_unit != current_unit(scene):
		return scene.selected_unit
	return null


func draw_current_unit_panel(scene) -> void:
	var unit = current_unit(scene)
	if unit == null:
		return

	var rect: Rect2 = scene._r(30, 30, 235, 92)
	scene._draw_panel(rect)

	var portrait_center: Vector2 = scene._p(74, 76)
	var portrait_radius: float = min(28.0 * scene._scale().x, 28.0 * scene._scale().y)
	scene.draw_circle(portrait_center, portrait_radius, Color(0.18, 0.25, 0.29))
	scene.draw_arc(portrait_center, portrait_radius, 0.0, TAU, 40, Color(0.42, 0.50, 0.54), 2.0, true)
	scene._draw_centered_text(Rect2(portrait_center - Vector2(portrait_radius, portrait_radius), Vector2(portrait_radius * 2.0, portrait_radius * 2.0)), str(unit["letter"]), 16, Color(0.86, 0.90, 0.92))

	scene.draw_string(scene._font(), scene._p(115, 54), str(unit["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(18), Color(0.95, 0.97, 0.97))
	var passive: Dictionary = scene._pilot_passive_for(unit)
	var wep_desc: String = str(unit.get("weapon", ""))
	var handedness: String = str(scene.WEAPON_HANDEDNESS.get(wep_desc, ""))
	if handedness != "":
		wep_desc += " · " + handedness
	if bool(unit.get("weapon_disabled", false)):
		wep_desc += " (DIS)"

	var off_hand: String = str(unit.get("off_hand", ""))
	if off_hand != "":
		if bool(unit.get("off_hand_disabled", false)):
			off_hand += " (DIS)"
		wep_desc += " / " + off_hand

	var sub_text: String = "%s · %s" % [unit.get("mech", ""), wep_desc]
	scene.draw_string(scene._font(), scene._p(115, 72), sub_text, HORIZONTAL_ALIGNMENT_LEFT, 140.0 * scene._scale().x, scene._font_size(10), Color(0.62, 0.69, 0.73))
	if not passive.is_empty():
		scene.draw_string(scene._font(), scene._p(115, 87), str(passive.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.86, 0.77, 0.52))
	if scene._is_active_unit(unit):
		scene.draw_string(scene._font(), scene._p(222, 50), "ACTIVE", HORIZONTAL_ALIGNMENT_RIGHT, 30.0 * scene._scale().x, scene._font_size(9), Color(0.96, 0.86, 0.48))
	scene._draw_bar(scene._r(115, 96, 122, 8), scene._overall_hp_ratio(unit), Color(0.46, 0.65, 0.56))


func draw_selected_unit_panel(scene) -> void:
	draw_current_unit_panel(scene)


func draw_part_status_panel(scene) -> void:
	var unit = current_unit(scene)
	if unit == null:
		return

	var has_shield: bool = int(unit.get("shield_max_hp", 0)) > 0
	var panel_h: float = 142.0 if has_shield else 126.0
	scene._draw_panel(scene._r(30, 396, 235, panel_h))
	scene.draw_string(scene._font(), scene._p(48, 416), "PART STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), Color(0.56, 0.63, 0.67))
	var y: float = 436.0
	for part_name in scene.PART_NAMES:
		var part: Dictionary = unit["parts"][part_name]
		var p_hp: int = int(part.get("hp", 0))
		var destroyed: bool = bool(part.get("destroyed", false)) or p_hp <= 0
		var label_color: Color = Color(0.78, 0.82, 0.84) if not destroyed else Color(0.88, 0.48, 0.46)
		scene.draw_string(scene._font(), scene._p(48, y), short_part_name(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), label_color)
		if part.get("orb") != null:
			var orb_data: Dictionary = scene._orb_data_for(part["orb"])
			var elem: String = str(orb_data.get("element", ""))
			var orb_col: Color = Color(0.95, 0.50, 0.25) if elem == "Fire" else (Color(0.35, 0.65, 0.95) if elem == "Water" else (Color(0.95, 0.85, 0.25) if elem == "Lightning" else Color(0.65, 0.75, 0.45)))
			if destroyed or bool(part.get("orb_disabled", false)):
				orb_col = Color(0.40, 0.40, 0.40)
			scene.draw_circle(scene._p(40, y - 3.0), 2.5 * min(scene._scale().x, scene._scale().y), orb_col)
		scene._draw_bar(scene._r(96, y - 8.0, 68, 7), scene._part_hp_ratio(unit, part_name), Color(0.46, 0.65, 0.56) if not destroyed else Color(0.76, 0.32, 0.31))
		scene.draw_string(scene._font(), scene._p(170, y), part_hp_text(unit, part_name, scene.PART_MAX_HP), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), label_color)
		y += 15.0

	if has_shield:
		var s_hp: int = int(unit.get("shield_hp", 0))
		var s_max: int = int(unit.get("shield_max_hp", 0))
		var s_active: bool = scene._shield_is_active(unit)
		var s_col: Color = Color(0.53, 0.71, 0.75) if s_active else Color(0.76, 0.32, 0.31)
		scene.draw_string(scene._font(), scene._p(48, y), "Shield", HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), s_col)
		scene._draw_bar(scene._r(96, y - 8.0, 68, 7), float(s_hp) / float(s_max) if s_max > 0 else 0.0, Color(0.40, 0.60, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		scene.draw_string(scene._font(), scene._p(170, y), shield_hp_text(unit, Callable(scene, "_shield_is_active")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), s_col)


func inspect_target(scene, target) -> Dictionary:
	if target == null:
		return {}
	scene.inspected_unit = target
	scene.selected_unit = target
	if scene.active_unit != null:
		return scene._preview_attack_target(target)
	scene.queue_redraw()
	return {}


func inspect_unit(scene, unit) -> void:
	if unit == null:
		return
	if unit == current_unit(scene):
		scene.inspected_unit = null
	else:
		scene.inspected_unit = unit
	scene.selected_unit = unit
	if scene.active_unit != null and scene.turn_state == scene.TurnState.SELECTING_ATTACK:
		scene._preview_attack_target(unit)
	else:
		scene.queue_redraw()


func draw_inspected_unit_panel(scene) -> void:
	draw_enemy_inspection_panel(scene)


func draw_enemy_inspection_panel(scene) -> void:
	var target = inspected_unit(scene)
	if target == null or target == current_unit(scene):
		return

	scene._draw_panel(scene._r(960, 126, 310, 385))
	var data: Dictionary = scene._target_inspection_data(target)
	var is_enemy: bool = str(target.get("team", "")) == "enemy"
	var header_title: String = "TARGET INSPECTION" if scene.turn_state == scene.TurnState.SELECTING_ATTACK else ("ENEMY INTEL" if is_enemy else "ALLY INTEL")
	var header_color: Color = Color(0.85, 0.65, 0.40) if scene.turn_state == scene.TurnState.SELECTING_ATTACK else Color(0.56, 0.63, 0.67)
	scene.draw_string(scene._font(), scene._p(976, 148), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), header_color)

	scene.draw_string(scene._font(), scene._p(976, 170), str(target["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(16), Color(0.95, 0.97, 0.97))
	var wep_desc: String = str(target.get("weapon", ""))
	var handedness: String = str(scene.WEAPON_HANDEDNESS.get(wep_desc, ""))
	if handedness != "":
		wep_desc += " · " + handedness
	var off_hand: String = str(target.get("off_hand", ""))
	if off_hand != "":
		wep_desc += " / " + off_hand
	scene.draw_string(scene._font(), scene._p(976, 188), "%s · %s" % [target.get("mech", ""), wep_desc], HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(11), Color(0.62, 0.69, 0.73))
	scene.draw_string(scene._font(), scene._p(976, 204), str(data.get("terrain_desc", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), Color(0.70, 0.75, 0.77))

	var y: float = 220.0
	for part_name in scene.PART_NAMES:
		var p_info: Dictionary = data["parts"][part_name]
		var p_hp: int = int(p_info["hp"])
		var p_max: int = int(p_info["max_hp"])
		var destroyed: bool = bool(p_info["destroyed"])
		var label_col: Color = Color(0.78, 0.82, 0.84) if not destroyed else Color(0.88, 0.48, 0.46)
		scene.draw_string(scene._font(), scene._p(976, y), short_part_name(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), label_col)
		scene._draw_bar(scene._r(1030, y - 8.0, 130, 7), float(p_hp) / float(p_max) if p_max > 0 else 0.0, Color(0.46, 0.65, 0.56) if not destroyed else Color(0.76, 0.32, 0.31))
		scene.draw_string(scene._font(), scene._p(1170, y), part_hp_text(target, part_name, scene.PART_MAX_HP), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), label_col)
		y += 15.0

	if bool(data.get("has_shield", false)):
		var s_hp: int = int(data["shield_hp"])
		var s_max: int = int(data["shield_max_hp"])
		var s_active: bool = bool(data["shield_active"])
		scene.draw_string(scene._font(), scene._p(976, y), "Shield", HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), Color(0.53, 0.71, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		scene._draw_bar(scene._r(1030, y - 8.0, 130, 7), float(s_hp) / float(s_max) if s_max > 0 else 0.0, Color(0.40, 0.60, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		scene.draw_string(scene._font(), scene._p(1170, y), shield_hp_text(target, Callable(scene, "_shield_is_active")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.53, 0.71, 0.75) if s_active else Color(0.76, 0.32, 0.31))
		y += 15.0

	for consequence in data.get("consequences", []):
		scene.draw_string(scene._font(), scene._p(976, y), "! " + str(consequence), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.96, 0.76, 0.40))
		y += 13.0

	var statuses: Array = data.get("statuses", [])
	if not statuses.is_empty():
		scene.draw_string(scene._font(), scene._p(976, y), "Status: " + ", ".join(statuses), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.96, 0.58, 0.35))
		y += 13.0

	var orbs: Array = data.get("orbs", [])
	if not orbs.is_empty():
		scene.draw_string(scene._font(), scene._p(976, y), "Orbs: " + ", ".join(orbs), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.45, 0.75, 0.90))
		y += 13.0

	var pilot: Dictionary = data.get("pilot", {})
	if not pilot.is_empty():
		scene.draw_string(scene._font(), scene._p(976, y), "Pilot: %s · %s" % [str(pilot.get("name", "")), str(pilot.get("passive_name", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.85, 0.75, 0.95))
		y += 13.0

	if scene.turn_state == scene.TurnState.SELECTING_ATTACK and not data["attack_preview"].is_empty():
		var preview: Dictionary = data["attack_preview"]
		y += 4.0
		scene.draw_line(scene._p(976, y), scene._p(1250, y), Color(0.25, 0.33, 0.36), 1.0)
		y += 14.0
		var legal: bool = bool(preview["legal"])
		var hit: int = int(preview["hit_percent"])
		var dmg: int = int(preview["damage"])
		var h_mod: int = int(preview.get("height_hit_modifier", 0))
		var c_mod: int = int(preview.get("cover_dodge_modifier", 0))
		var pat: String = str(preview.get("weapon_pattern", "single"))
		var status_text: String = "LEGAL TARGET" if legal else "INVALID TARGET"
		var status_color: Color = Color(0.40, 0.78, 0.58) if legal else Color(0.88, 0.42, 0.42)
		scene.draw_string(scene._font(), scene._p(976, y), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), status_color)
		y += 14.0
		var mod_notes: String = ""
		if h_mod != 0:
			mod_notes += " (H%+d%%)" % h_mod
		if c_mod != 0:
			mod_notes += " (Cover %+d%%)" % c_mod
		scene.draw_string(scene._font(), scene._p(976, y), "Hit: %d%%%s · Est Dmg: %d" % [hit, mod_notes, dmg], HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(10), Color(0.93, 0.96, 0.96))
		y += 14.0
		scene.draw_string(scene._font(), scene._p(976, y), "Pattern: %s · Range: %d-%d" % [pat.to_upper(), int(preview.get("min_range", 1)), int(preview.get("range", 1))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.62, 0.69, 0.73))
		y += 14.0
		if str(data.get("shield_warning", "")) != "":
			scene.draw_string(scene._font(), scene._p(976, y), "! " + str(data["shield_warning"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, scene._font_size(9), Color(0.96, 0.86, 0.48))


func handle_hud_input(scene, tapped_unit) -> bool:
	if tapped_unit == null:
		return false
	if scene.turn_state == scene.TurnState.MOVE_PREVIEW:
		if scene._is_active_unit(tapped_unit):
			scene._cancel_move_preview()
			return true
		return false
	if scene.selected_action == "Attack" and scene.turn_state == scene.TurnState.SELECTING_ATTACK:
		if scene._is_active_unit(tapped_unit):
			scene._cancel_attack_selection()
		elif scene.selected_unit != null and scene.selected_unit["id"] == tapped_unit["id"] and scene._is_attack_target_legal(scene.active_unit, tapped_unit):
			scene._confirm_attack_target(tapped_unit)
		else:
			inspect_target(scene, tapped_unit)
		return true

	inspect_unit(scene, tapped_unit)
	return true


func part_hp_text(unit, part_name: String, part_max_hp: int) -> String:
	if unit == null or not unit.get("parts", {}).has(part_name):
		return "0 / 0"
	var part: Dictionary = unit["parts"][part_name]
	var hp := int(part.get("hp", 0))
	var max_hp := int(part.get("max_hp", part_max_hp))
	if bool(part.get("destroyed", false)) or hp <= 0:
		return "0 / %d DESTROYED" % max_hp
	return "%d / %d" % [hp, max_hp]


func shield_hp_text(unit, shield_is_active: Callable) -> String:
	if unit == null or int(unit.get("shield_max_hp", 0)) <= 0:
		return ""
	var hp := int(unit.get("shield_hp", 0))
	var max_hp := int(unit.get("shield_max_hp", 0))
	if hp <= 0 or not bool(shield_is_active.call(unit)):
		return "0 / %d BROKEN" % max_hp
	return "%d / %d" % [hp, max_hp]


func short_part_name(part_name: String) -> String:
	if part_name == "Left Arm":
		return "L Arm"
	if part_name == "Right Arm":
		return "R Arm"
	return part_name


func target_inspection_data(
	unit,
	active_unit,
	part_names: Array,
	part_max_hp: int,
	terrain: Dictionary,
	height: int,
	has_cover: bool,
	active_orbs: Array,
	pilot_data: Dictionary,
	attack_preview: Dictionary,
	shield_interceptor
) -> Dictionary:
	if unit == null:
		return {}

	var terrain_desc := "H%d" % height
	if has_cover:
		terrain_desc += " · Cover"

	var consequences: Array[String] = []
	if bool(unit.get("weapon_disabled", false)):
		consequences.append("Weapon disabled (%s)" % str(unit.get("weapon_mount_part", "Arm")))
	if int(unit.get("accuracy_modifier", 0)) < 0:
		consequences.append("Accuracy reduced (%+d%%)" % int(unit["accuracy_modifier"]))
	if int(unit.get("current_move_range", 0)) == 0 and bool(unit.get("parts", {}).get("Legs", {}).get("destroyed", false)):
		consequences.append("Legs destroyed: mobility lost")

	var part_details := {}
	for part_name in part_names:
		var part: Dictionary = unit["parts"].get(part_name, {})
		part_details[part_name] = {
			"hp": int(part.get("hp", 0)),
			"max_hp": int(part.get("max_hp", part_max_hp)),
			"destroyed": bool(part.get("destroyed", false)),
		}

	var orbs_info: Array[String] = []
	for orb in active_orbs:
		orbs_info.append("%s (%s)" % [str(orb.get("name", orb.get("id", ""))), str(orb.get("element", ""))])

	var statuses_info: Array[String] = []
	for st in unit.get("statuses", []):
		if st is Dictionary:
			statuses_info.append(str(st.get("name", st.get("id", ""))))
		else:
			statuses_info.append(str(st))

	var pilot_info := {}
	if not pilot_data.is_empty():
		var p_passive: Dictionary = pilot_data.get("passive", {})
		pilot_info = {
			"id": str(pilot_data.get("id", "")),
			"name": str(pilot_data.get("name", "")),
			"title": str(pilot_data.get("title", "")),
			"passive_name": str(p_passive.get("name", "")),
			"passive_desc": str(p_passive.get("desc", "")),
		}

	var data := {
		"id": str(unit.get("id", "")),
		"name": str(unit.get("name", "")),
		"mech": str(unit.get("mech", "")),
		"weapon": str(unit.get("weapon", "")),
		"team": str(unit.get("team", "")),
		"grid": unit["grid"],
		"height": height,
		"has_cover": has_cover,
		"terrain": terrain,
		"terrain_desc": terrain_desc,
		"consequences": consequences,
		"parts": part_details,
		"shield_hp": int(unit.get("shield_hp", 0)),
		"shield_max_hp": int(unit.get("shield_max_hp", 0)),
		"has_shield": int(unit.get("shield_max_hp", 0)) > 0,
		"shield_active": int(unit.get("shield_hp", 0)) > 0 and not bool(unit.get("shield_disabled", false)),
		"statuses": statuses_info,
		"orbs": orbs_info,
		"pilot": pilot_info,
		"attack_preview": {},
		"shield_interceptor": null,
		"shield_warning": "",
	}

	if active_unit != null and str(active_unit.get("id", "")) != str(unit.get("id", "")):
		data["attack_preview"] = attack_preview
		data["shield_interceptor"] = shield_interceptor
		if shield_interceptor != null:
			data["shield_warning"] = "Protected by %s's Shield" % str(shield_interceptor.get("name", "Ally"))

	return data


func draw_action_bar(scene) -> void:
	var bar_rect: Rect2 = scene._r(888, 521, 390, 62)
	scene._draw_panel(bar_rect)
	scene.action_rects.clear()

	if scene.turn_state == scene.TurnState.MOVE_PREVIEW:
		scene.move_confirm_rect = scene._r(906, 533, 205, 38)
		scene.move_cancel_rect = scene._r(1123, 533, 137, 38)

		scene.draw_rect(scene.move_confirm_rect, Color(0.18, 0.42, 0.32), true)
		scene.draw_rect(scene.move_confirm_rect, Color(0.40, 0.78, 0.58), false, 2.0)
		scene._draw_centered_text(scene.move_confirm_rect, "CONFIRM MOVE", 13, Color(0.95, 0.98, 0.96))

		scene.draw_rect(scene.move_cancel_rect, Color(0.38, 0.22, 0.22), true)
		scene.draw_rect(scene.move_cancel_rect, Color(0.72, 0.42, 0.42), false, 1.5)
		scene._draw_centered_text(scene.move_cancel_rect, "CANCEL", 13, Color(0.95, 0.90, 0.90))
		return

	scene.move_confirm_rect = Rect2()
	scene.move_cancel_rect = Rect2()
	var widths: Array[float] = [104.0, 104.0, 124.0]
	var x: float = 906.0
	for index in range(scene.PRIMARY_ACTIONS.size()):
		var action: String = scene.PRIMARY_ACTIONS[index]
		var rect: Rect2 = scene._r(x, 533, widths[index], 38)
		scene.action_rects[action] = rect
		var active: bool = action == scene.selected_action
		var legal: bool = scene._is_action_legal(action)
		var color: Color = Color(0.16, 0.27, 0.30) if action == "Move" else Color(0.42, 0.24, 0.24) if action == "Attack" else Color(0.16, 0.20, 0.23)
		if active:
			color = color.lightened(0.18)
		if not legal:
			color = Color(0.12, 0.15, 0.16)
		scene.draw_rect(rect, color, true)
		scene.draw_rect(rect, Color(0.41, 0.53, 0.58) if active and legal else Color(0.32, 0.39, 0.42), false, 1.5)
		scene._draw_centered_text(rect, action.to_upper(), 13, Color(0.93, 0.96, 0.96) if legal else Color(0.48, 0.54, 0.56))
		x += widths[index] + 11.0
