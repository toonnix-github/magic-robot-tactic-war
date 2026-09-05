extends MarginContainer

const AssemblyViewScript := preload("res://src/ui/mech_assembly_view.gd")
const WEAPONS := ["Sword", "Rifle", "Spear", "Sniper"]
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
var title := Label.new()
var slot_title := Label.new()
var equipped_label := Label.new()
var overview := Label.new()
var candidate_grid := GridContainer.new()
var candidate_id := ""
var candidates: Dictionary = {}


func setup(model) -> void:
	hangar = model
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 20)
	theme = _theme()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var brand := Label.new()
	brand.text = "HANGAR"
	brand.add_theme_font_size_override("font_size", 22)
	header.add_child(brand)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer)
	for id in hangar.UNIT_IDS:
		unit_select.add_item(str(id).capitalize())
	unit_select.custom_minimum_size = Vector2(160, 42)
	header.add_child(unit_select)
	deploy_button.text = "Deploy Squad  >"
	deploy_button.custom_minimum_size = Vector2(180, 42)
	header.add_child(deploy_button)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	split.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(split)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.25
	split.add_child(left)
	title.add_theme_font_size_override("font_size", 26)
	left.add_child(title)
	overview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview.add_theme_color_override("font_color", Color("a6bab5"))
	left.add_child(overview)
	mech_view = AssemblyViewScript.new()
	left.add_child(mech_view)
	mech_view.part_selected.connect(_select_slot)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.0
	split.add_child(scroll)
	var inspector := VBoxContainer.new()
	inspector.size_flags_horizontal = SIZE_EXPAND_FILL
	inspector.add_theme_constant_override("separation", 10)
	scroll.add_child(inspector)
	slot_title.add_theme_font_size_override("font_size", 22)
	inspector.add_child(slot_title)
	equipped_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipped_label.add_theme_color_override("font_color", Color("9fb4ac"))
	inspector.add_child(equipped_label)
	candidate_grid.columns = 2
	candidate_grid.add_theme_constant_override("h_separation", 8)
	candidate_grid.add_theme_constant_override("v_separation", 8)
	inspector.add_child(candidate_grid)
	comparison.bbcode_enabled = true
	comparison.fit_content = true
	comparison.scroll_active = false
	comparison.custom_minimum_size.y = 54
	inspector.add_child(comparison)
	var actions := HBoxContainer.new()
	inspector.add_child(actions)
	equip_button.text = "Equip Part"
	equip_button.custom_minimum_size.y = 40
	equip_button.size_flags_horizontal = SIZE_EXPAND_FILL
	cancel_button.text = "Cancel"
	actions.add_child(equip_button)
	actions.add_child(cancel_button)
	inspector.add_child(HSeparator.new())
	for weapon in WEAPONS:
		weapon_select.add_item("%s (%s)" % [weapon, hangar.build_model.weapon_handedness(weapon)])
	_row(inspector, "Weapon", weapon_select)
	shield_toggle.text = "Shield"
	_row(inspector, "Left hand", shield_toggle)
	_row(inspector, "Part Orb", orb_select)
	unit_select.item_selected.connect(_select_unit)
	weapon_select.item_selected.connect(_select_weapon)
	shield_toggle.toggled.connect(_select_shield)
	orb_select.item_selected.connect(_select_orb)
	deploy_button.pressed.connect(hangar.deploy)
	equip_button.pressed.connect(_equip)
	cancel_button.pressed.connect(_cancel)
	refresh()


func _theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 15
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("263837") if state == "normal" else Color("375b52")
		if state == "disabled":
			box.bg_color = Color("202928")
		box.border_color = Color("638a7d") if state == "focus" else Color("3d5750")
		box.set_border_width_all(1)
		box.set_corner_radius_all(4)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		for type in ["Button", "OptionButton"]:
			result.set_stylebox(state, type, box)
	return result


func _row(parent: Control, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 88
	row.add_child(label)
	control.size_flags_horizontal = SIZE_EXPAND_FILL
	if control is OptionButton:
		control.fit_to_longest_item = false
	control.custom_minimum_size.y = 36
	row.add_child(control)
	parent.add_child(row)


func refresh() -> void:
	var build: Dictionary = hangar.builds[hangar.current_unit_id]
	unit_select.select(hangar.UNIT_IDS.find(hangar.current_unit_id))
	title.text = "%s / %s" % [str(hangar.current_unit_id).capitalize(), build["mech"]]
	var stats: Dictionary = hangar.build_model.build_stats(build)
	overview.text = "%d Armor HP    %d Move    %+d Accuracy    %+d Defense" % [stats["max_hp"], stats["move"], stats["accuracy"], stats["defense"]]
	weapon_select.select(WEAPONS.find(build["weapon"]))
	shield_toggle.disabled = hangar.build_model.weapon_handedness(build["weapon"]) == "2H"
	shield_toggle.text = "Both arms occupied" if shield_toggle.disabled else "Shield"
	shield_toggle.set_pressed_no_signal(build.get("off_hand", "") == "Shield")
	var slot: String = hangar.highlighted_part_name
	slot_title.text = slot
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
		button.add_theme_constant_override("icon_max_width", 48)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.tooltip_text = str(option["name"])
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(preview_part.bind(id))
		candidate_grid.add_child(button)
		candidates[id] = button
		if id == equipped_id:
			equipped_label.text = "Equipped: %s / %d HP" % [option["name"], option["max_hp"]]
	orb_select.clear()
	orb_select.add_item("Empty slot")
	orb_select.set_item_metadata(0, "")
	for orb in hangar.available_orb_options(slot):
		orb_select.add_item(str(orb.get("name", orb["id"])))
		var index := orb_select.item_count - 1
		orb_select.set_item_metadata(index, orb["id"])
		if orb["id"] == build.get("orbs", {}).get(slot, ""):
			orb_select.select(index)
	_show_preview()


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
	comparison.text = "[color=#a6bab5]Current part equipped[/color]"
	for id in candidates:
		candidates[id].modulate = Color("a3efd6") if id == candidate_id else Color.WHITE
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
			var color := "#8ce2bd" if value > 0 else "#f0a19a"
			comparison.text += "%s   %d -> %d   [color=%s](%+d)[/color]\n" % [labels[key], a, b, color, value]


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
