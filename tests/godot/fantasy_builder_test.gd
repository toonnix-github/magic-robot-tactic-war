extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures: Array[String] = load("res://tests/godot/fantasy_builder_acceptance.gd").check(self)
	for failure in failures:
		push_error(failure)
	print("Fantasy builder acceptance: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
