extends RefCounted
class_name BattleHud

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
