extends RefCounted

static func check(tree: SceneTree) -> Array[String]:
	var errors: Array[String] = []
	var script = load("res://src/data/fantasy_build_model.gd")
	if script == null:
		errors.append("Fantasy build model must exist")
		return errors
	var model = script.new()
	if model.party.size() != 5 or model.catalog.fairies.size() != 6:
		errors.append("Five jobs and six fairies required")
	var before: Dictionary = model.stats(0)
	if model.equip(0, "right_hand", "longbow"):
		errors.append("Knight cannot equip ranger bow")
	if not model.equip(0, "armor", "scout_leather"):
		errors.append("Knight can build for evasion with light armor")
	if model.stats(0).speed <= before.speed:
		errors.append("Light armor must increase speed over plate")
	var original: Dictionary = model.party[0].duplicate(true)
	model.preview_stats(0, "armor", "steel_plate")
	if model.party[0] != original:
		errors.append("Preview cannot mutate a build")
	model.equip(1, "right_hand", "great_axe")
	if model.can_equip(1, "left_hand", "iron_shield"):
		errors.append("Two-handed weapon blocks off-hand")
	if model.equip(0, "fairy", "ember"):
		errors.append("Occupied fairy requires explicit transfer")
	if not model.equip(0, "fairy", "ember", true) or model.party[1].equipment.fairy != "":
		errors.append("Fairy transfer must clear previous owner")
	model.equip(0, "accessory_1", "swift_charm")
	var one: int = model.stats(0).speed
	model.equip(0, "accessory_2", "swift_charm")
	if model.stats(0).speed != one + 2:
		errors.append("Accessory stat bonuses must stack")
	if model.abilities(0).count("Quickstep: +2 Speed.") != 1:
		errors.append("Identical abilities display once")
	if model.can_equip(-1, "armor", "steel_plate") or model.can_equip(0, "bad_slot", "steel_plate"):
		errors.append("Invalid inputs must be rejected")
	model.set_order(0, "Stay Safe")
	if model.set_order(0, "bad_order"):
		errors.append("Invalid order must be rejected")
	var path := "user://fantasy_acceptance.json"
	model.save_to(path)
	var restored = script.new()
	restored.load_from(path)
	if restored.party != model.party:
		errors.append("Save must round-trip all builds")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version":1,"party":[null,{"equipment":42}]}')
	file.close()
	restored.load_from(path)
	if restored.party.size() != 5:
		errors.append("Malformed save cannot corrupt party")
	DirAccess.remove_absolute(path)
	var scene = load("res://scenes/fantasy_builder.tscn")
	if scene == null:
		errors.append("Standalone scene required")
		return errors
	var ui = scene.instantiate()
	ui.persist_builds = false
	tree.root.add_child(ui)
	ui.select_hero(2)
	ui.select_slot("right_hand")
	ui.select_candidate("crippling_bow")
	ui.apply_candidate()
	if ui.model.party[2].equipment.right_hand != "crippling_bow":
		errors.append("UI must apply selected equipment")
	ui.select_hero(0)
	if ui.selected_hero != 0:
		errors.append("Roster selection must work")
	ui.select_slot("fairy")
	ui.select_candidate("ember")
	if not "Transfer from Warrior" in ui.equip_button.text or not "will become empty" in ui.detail.text:
		errors.append("UI must explain occupied fairy transfer before applying it")
	ui.equip_button.pressed.emit()
	if ui.model.fairy_owner("ember") != 0 or ui.model.party[1].equipment.fairy != "":
		errors.append("UI transfer must preserve unique fairy ownership")
	ui.change_order(1)
	ui.select_hero(1)
	ui.select_hero(0)
	if ui.order_button.selected != 1:
		errors.append("Order must survive hero switches")
	ui.show_effects()
	if not "Intercept" in ui.effects_text.text:
		errors.append("Build effects must expose job abilities")
	ui.effects_dialog.hide()
	ui.reset_party_prompt()
	ui.reset_dialog.hide()
	ui.reset_party()
	ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for viewport_size in [Vector2(1280, 590), Vector2(844, 390)]:
		ui.size = viewport_size
		ui.layout_screen()
		if ui.content_bounds().end.x > viewport_size.x + 1 or ui.content_bounds().end.y > viewport_size.y + 1:
			errors.append("Build panels must fit landscape viewport")
	for hero_index in 5:
		ui.select_hero(hero_index)
		for slot in ui.model.catalog.slots:
			ui.select_slot(slot)
			for candidate in ui.model.candidates(hero_index, slot):
				ui.select_candidate(candidate)
				if not ui.detail.text.contains(ui.model.item(candidate).name):
					errors.append("Every legal item must have an inspectable detail view")
	ui.queue_free()
	return errors
