extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var flow = load("res://scenes/preparation_flow.tscn").instantiate()
	root.add_child(flow)
	flow.editor.unit_select.item_selected.emit(1)
	flow.editor.weapon_select.item_selected.emit(1)
	flow.editor.shield_toggle.toggled.emit(true)
	for viewport_size in [Vector2i(1280, 590), Vector2i(844, 390)]:
		root.size = viewport_size
		DisplayServer.window_set_size(viewport_size)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://phase2-hangar-%d.png" % viewport_size.x)
	flow.editor.mech_view.buttons["Body"].pressed.emit()
	flow.editor.candidates["bulwark_body"].pressed.emit()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://phase2-part-preview.png")
	flow.editor.cancel_button.pressed.emit()
	flow.editor.deploy_button.pressed.emit()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://phase2-battle.png")
	flow.battle.run_auto_battle(150, 42)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://phase2-result.png")
	print("Phase 2 screenshots: ", OS.get_user_data_dir())
	quit(0)
