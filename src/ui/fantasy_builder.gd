extends Control
## Screen-only preparation controller. Delegates authoritative equipment rules.

const Model := preload("res://src/data/fantasy_build_model.gd")
const PaperDoll := preload("res://src/ui/fantasy_paper_doll.gd")
const GOLD := Color("d7bd83")
const INK := Color("eef0e5")
const MUTED := Color("a2b3ac")
const STAT_NAMES := {"hp": "HP", "atk": "ATK", "matk": "M.ATK", "def": "DEF", "speed": "SPD", "move": "MOVE"}
var model = Model.new()
var persist_builds := true
var selected_hero := 0
var selected_slot := "right_hand"
var selected_candidate := ""
var roster: HBoxContainer
var portrait_panel: Panel
var gear_panel: Panel
var chooser_panel: Panel
var doll: Control
var hero_title: Label
var hero_subtitle: Label
var stats_label: RichTextLabel
var fairy_label: Label
var order_button: OptionButton
var gear_list: VBoxContainer
var candidate_list: VBoxContainer
var detail: RichTextLabel
var candidate_scroll: ScrollContainer
var equip_button: Button
var chooser_title: Label
var toast: Label
var reset_dialog: ConfirmationDialog
var header: Label
var reset_button: Button
var effects_button: Button
var effects_dialog: AcceptDialog
var effects_text: RichTextLabel

func _ready() -> void:
	if persist_builds:
		model.load_from()
	theme = create_theme()
	var background := ColorRect.new()
	background.color = Color("111f22")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	header = label("PARTY ATELIER", 25, GOLD)
	add_child(header)
	reset_button = button("Reset party", reset_party_prompt)
	add_child(reset_button)
	effects_button = button("Build effects", show_effects)
	add_child(effects_button)
	roster = HBoxContainer.new()
	roster.add_theme_constant_override("separation", 8)
	add_child(roster)
	portrait_panel = panel()
	gear_panel = panel()
	chooser_panel = panel()
	build_portrait()
	build_equipment()
	build_chooser()
	toast = label("BUILD YOUR PARTY  /  Level 1 preview · all equipment unlocked", 13, MUTED)
	add_child(toast)
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Reset all five builds?"
	reset_dialog.dialog_text = "Restore starting equipment, fairies and orders for all five heroes."
	reset_dialog.confirmed.connect(reset_party)
	add_child(reset_dialog)
	effects_dialog = AcceptDialog.new()
	effects_dialog.title = "Build effects"
	effects_text = RichTextLabel.new()
	effects_text.bbcode_enabled = true
	effects_text.custom_minimum_size = Vector2(560, 260)
	effects_dialog.add_child(effects_text)
	add_child(effects_dialog)
	resized.connect(layout_screen)
	select_hero(0)
	layout_screen()

func create_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color", "Label", INK)
	result.set_color("default_color", "RichTextLabel", INK)
	for type in ["Button", "OptionButton"]:
		result.set_stylebox("normal", type, box(Color("233337"), Color("3c514e")))
		result.set_stylebox("hover", type, box(Color("354945"), GOLD))
		result.set_stylebox("pressed", type, box(Color("435648"), GOLD))
		result.set_stylebox("focus", type, box(Color.TRANSPARENT, GOLD))
		result.set_stylebox("disabled", type, box(Color("202b2e"), Color("34413f")))
		result.set_color("font_color", type, INK)
		result.set_color("font_disabled_color", type, Color("76837d"))
	return result

func box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func label(value: String, font_size := 16, color := INK) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return node

func button(value: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 42
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.pressed.connect(action)
	return node

func panel() -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel", box(Color("1a2a2d"), Color("40504a")))
	add_child(node)
	return node

func build_portrait() -> void:
	hero_title = label("", 23, GOLD)
	portrait_panel.add_child(hero_title)
	hero_subtitle = label("HUMAN  /  LEVEL 01", 12, MUTED)
	portrait_panel.add_child(hero_subtitle)
	doll = PaperDoll.new()
	doll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_panel.add_child(doll)
	fairy_label = label("", 14, GOLD)
	fairy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_panel.add_child(fairy_label)
	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_panel.add_child(stats_label)
	order_button = OptionButton.new()
	for order in Model.ORDERS:
		order_button.add_item(order)
	order_button.item_selected.connect(change_order)
	order_button.tooltip_text = "Preparation preference only. Follow Job uses the job's role; Stay Safe favors safer positions."
	portrait_panel.add_child(order_button)

func build_equipment() -> void:
	var title := label("EQUIPMENT", 17, GOLD)
	title.position = Vector2(14, 9)
	title.size = Vector2(180, 30)
	gear_panel.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "GearScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gear_panel.add_child(scroll)
	gear_list = VBoxContainer.new()
	gear_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_list.add_theme_constant_override("separation", 5)
	scroll.add_child(gear_list)

func build_chooser() -> void:
	chooser_title = label("", 17, GOLD)
	chooser_panel.add_child(chooser_title)
	candidate_scroll = ScrollContainer.new()
	candidate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chooser_panel.add_child(candidate_scroll)
	candidate_list = VBoxContainer.new()
	candidate_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	candidate_list.add_theme_constant_override("separation", 5)
	candidate_scroll.add_child(candidate_list)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.add_theme_font_size_override("normal_font_size", 15)
	chooser_panel.add_child(detail)
	equip_button = button("Equip", apply_candidate)
	chooser_panel.add_child(equip_button)

func layout_screen() -> void:
	if roster == null:
		return
	var margin := 14.0 if size.x > 1000 else 8.0
	var gap := 10.0
	header.position = Vector2(margin, 6)
	header.size = Vector2(size.x - 310, 38)
	reset_button.position = Vector2(size.x - margin - 136, 5)
	reset_button.size = Vector2(136, 36)
	effects_button.position = Vector2(size.x - margin - 280, 5)
	effects_button.size = Vector2(136, 36)
	var compact := size.y < 480
	var roster_y := 45.0 if compact else 51.0
	var body_y := 94.0 if compact else 109.0
	roster.position = Vector2(margin, roster_y)
	roster.size = Vector2(size.x - margin * 2, 42 if compact else 48)
	var available := size.x - margin * 2 - gap * 2
	var h := size.y - body_y - 30
	portrait_panel.position = Vector2(margin, body_y)
	portrait_panel.size = Vector2(available * 0.32, h)
	gear_panel.position = Vector2(portrait_panel.position.x + portrait_panel.size.x + gap, body_y)
	gear_panel.size = Vector2(available * 0.28, h)
	chooser_panel.position = Vector2(gear_panel.position.x + gear_panel.size.x + gap, body_y)
	chooser_panel.size = Vector2(available * 0.40, h)
	var w := portrait_panel.size.x
	hero_title.position = Vector2(14, 8)
	hero_title.size = Vector2(w - 28, 28)
	hero_subtitle.position = Vector2(14, 37)
	hero_subtitle.size = Vector2(w - 28, 19)
	hero_subtitle.visible = not compact
	doll.position = Vector2(8, 34 if compact else 54)
	doll.size = Vector2(w - 16, maxf(70, h - (137 if compact else 165)))
	fairy_label.position = Vector2(10, h - 112)
	fairy_label.size = Vector2(w - 20, 20)
	stats_label.position = Vector2(14, h - 87)
	stats_label.size = Vector2(w - 28, 48)
	order_button.position = Vector2(14, h - 37)
	order_button.size = Vector2(w - 28, 30)
	var scroll: ScrollContainer = gear_panel.get_node("GearScroll")
	scroll.position = Vector2(9, 43)
	scroll.size = gear_panel.size - Vector2(18, 52)
	chooser_title.position = Vector2(14, 9)
	chooser_title.size = Vector2(chooser_panel.size.x - 28, 27)
	candidate_scroll.position = Vector2(12, 43)
	candidate_scroll.size = Vector2(chooser_panel.size.x - 24, maxf(64, (h - 98) * 0.43))
	detail.position = Vector2(15, candidate_scroll.position.y + candidate_scroll.size.y + 10)
	detail.size = Vector2(chooser_panel.size.x - 30, h - detail.position.y - 57)
	equip_button.position = Vector2(12, h - 49)
	equip_button.size = Vector2(chooser_panel.size.x - 24, 39)
	toast.position = Vector2(margin, size.y - 25)
	toast.size = Vector2(size.x - margin * 2, 22)
	doll.queue_redraw()

func content_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, chooser_panel.position + chooser_panel.size)

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func select_hero(index: int) -> void:
	selected_hero = index
	select_slot(selected_slot)

func select_slot(slot: String) -> void:
	selected_slot = slot
	selected_candidate = model.party[selected_hero].equipment[slot]
	refresh()
	candidate_scroll.scroll_vertical = 0

func select_candidate(item_id: String) -> void:
	selected_candidate = item_id
	refresh_candidates()
	refresh_detail()

func refresh() -> void:
	clear_children(roster)
	for i in model.party.size():
		var hero: Dictionary = model.party[i]
		var entry := button("%02d   %s" % [i + 1, hero.job], select_hero.bind(i))
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_theme_stylebox_override("normal", box(Color("37483f") if i == selected_hero else Color("202e31"), GOLD if i == selected_hero else Color("3c514e")))
		roster.add_child(entry)
	var hero: Dictionary = model.party[selected_hero]
	hero_title.text = hero.job
	hero_title.tooltip_text = model.catalog.jobs[hero.job].description
	doll.show_build(hero.equipment, model.catalog)
	var fairy: Dictionary = model.item(hero.equipment.fairy)
	fairy_label.text = "%s  ·  %s" % [fairy.name, fairy.element] if not fairy.is_empty() else "No fairy assigned"
	var totals: Dictionary = model.stats(selected_hero)
	stats_label.text = "[center]HP [color=#d7bd83]%d[/color]   ATK [color=#d7bd83]%d[/color]   M.ATK [color=#d7bd83]%d[/color]\nDEF [color=#d7bd83]%d[/color]   SPD [color=#d7bd83]%d[/color]   MOVE [color=#d7bd83]%d[/color][/center]" % [totals.hp,totals.atk,totals.matk,totals.def,totals.speed,totals.move]
	order_button.select(Model.ORDERS.find(hero.order))
	clear_children(gear_list)
	for slot in model.catalog.slots:
		var equipped: Dictionary = model.item(hero.equipment[slot])
		var item_name: String = equipped.get("name", "Empty")
		if slot == "left_hand" and model.item(hero.equipment.right_hand).get("hands", 1) == 2:
			item_name = "Two-handed weapon"
		var entry := button("%s\n%s" % [model.catalog.slots[slot].to_upper(), item_name], select_slot.bind(slot))
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.custom_minimum_size.y = 53
		entry.add_theme_font_size_override("font_size", 14)
		entry.add_theme_stylebox_override("normal", box(Color("34443d") if slot == selected_slot else Color("202e31"), GOLD if slot == selected_slot else Color("3c514e")))
		gear_list.add_child(entry)
	chooser_title.text = "CHOOSE  /  " + model.catalog.slots[selected_slot].to_upper()
	refresh_candidates()
	refresh_detail()

func refresh_candidates() -> void:
	clear_children(candidate_list)
	var options: Array[String] = model.candidates(selected_hero, selected_slot)
	options.append("")
	for item_id in options:
		var entry_data: Dictionary = model.item(item_id)
		var title: String = entry_data.get("name", "Unequip")
		if item_id == model.party[selected_hero].equipment[selected_slot]:
			title += "  ·  Equipped"
		elif selected_slot == "fairy" and model.fairy_owner(item_id) >= 0:
			title += "  ·  " + model.party[model.fairy_owner(item_id)].job
		var entry := button(title, select_candidate.bind(item_id))
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.add_theme_stylebox_override("normal", box(Color("3b4d42") if item_id == selected_candidate else Color("202e31"), GOLD if item_id == selected_candidate else Color("3c514e")))
		candidate_list.add_child(entry)

func refresh_detail() -> void:
	var entry: Dictionary = model.item(selected_candidate)
	var current: String = model.party[selected_hero].equipment[selected_slot]
	var total: Dictionary = model.stats(selected_hero)
	var preview: Dictionary = model.preview_stats(selected_hero, selected_slot, selected_candidate)
	var text := "[color=#d7bd83][b]%s[/b][/color]\n" % entry.get("name", "Empty slot")
	var owner: int = model.fairy_owner(selected_candidate) if selected_slot == "fairy" else -1
	if owner >= 0 and owner != selected_hero:
		text += "[color=#eeaa97]Transfer from %s. Their fairy slot will become empty.[/color]\n\n" % model.party[owner].job
	if entry.has("element"):
		text += "%s  ·  " % entry.element
	if entry.has("range"):
		text += "Range %d–%d  ·  %dH\n" % [entry.range[0], entry.range[1], entry.hands]
	elif entry.has("element"):
		text += "Fairy partner\n"
	var deltas: Array[String] = []
	for stat in STAT_NAMES:
		var delta: int = int(preview[stat]) - int(total[stat])
		if delta != 0:
			deltas.append("%s %d → %d [color=%s](%+d)[/color]" % [STAT_NAMES[stat], total[stat], preview[stat], "#9ed8b3" if delta > 0 else "#eeaa97", delta])
	text += "\n" + ("\n".join(deltas) if not deltas.is_empty() else "No change to total stats.") + "\n"
	if selected_candidate == current and not entry.get("stats", {}).is_empty():
		var bonuses: Array[String] = []
		for stat in entry.stats:
			bonuses.append("%s %+d" % [STAT_NAMES.get(stat, stat), entry.stats[stat]])
		text += "Bonuses: " + " · ".join(bonuses) + "\n"
	for ability in entry.get("abilities", []):
		text += "\n[color=#d7bd83]◆[/color] " + ability + "\n"
	if entry.get("abilities", []).is_empty():
		text += "\nEquipment bonuses only."
	if selected_slot == "right_hand" and entry.get("hands", 1) == 2 and model.party[selected_hero].equipment.left_hand != "":
		text += "\n\n[color=#eeaa97]Equipping this also removes the left-hand item. Comparison includes its removal.[/color]"
	if owner >= 0 and owner != selected_hero:
		equip_button.text = "Transfer from " + model.party[owner].job
	else:
		equip_button.text = "Equipped" if current == selected_candidate else ("Unequip" if selected_candidate.is_empty() else "Equip " + entry.get("name", ""))
	equip_button.disabled = current == selected_candidate or not model.can_equip(selected_hero, selected_slot, selected_candidate)
	detail.text = text
	detail.scroll_to_line(0)

func apply_candidate() -> void:
	if model.equip(selected_hero, selected_slot, selected_candidate, true):
		persist("Build updated")
		refresh()

func change_order(index: int) -> void:
	model.set_order(selected_hero, Model.ORDERS[index])
	persist("Order saved · preparation only")

func persist(message: String) -> void:
	if not persist_builds:
		toast.text = message + "  /  Preview session"
		return
	var saved: bool = not persist_builds or model.save_to()
	toast.text = message + ("  /  Saved locally" if saved else "  /  Save unavailable; changes remain in this session")

func reset_party_prompt() -> void:
	reset_dialog.popup_centered()

func reset_party() -> void:
	model.reset()
	select_hero(0)
	persist("Starting party restored")

func show_effects() -> void:
	var hero: Dictionary = model.party[selected_hero]
	var content := "[b][color=#d7bd83]%s · Level 1[/color][/b]\n%s\n\n" % [hero.job, model.catalog.jobs[hero.job].description]
	for ability in model.abilities(selected_hero):
		content += "◆ " + ability + "\n\n"
	content += "[color=#a2b3ac]Ability descriptions are preparation previews. The fantasy battle system is not implemented in this screen. Stat allocation and growth costs remain to be designed.[/color]"
	effects_text.text = content
	effects_dialog.popup_centered(Vector2i(mini(int(size.x) - 40, 680), mini(int(size.y) - 30, 430)))
