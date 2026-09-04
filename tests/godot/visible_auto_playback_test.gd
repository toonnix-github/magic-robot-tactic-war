extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var visible_scene := await _new_battle_scene()
	visible_scene.auto_activation_highlight_seconds = 0.001
	visible_scene.auto_move_step_seconds = 0.001
	visible_scene.attack_feedback_step_seconds = 0.001
	visible_scene.simulation_seed = 1337
	visible_scene.fast_simulation = false
	visible_scene.enemy_presentation_enabled = true
	visible_scene.attack_presentation_enabled = true

	visible_scene._set_auto_battle(true)
	_assert_true(visible_scene.auto_battle, "Auto Battle turns on")
	_assert_true(visible_scene._input_locked(), "normal combat input is locked while Auto Battle is running")

	var saw_player_activation := false
	var saw_enemy_activation := false
	var saw_attack_feedback := false
	for _frame in range(1200):
		await process_frame
		for entry in visible_scene.enemy_presentation_log:
			var text := str(entry)
			if text.begins_with("arlen:") or text.begins_with("mira:") or text.begins_with("sera:") or text.begins_with("brann:"):
				saw_player_activation = true
			if text.begins_with("enemy_") or text.begins_with("commander:"):
				saw_enemy_activation = true
		if not visible_scene.attack_feedback_log.is_empty():
			saw_attack_feedback = true
		if visible_scene._is_battle_over() and saw_player_activation and saw_enemy_activation and saw_attack_feedback:
			break

	_assert_true(saw_player_activation, "visible Auto presents player-team activations")
	_assert_true(saw_enemy_activation, "visible Auto presents enemy activations")
	_assert_true(saw_attack_feedback, "visible Auto presents attacks instead of resolving only in the background")
	_assert_true(visible_scene._is_battle_over(), "visible Auto can finish the battle")

	var visible_snapshot := _battle_snapshot(visible_scene)
	var visible_winner := visible_scene._battle_winner()

	var fast_scene := await _new_battle_scene()
	fast_scene.simulation_seed = 1337
	fast_scene.fast_simulation = true
	fast_scene.enemy_presentation_enabled = true
	fast_scene.attack_presentation_enabled = true
	fast_scene._set_auto_battle(true)
	for _frame in range(20):
		if fast_scene._is_battle_over():
			break
		await process_frame

	_assert_true(fast_scene._is_battle_over(), "Fast Simulation still completes rapidly")
	_assert_equal(fast_scene._battle_winner(), visible_winner, "visible Auto and Fast Simulation produce the same winner")
	_assert_equal(_battle_snapshot(fast_scene), visible_snapshot, "visible Auto and Fast Simulation preserve deterministic final combat state")
	_assert_true(fast_scene.attack_feedback_log.is_empty(), "Fast Simulation skips attack presentation")

	visible_scene.queue_free()
	fast_scene.queue_free()
	await process_frame

	if _failures.is_empty():
		print("VISIBLE AUTO PLAYBACK TESTS PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _new_battle_scene():
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate() as Control
	root.add_child(scene)
	await process_frame
	await process_frame
	# Reset to a known starting point after _ready() so both comparison runs start identically.
	scene.auto_battle = false
	scene.fast_simulation = false
	scene.simulation_seed = 1337
	scene._load_mission("ancient_ruins")
	await process_frame
	return scene


func _battle_snapshot(scene) -> Dictionary:
	var snapshot := {}
	for unit in scene.units:
		var parts := {}
		for part_name in scene.PART_NAMES:
			parts[part_name] = int(unit["parts"][part_name]["hp"])
		snapshot[str(unit["id"])] = {
			"grid": unit["grid"],
			"in_battle": bool(unit.get("in_battle", false)),
			"defeated": bool(unit.get("defeated", false)),
			"parts": parts,
			"shield_hp": int(unit.get("shield_hp", 0)),
			"statuses": unit.get("statuses", []).duplicate(true),
		}
	return snapshot


func _assert_true(value: bool, label: String) -> void:
	if not value:
		_failures.append("FAIL: %s" % label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("FAIL: %s (actual=%s expected=%s)" % [label, str(actual), str(expected)])
