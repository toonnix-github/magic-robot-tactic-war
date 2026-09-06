extends SceneTree


func _init() -> void:
	call_deferred("_render")


func _render() -> void:
	DirAccess.make_dir_recursive_absolute("res://output")
	for viewport_size in [Vector2i(1280, 590), Vector2i(844, 390)]:
		root.size = viewport_size
		var flow = load("res://scenes/preparation_flow.tscn").instantiate()
		root.add_child(flow)
		var suffix := "%dx%d" % [viewport_size.x, viewport_size.y]
		for variant in ["aegis", "bulwark", "mixed"]:
			flow.editor._select_unit(3 if variant == "bulwark" else 0)
			flow.editor._select_slot("Body")
			if variant == "mixed":
				flow.editor.preview_part("bulwark_body")
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://output/hangar-%s-%s.png" % [variant, suffix])
		flow.free()
		await process_frame
	quit()
