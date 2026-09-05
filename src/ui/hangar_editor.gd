extends MarginContainer

var hangar
var unit_select := OptionButton.new()
var weapon_select := OptionButton.new()
var shield_toggle := CheckBox.new()
var slot_select := OptionButton.new()
var part_select := OptionButton.new()
var orb_select := OptionButton.new()
var deploy_button := Button.new()
var summary := Label.new()
var delta_label := Label.new()
var parts_label := Label.new()
const WEAPONS := ["Sword", "Rifle", "Spear", "Sniper"]


func setup(model) -> void:
	hangar = model
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, 20)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "HANGAR"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for id in hangar.UNIT_IDS:
		unit_select.add_item(str(id).capitalize())
	header.add_child(unit_select)
	deploy_button.text = "Deploy Squad"
	header.add_child(deploy_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	for weapon in WEAPONS:
		weapon_select.add_item("%s (%s)" % [weapon, hangar.build_model.weapon_handedness(weapon)])
	_row(content, "Weapon", weapon_select)
	shield_toggle.text = "Shield (Left Arm)"
	_row(content, "Off-hand", shield_toggle)
	for slot in hangar.GameDataScript.PART_NAMES:
		slot_select.add_item(slot)
	_row(content, "Part Slot", slot_select)
	_row(content, "Equipped Part", part_select)
	_row(content, "Orb", orb_select)
	for label in [delta_label, summary, parts_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(label)
	unit_select.item_selected.connect(_select_unit)
	weapon_select.item_selected.connect(_select_weapon)
	shield_toggle.toggled.connect(_select_shield)
	slot_select.item_selected.connect(_select_slot)
	part_select.item_selected.connect(_select_part)
	orb_select.item_selected.connect(_select_orb)
	deploy_button.pressed.connect(hangar.deploy)
	refresh()


func _row(parent: Control, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 130
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if control is OptionButton:
		control.fit_to_longest_item = false
	control.custom_minimum_size.y = 42
	row.add_child(control)
	parent.add_child(row)


func refresh() -> void:
	var build: Dictionary = hangar.builds[hangar.current_unit_id]
	unit_select.select(hangar.UNIT_IDS.find(hangar.current_unit_id))
	weapon_select.select(WEAPONS.find(build["weapon"]))
	shield_toggle.disabled = hangar.build_model.weapon_handedness(build["weapon"]) == "2H"
	shield_toggle.set_pressed_no_signal(build.get("off_hand", "") == "Shield")
	var slot: String = hangar.highlighted_part_name
	slot_select.select(hangar.GameDataScript.PART_NAMES.find(slot))
	part_select.clear()
	for option in hangar.available_part_options(slot):
		var delta: Dictionary = hangar.preview_part_delta(slot, option["id"])
		var changes: String = ", ".join(delta.get("display_lines", []))
		part_select.add_item(str(option["name"]) + (" | " + changes if not changes.is_empty() else ""))
		var index := part_select.item_count - 1
		part_select.set_item_metadata(index, option["id"])
		if option["id"] == build["parts"][slot]:
			part_select.select(index)
	orb_select.clear()
	orb_select.add_item("Empty")
	orb_select.set_item_metadata(0, "")
	for orb in hangar.available_orb_options(slot):
		orb_select.add_item(str(orb.get("name", orb["id"])))
		var index := orb_select.item_count - 1
		orb_select.set_item_metadata(index, orb["id"])
		if orb["id"] == build.get("orbs", {}).get(slot, ""):
			orb_select.select(index)
	var signals: Dictionary = hangar.current_build_signals()
	summary.text = "%s\n%s\nStrengths: %s\nWeaknesses: %s" % [signals.get("summary_line", ""), ", ".join(signals.get("role_tags", [])), ", ".join(signals.get("strengths", [])), ", ".join(signals.get("weaknesses", [])) if not signals.get("weaknesses", []).is_empty() else "None flagged"]
	var rows: Array[String] = []
	for row in hangar.part_rows():
		rows.append("%s: %s | %s | %s" % [row["part_name"], row["part_id"], row["durability"], row["orb_state"]])
	parts_label.text = "\n".join(rows)
	parts_label.text += "\n\nSQUAD\n"
	for unit in hangar.squad_overview():
		parts_label.text += "%s: %s\n" % [unit["pilot"], unit["summary_line"]]


func _select_unit(index: int) -> void:
	hangar.select_unit(hangar.UNIT_IDS[index])
	delta_label.text = ""
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


func _select_slot(index: int) -> void:
	hangar.highlight_part(hangar.GameDataScript.PART_NAMES[index])
	delta_label.text = ""
	refresh()


func _select_part(index: int) -> void:
	var id: String = part_select.get_item_metadata(index)
	var delta: Dictionary = hangar.preview_part_delta(hangar.highlighted_part_name, id)
	delta_label.text = ", ".join(delta.get("display_lines", []))
	hangar.swap_part(hangar.highlighted_part_name, id)
	refresh()


func _select_orb(index: int) -> void:
	var id: String = orb_select.get_item_metadata(index)
	if id.is_empty():
		hangar.remove_orb(hangar.highlighted_part_name)
	else:
		hangar.install_orb(hangar.highlighted_part_name, id)
	refresh()
