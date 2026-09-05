extends Control

signal part_selected(slot: String)

const ArtLibrary := preload("res://src/ui/hangar_art_library.gd")
var art_library = ArtLibrary.new()

const SLOTS := {
	"Head": Rect2(263, 27, 74, 79),
	"Body": Rect2(212, 92, 176, 165),
	"Right Arm": Rect2(115, 101, 98, 290),
	"Left Arm": Rect2(387, 101, 98, 290),
	"Legs": Rect2(151, 242, 296, 362),
}
const ORB_ANCHORS := {
	"Head": Vector2(0.50, 0.56),
	"Body": Vector2(0.50, 0.53),
	"Right Arm": Vector2(0.50, 0.56),
	"Left Arm": Vector2(0.50, 0.56),
	"Legs": Vector2(0.50, 0.42),
}
var display_build: Dictionary = {}
var selected_slot := "Head"
var buttons: Dictionary = {}
var orb_markers: Dictionary = {}
var textures: Dictionary = {}
var weapon_visual := TextureRect.new()
var shield_visual := TextureRect.new()
var previewing := false
var cur_part_hps: Dictionary = {}
var preview_part_hps: Dictionary = {}
var callouts := Control.new()


func _ready() -> void:
	custom_minimum_size = Vector2(300, 270)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	for slot in SLOTS:
		var button := TextureButton.new()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = slot
		button.pressed.connect(_choose.bind(slot))
		button.mouse_entered.connect(_hover.bind(slot, true))
		button.mouse_exited.connect(_hover.bind(slot, false))
		add_child(button)
		buttons[slot] = button
	for visual in [weapon_visual, shield_visual]:
		visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(visual)
	for slot in SLOTS:
		var marker := Panel.new()
		marker.custom_minimum_size = Vector2(16, 16)
		marker.size = Vector2(16, 16)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.visible = false
		add_child(marker)
		orb_markers[slot] = marker
	callouts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	callouts.draw.connect(_draw_callouts)
	add_child(callouts)
	resized.connect(_layout)
	_layout()


func _choose(slot: String) -> void:
	part_selected.emit(slot)


func _hover(slot: String, active: bool) -> void:
	buttons[slot].modulate = Color(1.25, 1.25, 1.25) if active else Color.WHITE


func _layout() -> void:
	var factor: float = min(size.x / 600.0, size.y / 650.0)
	var origin := (size - Vector2(600, 650) * factor) * 0.5
	for slot in buttons:
		var rect: Rect2 = SLOTS[slot]
		var id: String = display_build.get("parts", {}).get(slot, "")
		if uses_detailed_art(slot, id):
			rect = art_library.rect_for(slot, id, display_build.get("parts", {}).get("Body", ""))
		buttons[slot].position = origin + rect.position * factor
		buttons[slot].size = rect.size * factor
		orb_markers[slot].position = orb_marker_position(slot) - orb_markers[slot].size * 0.5
	weapon_visual.position = origin + Vector2(75, 320) * factor
	weapon_visual.size = Vector2(180, 250) * factor
	shield_visual.position = origin + Vector2(400, 280) * factor
	shield_visual.size = Vector2(120, 160) * factor
	callouts.size = size
	callouts.queue_redraw()


func orb_marker_position(slot: String) -> Vector2:
	if not buttons.has(slot):
		return Vector2.ZERO
	var rect: Rect2 = buttons[slot].get_rect()
	return rect.position + rect.size * ORB_ANCHORS.get(slot, Vector2(0.5, 0.5))


func texture_for(slot: String, part_id: String) -> Texture2D:
	if uses_detailed_art(slot, part_id):
		return art_library.texture_for(slot, part_id)
	var family: String = part_id.get_slice("_", 0)
	if family == "guard":
		family = "bulwark"
	if family == "sprinter":
		family = "volt"
	var kind := "arm" if slot.contains("Arm") else slot.to_lower()
	var path := "res://assets/hangar/%s_%s.svg" % [family, kind]
	if not textures.has(path):
		var bitmap := Image.new()
		if bitmap.load_svg_from_string(FileAccess.get_file_as_string(path)) != OK:
			return null
		textures[path] = ImageTexture.create_from_image(bitmap)
	return textures[path]


func uses_detailed_art(slot: String, part_id: String) -> bool:
	return art_library.has_art(slot, part_id)


func equipment_texture(asset_name: String) -> Texture2D:
	var path := "res://assets/hangar/%s.svg" % asset_name
	if not textures.has(path):
		var bitmap := Image.new()
		if bitmap.load_svg_from_string(FileAccess.get_file_as_string(path)) != OK:
			return null
		textures[path] = ImageTexture.create_from_image(bitmap)
	return textures[path]


func show_build(build: Dictionary, slot: String, is_preview: bool = false, hps: Dictionary = {}, prev_hps: Dictionary = {}) -> void:
	display_build = build.duplicate(true)
	selected_slot = slot
	previewing = is_preview
	if not hps.is_empty():
		cur_part_hps = hps.duplicate(true)
	preview_part_hps = prev_hps.duplicate(true)
	var weapon_name := str(build.get("weapon", ""))
	weapon_visual.texture = equipment_texture("weapon_%s" % weapon_name.to_lower())
	weapon_visual.visible = weapon_visual.texture != null
	weapon_visual.tooltip_text = weapon_name
	shield_visual.texture = equipment_texture("shield")
	shield_visual.visible = str(build.get("off_hand", "")) == "Shield"
	shield_visual.tooltip_text = "Shield"
	for part in buttons:
		buttons[part].texture_normal = texture_for(part, build["parts"][part])
		var detailed := uses_detailed_art(part, build["parts"][part])
		buttons[part].material = art_library.material_for(part, build["parts"][part]) if detailed else null
		buttons[part].flip_h = part == "Left Arm" and not detailed
		var orb_id: String = str(build.get("orbs", {}).get(part, ""))
		orb_markers[part].visible = not orb_id.is_empty()
		if not orb_id.is_empty():
			orb_markers[part].add_theme_stylebox_override("panel", _orb_style(orb_id))
			buttons[part].tooltip_text = "%s / Orb: %s" % [part, orb_id]
		else:
			buttons[part].tooltip_text = "%s / Orb slot empty" % part
	_layout()



func equipment_visual_state() -> Dictionary:
	var weapon_name := str(display_build.get("weapon", ""))
	return {
		"weapon": weapon_name,
		"weapon_visible": weapon_visual.visible,
		"shield_visible": shield_visual.visible,
		"required_arms": "Both Arms" if weapon_name in ["Spear", "Sniper"] else "Right Arm",
	}


func _draw_callouts() -> void:
	var font := ThemeDB.fallback_font
	var factor: float = min(size.x / 600.0, size.y / 650.0)
	var origin := (size - Vector2(600, 650) * factor) * 0.5
	var muted := Color("52615f")
	if buttons.has(selected_slot):
		var active: Rect2 = buttons[selected_slot].get_rect().grow(4)
		callouts.draw_style_box(_selection_style(), active)
	for slot in buttons:
		var rect: Rect2 = buttons[slot].get_rect()
		var on_left: bool = slot in ["Head", "Right Arm", "Legs"]
		var y_offset: float = -25.0 if slot == "Body" else (10.0 if slot == "Left Arm" else 0.0)
		var y: float = rect.get_center().y + y_offset * factor
		var start := Vector2(8 if on_left else size.x - 96, y)
		var color := Color("78e1c3") if slot == selected_slot else Color("aebeb9")
		callouts.draw_rect(Rect2(start + Vector2(-4, -15), Vector2(94, 33)), Color(0.015, 0.045, 0.05, 0.85))
		callouts.draw_string(font, start + Vector2(0, -2 * factor), slot, HORIZONTAL_ALIGNMENT_LEFT, 90, 13, color)
		var hp_str := ""
		var hp_color := Color("8faea4")
		if cur_part_hps.has(slot):
			var cur_hp: int = cur_part_hps[slot]
			if not preview_part_hps.is_empty() and preview_part_hps.has(slot) and preview_part_hps[slot] != cur_hp:
				var new_hp: int = preview_part_hps[slot]
				var diff: int = new_hp - cur_hp
				hp_str = "%d -> %d (%+d)" % [cur_hp, new_hp, diff]
				hp_color = Color("38d9a9") if diff > 0 else Color("ff6b6b")
			else:
				hp_str = "%d HP" % cur_hp
		if not hp_str.is_empty():
			callouts.draw_string(font, start + Vector2(0, 18 * factor), hp_str, HORIZONTAL_ALIGNMENT_LEFT, 90, 11, hp_color)
		var line_start := start + Vector2(0, 4 * factor)
		var end := Vector2(rect.position.x if on_left else rect.end.x, y + 4 * factor)
		callouts.draw_line(line_start, end, color.darkened(0.5), 1)
	var caption := "PART PREVIEW" if previewing else "ASSEMBLED MECH"
	callouts.draw_string(font, Vector2(15, size.y - 8), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, muted.lightened(0.3))


func _selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.7, 0.55, 0.08)
	style.border_color = Color("72d5b8")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _orb_style(orb_id: String) -> StyleBoxFlat:
	var fill := Color("ef9b79")
	if orb_id.begins_with("lightning"):
		fill = Color("edd77e")
	elif orb_id.begins_with("water"):
		fill = Color("80cbd7")
	elif orb_id.begins_with("earth"):
		fill = Color("91c58d")
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("f4fbf8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 3
	return style
