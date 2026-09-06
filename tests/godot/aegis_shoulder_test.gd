extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var flow = load("res://scenes/preparation_flow.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var failures: Array[String] = preload("res://tests/godot/aegis_shoulder_acceptance.gd").check(flow.editor.mech_view, flow.hangar.builds["arlen"])
	for failure in failures:
		printerr(failure)
	flow.free()
	print("AEGIS SHOULDER TESTS PASSED" if failures.is_empty() else "AEGIS SHOULDER TESTS FAILED")
	quit(0 if failures.is_empty() else 1)
