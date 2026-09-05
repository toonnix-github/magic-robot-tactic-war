extends MarginContainer

const AssemblyViewScript := preload("res://src/ui/mech_assembly_view.gd")
const WEAPONS := ["Sword", "Rifle", "Spear", "Sniper"]
const SLOTS := ["Head", "Body", "Left Arm", "Right Arm", "Legs"]

var hangar
var mech_view
var unit_select := OptionButton.new()
var weapon_select := OptionButton.new()
var shield_toggle := CheckBox.new()
var orb_select := OptionButton.new()
var deploy_button := Button.new()
var equip_button := Button.new()
var cancel_button := Button.new()
var comparison := RichTextLabel.new()
var weapon_details := RichTextLabel.new()
var orb_details := RichTextLabel.new()
var stat_breakdown := RichTextLabel.new()
var title := Label.new()
var slot_title := Label.new()
var equipped_label := Label.new()
var overview := Label.new()
var candidate_grid := GridContainer.new()
var candidate_id := ""
var candidates: Dictionary = {}
var review_overlay := PanelContainer.new()
var review_text := RichTextLabel.new()
var mission_select := OptionButton.new()
var confirm_deploy_button := Button.new()
var close_review_button := Button.new()
var selected_mission_id := "ancient_ruins"
var mission_ids: Array[String] = []

var unit_tab_buttons: Array[Button] = []
var slot_tab_buttons: Dictionary = {}


func setup(model) -> void:
	hangar = model
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 16)
	theme = _theme()

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	# --- TOP HEADER BAR: FM3 Style Unit Navigation ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	var brand := Label.new()
	brand.text = "WANZER HANGAR"
	brand.add_theme_font_size_override("font_size", 20)
	brand.add_theme_color_override("font_color", Color("38d9a9"))
	header.add_child(brand)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer1)

	# Unit Switcher Tabs
	var unit_nav := HBoxContainer.new()
	unit_nav.add_theme_constant_override("separation", 6)
	header.add_child(unit_nav)

	var prev_btn := Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(34, 38)
	prev_btn.pressed.connect(_prev_unit)
	unit_nav.add_child(prev_btn)

	for i in range(hangar.UNIT_IDS.size()):
		var id: String = hangar.UNIT_IDS[i]
		var btn := Button.new()
		btn.text = id.capitalize()
		btn.custom_minimum_size = Vector2(88, 38)
		btn.pressed.connect(_select_unit.bind(i))
		unit_nav.add_child(btn)
		unit_tab_buttons.append(btn)

	var next_btn := Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(34, 38)
	next_btn.pressed.connect(_next_unit)
	unit_nav.add_child(next_btn)

	# Hidden dropdown for automated tests compatibility
	unit_select.visible = false
	for id in hangar.UNIT_IDS:
		unit_select.add_item(str(id).capitalize())
	header.add_child(unit_select)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer2)

	deploy_button.text = "Deploy Squad  >"
	deploy_button.custom_minimum_size = Vector2(170, 38)
	header.add_child(deploy_button)

	# --- 3-COLUMN MAIN BODY: Setup Inspector | Mech Bay | Authoritative Telemetry ---
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 16)
	split.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(split)

	# 1. LEFT COLUMN: Part & Gear Inspector (Front Mission 3 Hierarchy)
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size.x = 390
	left_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 1.05
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = Color("0d1514")
	left_style.border_color = Color("233b34")
	left_style.set_border_width_all(1)
	left_style.set_corner_radius_all(4)
	left_style.content_margin_left = 12
	left_style.content_margin_right = 12
	left_style.content_margin_top = 10
	left_style.content_margin_bottom = 10
	left_panel.add_theme_stylebox_override("panel", left_style)
	split.add_child(left_panel)

	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	inspector_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	left_panel.add_child(inspector_scroll)

	var inspector := VBoxContainer.new()
	inspector.size_flags_horizontal = SIZE_EXPAND_FILL
	inspector.add_theme_constant_override("separation", 10)
	inspector_scroll.add_child(inspector)

	# Part Slot Tabs (Head, Body, Left Arm, Right Arm, Legs)
	var slot_header := Label.new()
	slot_header.text = "PART SELECTION"
	slot_header.add_theme_font_size_override("font_size", 14)
	slot_header.add_theme_color_override("font_color", Color("74a89b"))
	inspector.add_child(slot_header)

	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 4)
	inspector.add_child(slot_row)
	for slot_name in SLOTS:
		var slot_btn := Button.new()
		slot_btn.text = slot_name.replace(" Arm", "")
		slot_btn.tooltip_text = slot_name
		slot_btn.size_flags_horizontal = SIZE_EXPAND_FILL
		slot_btn.custom_minimum_size.y = 32
		slot_btn.pressed.connect(_select_slot.bind(slot_name))
		slot_row.add_child(slot_btn)
		slot_tab_buttons[slot_name] = slot_btn

	inspector.add_child(HSeparator.new())

	# Section 1: Frame Tuning
	slot_title.add_theme_font_size_override("font_size", 18)
	slot_title.add_theme_color_override("font_color", Color("e0ece8"))
	inspector.add_child(slot_title)

	equipped_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipped_label.add_theme_color_override("font_color", Color("8faea4"))
	equipped_label.add_theme_font_size_override("font_size", 13)
	inspector.add_child(equipped_label)

	candidate_grid.columns = 2
	candidate_grid.add_theme_constant_override("h_separation", 6)
	candidate_grid.add_theme_constant_override("v_separation", 6)
	inspector.add_child(candidate_grid)

	comparison.bbcode_enabled = true
	comparison.fit_content = true
	comparison.scroll_active = false
	comparison.custom_minimum_size.y = 48
	inspector.add_child(comparison)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	inspector.add_child(actions)
	equip_button.text = "Equip Frame"
	equip_button.custom_minimum_size.y = 36
	equip_button.size_flags_horizontal = SIZE_EXPAND_FILL
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 36)
	actions.add_child(equip_button)
	actions.add_child(cancel_button)

	inspector.add_child(HSeparator.new())

	# Section 2: Socketed Orb on this Part (Unified Part & Orb Tuning!)
	var orb_section_lbl := Label.new()
	orb_section_lbl.text = "SOCKETED ORB"
	orb_section_lbl.add_theme_font_size_override("font_size", 14)
	orb_section_lbl.add_theme_color_override("font_color", Color("74a89b"))
	inspector.add_child(orb_section_lbl)

	_row(inspector, "Orb", orb_select)
	_setup_detail_label(orb_details)
	inspector.add_child(orb_details)

	inspector.add_child(HSeparator.new())

	# Section 3: Weapon & Off-Hand
	var gear_section_lbl := Label.new()
	gear_section_lbl.text = "ARMAMENT"
	gear_section_lbl.add_theme_font_size_override("font_size", 14)
	gear_section_lbl.add_theme_color_override("font_color", Color("74a89b"))
	inspector.add_child(gear_section_lbl)

	for weapon in WEAPONS:
		var profile: Dictionary = hangar.build_model.weapon_profile(weapon, hangar.GameDataScript.WEAPON_DATA)
		weapon_select.add_item("%s / R%d-%d / %s / %s" % [weapon, profile["range_min"], profile["range_max"], profile["handedness"], profile["pattern_short"]])
	_row(inspector, "Weapon", weapon_select)
	_setup_detail_label(weapon_details)
	inspector.add_child(weapon_details)

	shield_toggle.text = "Shield"
	_row(inspector, "Left Hand", shield_toggle)

	# 2. CENTER COLUMN: Mech Bay (Visual Representation)
	var center_col := VBoxContainer.new()
	center_col.size_flags_horizontal = SIZE_EXPAND_FILL
	center_col.size_flags_stretch_ratio = 1.15
	center_col.add_theme_constant_override("separation", 6)
	split.add_child(center_col)

	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("ffffff"))
	center_col.add_child(title)

	overview.text = ""
	overview.visible = false
	center_col.add_child(overview)

	mech_view = AssemblyViewScript.new()
	center_col.add_child(mech_view)
	mech_view.part_selected.connect(_select_slot)

	# 3. RIGHT COLUMN: Authoritative Telemetry / Stats Window (Pure Numbers + Skills)
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size.x = 340
	right_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.0
	var right_style := StyleBoxFlat.new()
	right_style.bg_color = Color("0a1110")
	right_style.border_color = Color("28453d")
	right_style.set_border_width_all(1)
	right_style.set_corner_radius_all(4)
	right_style.content_margin_left = 14
	right_style.content_margin_right = 14
	right_style.content_margin_top = 12
	right_style.content_margin_bottom = 12
	right_panel.add_theme_stylebox_override("panel", right_style)
	split.add_child(right_panel)

	var stat_scroll := ScrollContainer.new()
	stat_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	stat_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	right_panel.add_child(stat_scroll)

	var stat_box := VBoxContainer.new()
	stat_box.size_flags_horizontal = SIZE_EXPAND_FILL
	stat_box.add_theme_constant_override("separation", 8)
	stat_scroll.add_child(stat_box)

	var telemetry_hdr := Label.new()
	telemetry_hdr.text = "AUTHORITATIVE TELEMETRY"
	telemetry_hdr.add_theme_font_size_override("font_size", 16)
	telemetry_hdr.add_theme_color_override("font_color", Color("38d9a9"))
	stat_box.add_child(telemetry_hdr)
	stat_box.add_child(HSeparator.new())

	stat_breakdown.bbcode_enabled = true
	stat_breakdown.fit_content = true
	stat_breakdown.scroll_active = false
	stat_breakdown.add_theme_font_size_override("normal_font_size", 13)
	stat_box.add_child(stat_breakdown)

	# Wire signals
	unit_select.item_selected.connect(_select_unit)
	weapon_select.item_selected.connect(_select_weapon)
	shield_toggle.toggled.connect(_select_shield)
	orb_select.item_selected.connect(_select_orb)
	deploy_button.pressed.connect(_open_squad_review)
	equip_button.pressed.connect(_equip)
	cancel_button.pressed.connect(_cancel)

	_build_review_overlay()
	refresh()


func _setup_detail_label(label: RichTextLabel) -> void:
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("normal_font_size", 12)


func _build_review_overlay() -> void:
	review_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	review_overlay.visible = false
	var review_style := StyleBoxFlat.new()
	review_style.bg_color = Color("08100f")
	review_style.border_color = Color("38d9a9")
	review_style.set_border_width_all(1)
	review_style.content_margin_left = 16
	review_style.content_margin_right = 16
	review_style.content_margin_top = 12
	review_style.content_margin_bottom = 12
	review_overlay.add_theme_stylebox_override("panel", review_style)
	add_child(review_overlay)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	review_overlay.add_child(content)

	var heading := Label.new()
	heading.text = "SQUAD DEPLOYMENT REVIEW"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("38d9a9"))
	content.add_child(heading)

	var mission_row := HBoxContainer.new()
	content.add_child(mission_row)
	var mission_label := Label.new()
	mission_label.text = "Target Mission:"
	mission_label.custom_minimum_size.x = 110
	mission_row.add_child(mission_label)
	for mission_id in hangar.GameDataScript.MISSIONS_DATA.keys():
		mission_ids.append(str(mission_id))
		mission_select.add_item(str(hangar.GameDataScript.MISSIONS_DATA[mission_id].get("name", mission_id)))
	mission_select.size_flags_horizontal = SIZE_EXPAND_FILL
	mission_row.add_child(mission_select)

	var review_scroll := ScrollContainer.new()
	review_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(review_scroll)
	review_text.bbcode_enabled = true
	review_text.fit_content = true
	review_text.scroll_active = false
	review_text.custom_minimum_size.x = 700
	review_scroll.add_child(review_text)

	var actions := HBoxContainer.new()
	content.add_child(actions)
	close_review_button.text = "Back to Hangar"
	close_review_button.size_flags_horizontal = SIZE_EXPAND_FILL
	confirm_deploy_button.text = "Confirm Deployment"
	confirm_deploy_button.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_child(close_review_button)
	actions.add_child(confirm_deploy_button)

	mission_select.item_selected.connect(_select_mission)
	close_review_button.pressed.connect(_close_squad_review)
	confirm_deploy_button.pressed.connect(_confirm_deploy)


func _theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 14
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("1a2b27") if state == "normal" else (Color("25423b") if state == "hover" else Color("14221f"))
		if state == "disabled":
			box.bg_color = Color("141b1a")
		box.border_color = Color("38d9a9") if (state == "focus" or state == "pressed") else Color("28433c")
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 5
		box.content_margin_bottom = 5
		for type in ["Button", "OptionButton"]:
			result.set_stylebox(state, type, box)
	return result


func _row(parent: Control, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 80
	label.add_theme_color_override("font_color", Color("9eb6af"))
	row.add_child(label)
	control.size_flags_horizontal = SIZE_EXPAND_FILL
	if control is OptionButton:
		control.fit_to_longest_item = false
	control.custom_minimum_size.y = 34
	row.add_child(control)
	parent.add_child(row)


func refresh() -> void:
	var build: Dictionary = hangar.builds[hangar.current_unit_id]
	var unit_idx: int = hangar.UNIT_IDS.find(hangar.current_unit_id)
	unit_select.select(unit_idx)
	_update_unit_tabs(unit_idx)

	title.text = "%s / %s" % [str(hangar.current_unit_id).capitalize(), build["mech"]]

	var breakdown: Dictionary = hangar.build_model.build_combat_breakdown(
		build,
		hangar.GameDataScript.WEAPON_DATA,
		hangar.GameDataScript.ORB_DATA,
		hangar.GameDataScript.PILOT_DATA,
		hangar.GameDataScript.PART_NAMES,
		hangar.GameDataScript.UNIT_INITIATIVE_DATA
	)
	stat_breakdown.text = _format_stat_breakdown(breakdown)

	weapon_select.select(WEAPONS.find(build["weapon"]))
	weapon_details.text = _format_weapon_details(breakdown["weapon"])
	shield_toggle.disabled = hangar.build_model.weapon_handedness(build["weapon"]) == "2H"
	shield_toggle.text = "Occupied (2H)" if shield_toggle.disabled else "Shield Equipped"
	shield_toggle.set_pressed_no_signal(build.get("off_hand", "") == "Shield")

	var slot: String = hangar.highlighted_part_name
	slot_title.text = "%s FRAME" % slot.to_upper()
	_update_slot_tabs(slot)

	var equipped_id: String = build["parts"][slot]
	candidates.clear()
	for child in candidate_grid.get_children():
		candidate_grid.remove_child(child)
		child.queue_free()
	for option in hangar.available_part_options(slot):
		var id: String = option["id"]
		var button := Button.new()
		button.text = str(option["name"]) + ("\nEquipped" if id == equipped_id else "\n%d HP" % option["max_hp"])
		button.icon = mech_view.texture_for(slot, id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.tooltip_text = str(option["name"])
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(preview_part.bind(id))
		candidate_grid.add_child(button)
		candidates[id] = button
		if id == equipped_id:
			equipped_label.text = "Equipped: %s (%d HP)" % [option["name"], option["max_hp"]]

	orb_select.clear()
	orb_select.add_item("Empty socket")
	orb_select.set_item_metadata(0, "")
	for orb in hangar.available_orb_options(slot):
		var orb_profile: Dictionary = hangar.build_model.orb_profile(str(orb["id"]), hangar.GameDataScript.ORB_DATA)
		orb_select.add_item("%s / %s" % [str(orb.get("name", orb["id"])), " / ".join(orb_profile["menu_lines"])])
		var index := orb_select.item_count - 1
		orb_select.set_item_metadata(index, orb["id"])
		if orb["id"] == build.get("orbs", {}).get(slot, ""):
			orb_select.select(index)
	_refresh_orb_details(build, slot)
	_show_preview()


func _format_stat_breakdown(breakdown: Dictionary) -> String:
	var parts: Dictionary = breakdown["part_stats"]
	var effective: Dictionary = breakdown["effective_stats"]
	var p_hp: Dictionary = parts.get("part_hp", {})
	var shield_hp: int = int(effective.get("shield_hp", 0))
	var shield_str := "Shield: %d HP" % shield_hp if shield_hp > 0 else "Shield: None"

	var orb_lines: Array[String] = []
	for profile in breakdown.get("orb_profiles", []):
		var effs: String = ", ".join(profile.get("effect_lines", []))
		orb_lines.append("[color=#38d9a9]•[/color] %s: %s (%s)" % [profile.get("part_name", ""), profile.get("name", ""), effs])
	var orb_text := "\n".join(orb_lines) if not orb_lines.is_empty() else "[color=#778c85]No Orbs installed[/color]"

	return "[b]PART FRAME[/b]\nHead: %d HP  |  Body: %d HP\nL.Arm: %d HP  |  R.Arm: %d HP\nLegs: %d HP\nMove: %d  |  Speed: %+d  |  Acc: %+d  |  Def: %+d  |  Dodge: %d\n\n[b]EFFECTIVE LOADOUT[/b]\nMove: %d tiles  |  Speed: %d\nDefense: %d%%  |  Dodge: %d%%\nAttack Hit: %d%%  |  Damage: %+d%%\n%s\n\n[b]PILOT SKILL[/b]\n%s: %s\n\n[b]SOCKETED ORBS[/b]\n%s" % [
		p_hp.get("Head", 100), p_hp.get("Body", 110),
		p_hp.get("Left Arm", 100), p_hp.get("Right Arm", 104),
		p_hp.get("Legs", 100),
		parts["move"], parts["speed"], parts["accuracy"], parts["defense"], parts["dodge"],
		effective["move"], effective.get("speed", 5),
		effective.get("defense", parts["defense"]), effective.get("dodge", parts["dodge"]),
		effective["attack_hit_percent"], effective["damage_percent"],
		shield_str,
		breakdown["pilot_passive"], breakdown["pilot_effect"],
		orb_text
	]


func _format_weapon_details(profile: Dictionary) -> String:
	return "[b]Range %d-%d[/b]  |  %s\n%s  |  Base damage %d  |  Base hit %d%%" % [profile["range_min"], profile["range_max"], profile["required_arms"], profile["pattern_label"], profile["base_damage"], profile["base_hit_percent"]]


func _refresh_orb_details(build: Dictionary, slot: String) -> void:
	var orb_id := str(build.get("orbs", {}).get(slot, ""))
	if orb_id.is_empty():
		orb_details.text = "[color=#778c85]Socket is empty. Equip an Orb to empower this part.[/color]"
		return
	var proc_bonus := int(hangar.GameDataScript.PILOT_DATA.get(str(build.get("pilot", "")), {}).get("passive", {}).get("orb_proc_bonus_percent", 0))
	var profile: Dictionary = hangar.build_model.orb_profile(orb_id, hangar.GameDataScript.ORB_DATA, proc_bonus)
	var lines: Array = profile["effect_lines"].duplicate()
	lines.append_array(profile["inactive_lines"])
	orb_details.text = "[b]%s / %s %s[/b]\n%s" % [profile["name"], profile["element"], profile["rarity"], "  |  ".join(lines)]


func preview_part(id: String) -> void:
	if not candidates.has(id):
		return
	candidate_id = id
	_show_preview()


func _show_preview() -> void:
	var build: Dictionary = hangar.builds[hangar.current_unit_id]
	var slot: String = hangar.highlighted_part_name
	var changed: bool = not candidate_id.is_empty() and candidate_id != build["parts"][slot]
	var shown: Dictionary = hangar.build_model.swap_part(build, slot, candidate_id) if changed else build
	mech_view.show_build(shown, slot, changed)
	equip_button.disabled = not changed
	cancel_button.disabled = not changed
	deploy_button.disabled = changed
	comparison.text = "[color=#778c85]Currently equipped frame[/color]"
	for id in candidates:
		candidates[id].modulate = Color("38d9a9") if id == candidate_id else Color.WHITE
	if changed:
		var delta: Dictionary = hangar.preview_part_delta(slot, candidate_id)
		comparison.text = "[b]%s[/b]\n" % delta["to_name"]
		var before: Dictionary = hangar.build_model.build_stats(build)
		var after: Dictionary = hangar.build_model.build_stats(shown)
		var labels := {"max_hp": "Part HP", "accuracy": "Accuracy", "defense": "Defense", "speed": "Speed", "move": "Move", "dodge": "Dodge"}
		for key in labels:
			var value: int = delta["stat_delta"][key]
			if value == 0:
				continue
			var a: int = before["part_hp"][slot] if key == "max_hp" else before[key]
			var b: int = after["part_hp"][slot] if key == "max_hp" else after[key]
			var color := "#38d9a9" if value > 0 else "#ff6b6b"
			comparison.text += "%s  %d -> %d  [color=%s](%+d)[/color]\n" % [labels[key], a, b, color, value]


func _equip() -> void:
	if not candidate_id.is_empty():
		hangar.swap_part(hangar.highlighted_part_name, candidate_id)
	candidate_id = ""
	refresh()


func _cancel() -> void:
	candidate_id = ""
	_show_preview()


func _select_unit(index: int) -> void:
	hangar.select_unit(hangar.UNIT_IDS[index])
	candidate_id = ""
	refresh()


func _prev_unit() -> void:
	var cur: int = hangar.UNIT_IDS.find(hangar.current_unit_id)
	var prev_idx: int = (cur - 1 + hangar.UNIT_IDS.size()) % hangar.UNIT_IDS.size()
	_select_unit(prev_idx)


func _next_unit() -> void:
	var cur: int = hangar.UNIT_IDS.find(hangar.current_unit_id)
	var next_idx: int = (cur + 1) % hangar.UNIT_IDS.size()
	_select_unit(next_idx)


func _update_unit_tabs(active_index: int) -> void:
	for i in range(unit_tab_buttons.size()):
		var btn: Button = unit_tab_buttons[i]
		if i == active_index:
			btn.modulate = Color("38d9a9")
		else:
			btn.modulate = Color.WHITE


func _update_slot_tabs(active_slot: String) -> void:
	for slot_name in slot_tab_buttons:
		var btn: Button = slot_tab_buttons[slot_name]
		if slot_name == active_slot:
			btn.modulate = Color("38d9a9")
		else:
			btn.modulate = Color.WHITE


func _select_weapon(index: int) -> void:
	var build: Dictionary = hangar.builds[hangar.current_unit_id].duplicate(true)
	build["weapon"] = WEAPONS[index]
	hangar.builds[hangar.current_unit_id] = hangar.build_model.normalize_build(build, hangar.GameDataScript.WEAPON_DATA, hangar.GameDataScript.ORB_DATA)
	refresh()


func _select_shield(enabled: bool) -> void:
	if not shield_toggle.disabled:
		hangar.builds[hangar.current_unit_id]["off_hand"] = "Shield" if enabled else ""
	refresh()


func _select_slot(slot: String) -> void:
	hangar.highlight_part(slot)
	candidate_id = ""
	refresh()


func _select_orb(index: int) -> void:
	var id: String = orb_select.get_item_metadata(index)
	if id.is_empty():
		hangar.remove_orb(hangar.highlighted_part_name)
	else:
		hangar.install_orb(hangar.highlighted_part_name, id)
	refresh()


func _open_squad_review() -> void:
	if deploy_button.disabled:
		return
	_refresh_review()
	review_overlay.show()


func _close_squad_review() -> void:
	review_overlay.hide()


func _select_mission(index: int) -> void:
	if index >= 0 and index < mission_ids.size():
		selected_mission_id = mission_ids[index]
	_refresh_review()


func _refresh_review() -> void:
	var mission: Dictionary = hangar.GameDataScript.MISSIONS_DATA.get(selected_mission_id, {})
	var lines: Array[String] = []
	lines.append("[b]%s[/b]  |  %s" % [str(mission.get("name", selected_mission_id)), str(mission.get("objective_label", ""))])
	lines.append("[table=2]")
	for member in hangar.squad_overview():
		var equipment := str(member["weapon"]) + " " + str(member["weapon_handedness"])
		if bool(member["has_shield"]):
			equipment += " + Shield"
		var roles := ", ".join(member["role_tags"])
		lines.append("[cell][b]%s / %s[/b]\n%s\nRole: %s\nMove %d[/cell]" % [member["pilot"], member["mech"], equipment, roles, member["move"]])
	lines.append("[/table]")
	review_text.text = "\n".join(lines)


func _confirm_deploy() -> void:
	review_overlay.hide()
	hangar.deploy()
