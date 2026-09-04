extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate() as Control
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	scene.fast_simulation = true

	print("Running Phase 1 Auto Benchmark Suite...")
	var suite_results: Dictionary = scene.run_auto_benchmark_suite()
	var markdown: String = scene.generate_benchmark_report_markdown(suite_results)
	print(markdown)

	DirAccess.make_dir_recursive_absolute("res://docs/playtest")
	var file := FileAccess.open("res://docs/playtest/phase1-auto-benchmark-report.md", FileAccess.WRITE)
	if file != null:
		file.store_string(markdown)
		file.close()
		print("\nReport successfully written to docs/playtest/phase1-auto-benchmark-report.md")
	else:
		push_error("Failed to write benchmark report to file.")

	quit(0)
