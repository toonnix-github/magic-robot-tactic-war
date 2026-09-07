extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1200, 1000)
	root.content_scale_size = root.size
	var model = load("res://src/data/fantasy_build_model.gd").new()
	var cases := [
		[0, "steel_plate", "iron_sword", "Plate / sword / shield"],
		[1, "steel_plate", "great_axe", "Plate / axe"],
		[2, "scout_leather", "longbow", "Leather / bow"],
		[3, "woven_robes", "ember_staff", "Robe / staff"],
		[0, "scout_leather", "guard_spear", "Leather / shared spear art"],
		[0, "", "", "Base body reference"],
	]
	for index in cases.size():
		var entry: Array = cases[index]
		var hero: int = entry[0]
		model.equip(hero, "armor", entry[1])
		model.equip(hero, "right_hand", entry[2])
		if index == 5:
			for slot in model.catalog.slots:
				model.equip(hero, slot, "")
		var view = load("res://src/ui/fantasy_paper_doll.gd").new()
		view.position = Vector2((index % 3) * 400 + 25, (index / 3) * 500 + 40)
		view.size = Vector2(350,435)
		root.add_child(view)
		view.show_build(model.party[hero].equipment, model.catalog)
		var label := Label.new()
		label.text = entry[3]
		label.position = view.position - Vector2(0,30)
		root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/playtest/fantasy/equipment-alignment.png")
	quit()
