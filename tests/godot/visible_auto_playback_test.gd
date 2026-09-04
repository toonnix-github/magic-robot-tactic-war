extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var visible_scene := await _new_battle_scene()
	visible_scene.auto_activation_highlight_seconds = 0.001
	visible_scene.auto_move_step_seconds = 0.001
	visible_scene.attack_feedback_step_seconds = 0.001
	visible_scene.fast_simulation = false
	visible_scene.enemy_presentation_enabled = true
	visible_scene.attack_presentation_enabled = true

	var player_id := str(visible_scene.units[0]["id"])
	var enemy_id := str(visible_scene.units[1]["id"])
	visible_scene._set_auto_battle(true)
	_assert_true(visible_scene.auto_battle, "Auto Battle turns on")
	_assert_true(visible_scene._input_locked(), "normal combat input is locked while Auto Battle is running")

	for _frame in range(180):
		if visible_scene._is_battle_over():
			break
		await process_frame

	var saw_player_activation := false
	var saw_enemy_activation := false
	var saw_player_move := false
	var saw_enemy_move := false
	for entry in visible_scene.enemy_presentation_log:
		var text := str(entry)
		if text == "%s:activate" % player_id:
			saw_player_activation = true
		if text == "%s:activate" % enemy_id:
			saw_enemy_activation = true
		if text.begins_with("%s:presentation_move:" % player_id):
			saw_player_move = true
		if text.begins_with("%s:presentation_move:" % enemy_id):
			saw_enemy_move = true

	_assert_true(saw_player_activation, "visible Auto presents player-team activation")
	_assert_true(saw_enemy_activation, "visible Auto presents enemy activation")
	_assert_true(saw_player_move, "visible Auto presents player movement tile-by-tile")
	_assert_true(saw_enemy_move, "visible Auto presents enemy movement tile-by-tile")
	_assert_true(not visible_scene.attack_feedback_log.is_empty(), "visible Auto presents attack feedback")
	_assert_true(visible_scene._is_battle_over(), "visible Auto reaches the short scenario result")

	var visible_snapshot := _battle_snapshot(visible_scene)
	var visible_winner := visible_scene._battle_winner()

	var fast_scene := await _new_battle_scene()
	fast_scene.fast_simulation = true
	fast_scene.enemy_presentation_enabled = true
	fast_scene.attack_presentation_enabled = true
	fast_scene._set_auto_battle(true)
	for _frame in range(10):
		if fast_scene._is_battle_over():
			break
		await process_frame

	_assert_true(fast_scene._is_battle_over(), "Fast Simulation completes the same short scenario rapidly")
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

	scene.auto_battle = false
	scene.fast_simulation = false
	scene.simulation_seed = 1337
	scene._load_mission("crystal_quarry")
	await process_frame
	_configure_short_auto_fixture(scene)
	return scene


func _configure_short_auto_fixture(scene) -> void:
	var player = scene._unit_by_id("arlen")
	var enemy = scene._unit_by_id("scavenger_alpha")

	player["grid"] = Vector2i(0, 3)
	player["weapon"] = "Sword"
	player["weapon_mount_part"] = scene._weapon_mount_part(player)
	player["weapon_disabled"] = false
	player["current_move_range"] = 3
	player["base_move_range"] = 3
	player["initiative_time"] = 0.0
	player["speed"] = 5
	player["defeated"] = false
	player["in_battle"] = true
	player["statuses"] = []
	player["parts"]["Body"]["hp"] = 1
	player["parts"]["Body"]["destroyed"] = false

	enemy["grid"] = Vector2i(9, 3)
	enemy["weapon"] = "Commander"
	enemy["weapon_mount_part"] = scene._weapon_mount_part(enemy)
	enemy["weapon_disabled"] = false
	enemy["current_move_range"] = 3
	enemy["base_move_range"] = 3
	enemy["initiative_time"] = 1.0
	enemy["speed"] = 5
	enemy["accuracy_modifier"] = 100
	enemy["defeated"] = false
	enemy["in_battle"] = true
	enemy["statuses"] = []

	# Keep the fixture free from map-specific height/cover variance.
	for x in range(scene.GRID_COLUMNS):
		for y in range(scene.GRID_ROWS):
			scene._set_tile_terrain(Vector2i(x, y), {"height": 0, "cover": false, "blocks_los": false})

	scene.units = [player, enemy]
	scene.current_mission = "crystal_quarry"
	scene.enemy_presentation_log.clear()
	scene.attack_feedback_log.clear()
	scene.turn_log.clear()
	scene._initialize_initiative()
	scene._begin_next_activation()


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
