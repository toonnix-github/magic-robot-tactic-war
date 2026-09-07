extends SceneTree
## Reproducible rendered checks; does not load or overwrite the user's saved party.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var screen = load("res://scenes/fantasy_builder.tscn").instantiate()
	screen.persist_builds = false
	root.add_child(screen)
	DirAccess.make_dir_recursive_absolute("res://docs/playtest/fantasy")
	for dimensions in [Vector2i(1280, 590), Vector2i(844, 390)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for hero in [0, 2, 4]:
			screen.select_hero(hero)
			screen.select_slot("fairy" if hero == 4 else "armor")
			if hero == 0:
				screen.select_candidate("scout_leather")
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://docs/playtest/fantasy/build-%d-%dx%d.png" % [hero, dimensions.x, dimensions.y]
			var result := root.get_texture().get_image().save_png(path)
			print("Capture %s: %d" % [path, result])
	root.size = Vector2i(1280, 590)
	root.content_scale_size = root.size
	screen.select_hero(0)
	screen.select_slot("armor")
	screen.select_candidate("scout_leather")
	screen.equip_button.pressed.emit()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/playtest/fantasy/knight-light-armor.png")
	screen.select_hero(4)
	screen.select_slot("fairy")
	screen.select_candidate("zephyr")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/playtest/fantasy/fairy-transfer.png")
	screen.show_effects()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/playtest/fantasy/build-effects.png")
	quit()
