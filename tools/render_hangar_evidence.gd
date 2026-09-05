extends SceneTree


func _init() -> void:
	call_deferred("_render")


func _render() -> void:
	for viewport_size in [Vector2i(1280, 590), Vector2i(844, 390)]:
		root.size = viewport_size
		var flow = load("res://scenes/preparation_flow.tscn").instantiate()
		root.add_child(flow)
		await process_frame
		await process_frame
		var suffix := "%dx%d" % [viewport_size.x, viewport_size.y]
		root.get_texture().get_image().save_png("res://docs/playtest/hangar-loadout-%s.png" % suffix)
		flow.editor.unit_select.select(3)
		flow.editor.unit_select.item_selected.emit(3)
		await process_frame
		root.get_texture().get_image().save_png("res://docs/playtest/hangar-shield-%s.png" % suffix)
		flow.editor._open_squad_review()
		await process_frame
		root.get_texture().get_image().save_png("res://docs/playtest/hangar-squad-review-%s.png" % suffix)
		flow.free()
		await process_frame
	quit()
