extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Control = packed_scene.instantiate() as Control
	root.add_child(scene)
	await process_frame
	await process_frame

	_assert_equal(scene.GRID_COLUMNS, 10, "grid has 10 columns")
	_assert_equal(scene.GRID_ROWS, 7, "grid has 7 rows")
	_assert_equal(scene.PRIMARY_ACTIONS, ["Move", "Attack", "Wait"], "primary actions stay scoped")
	_assert_equal(_count_team(scene.units, "player"), 4, "four player units are present")

	var arlen = scene._unit_by_id("arlen")
	var mira = scene._unit_by_id("mira")
	var enemy = scene._unit_by_id("enemy_blade")

	arlen["grid"] = Vector2i(1, 1)
	mira["grid"] = Vector2i(2, 1)
	enemy["grid"] = Vector2i(8, 6)
	scene._select_unit(arlen)
	var reachable: Dictionary = scene._calculate_reachable_tiles(arlen)
	_assert_false(reachable.has("2,1"), "allies cannot be final movement destinations")
	_assert_true(reachable.has("3,1"), "allies may be traversed")

	scene._handle_grid_tap(scene._tile_center(Vector2i(3, 1)))
	_assert_equal(arlen["grid"], Vector2i(3, 1), "tap on reachable tile moves selected unit")

	arlen["grid"] = Vector2i(1, 1)
	mira["grid"] = Vector2i(8, 5)
	enemy["grid"] = Vector2i(2, 1)
	scene._select_unit(arlen)
	reachable = scene._calculate_reachable_tiles(arlen)
	_assert_false(reachable.has("3,1"), "opponents block movement routes")

	scene._select_action("Attack")
	_assert_equal(scene.selected_action, "Attack", "action selection changes selected action")
	_assert_equal(scene.reachable_tiles.size(), 0, "non-move actions clear movement highlights")

	scene._notification(0)
	_assert_true(scene._is_in_bounds(Vector2i(0, 0)), "origin tile is in bounds")
	_assert_false(scene._is_in_bounds(Vector2i(10, 7)), "outside tile is out of bounds")
	_assert_equal(scene._height_at(Vector2i(9, 0)), 4, "rightmost band reaches H4")
	_assert_equal(scene._grid_from_key(scene._grid_key(Vector2i(4, 2))), Vector2i(4, 2), "grid keys round-trip")
	_assert_true(scene._grid_at_position(scene._tile_center(Vector2i(4, 2))) == Vector2i(4, 2), "tile hit-testing works")
	_assert_true(scene._unit_at_position(scene._tile_center(arlen["grid"])) == arlen, "unit hit-testing works")

	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = Vector2(12, 34)
	_assert_equal(scene._event_press_position(mouse), Vector2(12, 34), "mouse taps are accepted")

	scene.action_rects["Wait"] = Rect2(Vector2(0, 0), Vector2(100, 100))
	mouse.position = Vector2(10, 10)
	scene._gui_input(mouse)
	_assert_equal(scene.selected_action, "Wait", "gui input can trigger action buttons")

	_assert_equal(scene._short_part_name("Left Arm"), "L Arm", "left arm short label")
	_assert_equal(scene._short_part_name("Right Arm"), "R Arm", "right arm short label")
	_assert_equal(scene._short_part_name("Legs"), "Legs", "plain part label")

	if _failures.is_empty():
		print("GODOT TESTS PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _count_team(units: Array, team: String) -> int:
	var count := 0
	for unit in units:
		if unit["team"] == team:
			count += 1
	return count


func _assert_true(actual: bool, message: String) -> void:
	if not actual:
		_failures.append("Expected true: %s" % message)


func _assert_false(actual: bool, message: String) -> void:
	if actual:
		_failures.append("Expected false: %s" % message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s but got %s" % [message, expected, actual])
