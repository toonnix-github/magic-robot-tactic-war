extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var results: Dictionary = scene.run_phase2_build_validation_suite()
	var markdown: String = scene.generate_phase2_validation_report_markdown(results)
	var file := FileAccess.open("res://docs/playtest/phase2-build-fun-validation-report.md", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write Phase 2 validation report: %s" % FileAccess.get_open_error())
		quit(1)
		return
	file.store_string(markdown)
	file.close()
	print(markdown)
	quit(0)
