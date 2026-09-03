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
	scene._begin_activation(arlen)
	scene._select_unit(arlen)
	var reachable: Dictionary = scene._calculate_reachable_tiles(arlen)
	_assert_false(reachable.has("2,1"), "allies cannot be final movement destinations")
	_assert_true(reachable.has("3,1"), "allies may be traversed")

	scene._handle_grid_tap(scene._tile_center(Vector2i(3, 1)))
	_assert_equal(arlen["grid"], Vector2i(3, 1), "tap on reachable tile moves selected unit")

	arlen["grid"] = Vector2i(1, 1)
	mira["grid"] = Vector2i(8, 5)
	enemy["grid"] = Vector2i(2, 1)
	scene._begin_activation(arlen)
	scene._select_unit(arlen)
	reachable = scene._calculate_reachable_tiles(arlen)
	_assert_false(reachable.has("3,1"), "opponents block movement routes")

	scene._select_action("Attack")
	_assert_equal(scene.active_unit["id"], "mira", "attack action resolves and advances initiative")
	_assert_equal(scene.selected_action, "Move", "next active unit receives fresh command state")
	_assert_false(scene._can_move(arlen), "previous attacker is no longer controllable")

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
	_assert_equal(scene.active_unit["id"], "sera", "gui input can trigger wait and advance action buttons")

	_assert_equal(scene._short_part_name("Left Arm"), "L Arm", "left arm short label")
	_assert_equal(scene._short_part_name("Right Arm"), "R Arm", "right arm short label")
	_assert_equal(scene._short_part_name("Legs"), "Legs", "plain part label")
	_run_turn_flow_acceptance(scene)

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


func _run_turn_flow_acceptance(scene: Control) -> void:
	var required_methods := [
		"_initialize_initiative",
		"_begin_next_activation",
		"_begin_activation",
		"_can_move",
		"_try_move_active_unit",
		"_try_attack_active_unit",
		"_try_wait_active_unit",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "turn-flow API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_move_once_then_second_move_rejected(scene)
	_test_move_then_attack_advances_to_next_player(scene)
	_test_attack_without_moving_advances_to_next_player(scene)
	_test_move_then_wait_advances_to_next_player(scene)
	_test_wait_without_moving_advances_to_next_player(scene)
	_test_selecting_non_active_ally_does_not_transfer_control(scene)
	_test_full_initiative_cycle_respects_schedule(scene)
	_test_faster_units_receive_more_future_activations(scene)
	_test_future_activation_resets_flags(scene)


func _reset_turn_fixture(scene: Control) -> void:
	scene._create_units()
	scene._initialize_initiative()
	scene._begin_next_activation()
	scene._unit_by_id("arlen")["grid"] = Vector2i(1, 1)
	scene._unit_by_id("mira")["grid"] = Vector2i(4, 1)
	scene._unit_by_id("sera")["grid"] = Vector2i(0, 4)
	scene._unit_by_id("brann")["grid"] = Vector2i(2, 6)
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(6, 1)
	scene._unit_by_id("enemy_rifle")["grid"] = Vector2i(7, 4)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 1)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 3)
	scene._begin_activation(scene._unit_by_id("arlen"))


func _test_move_once_then_second_move_rejected(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	_assert_equal(scene.active_unit["id"], "arlen", "Arlen starts active")
	_assert_true(scene._try_move_active_unit(Vector2i(2, 1)), "first Arlen move is accepted")
	_assert_true(arlen["has_moved"], "move marks has_moved")
	_assert_false(scene._can_move(arlen), "move becomes illegal after first move")
	_assert_false(scene._try_move_active_unit(Vector2i(3, 1)), "second move in same activation is rejected")
	_assert_equal(arlen["grid"], Vector2i(2, 1), "rejected second move does not change position")


func _test_move_then_attack_advances_to_next_player(scene: Control) -> void:
	_reset_turn_fixture(scene)
	_assert_true(scene._try_move_active_unit(Vector2i(2, 1)), "move before attack succeeds")
	_assert_true(scene._try_attack_active_unit(), "attack after move succeeds")
	_assert_equal(scene._unit_by_id("arlen")["activation_complete"], true, "attack completes activation")
	_assert_equal(scene.active_unit["id"], "mira", "enemy auto-resolves and Mira becomes active")
	_assert_true(scene.turn_log.has("arlen:attack"), "attack is logged")
	_assert_true(scene.turn_log.has("enemy_blade:enemy_wait"), "enemy between Arlen and Mira resolves")


func _test_attack_without_moving_advances_to_next_player(scene: Control) -> void:
	_reset_turn_fixture(scene)
	_assert_true(scene._try_attack_active_unit(), "attack without moving succeeds")
	_assert_equal(scene._unit_by_id("arlen")["has_moved"], false, "attack-only activation does not mark moved")
	_assert_equal(scene.active_unit["id"], "mira", "attack-only advances initiative")


func _test_move_then_wait_advances_to_next_player(scene: Control) -> void:
	_reset_turn_fixture(scene)
	_assert_true(scene._try_move_active_unit(Vector2i(2, 1)), "move before wait succeeds")
	_assert_true(scene._try_wait_active_unit(), "wait after move succeeds")
	_assert_equal(scene._unit_by_id("arlen")["activation_complete"], true, "wait completes activation")
	_assert_equal(scene.active_unit["id"], "mira", "move-wait advances initiative")


func _test_wait_without_moving_advances_to_next_player(scene: Control) -> void:
	_reset_turn_fixture(scene)
	_assert_true(scene._try_wait_active_unit(), "wait without moving succeeds")
	_assert_equal(scene._unit_by_id("arlen")["has_moved"], false, "wait-only activation does not mark moved")
	_assert_equal(scene.active_unit["id"], "mira", "wait-only advances initiative")


func _test_selecting_non_active_ally_does_not_transfer_control(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var mira = scene._unit_by_id("mira")
	scene._select_unit(mira)
	_assert_equal(scene.selected_unit["id"], "mira", "non-active ally can be inspected")
	_assert_equal(scene.active_unit["id"], "arlen", "active control stays with Arlen")
	_assert_false(scene._can_move(mira), "non-active ally cannot move")
	_assert_false(scene._try_move_active_unit(Vector2i(5, 1)), "Mira cannot move using Arlen activation")


func _test_full_initiative_cycle_respects_schedule(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var expected_players := ["arlen", "mira", "sera", "brann"]
	var seen_players: Array[String] = []
	for expected in expected_players:
		_assert_equal(scene.active_unit["id"], expected, "scheduled player activation")
		seen_players.append(str(scene.active_unit["id"]))
		_assert_true(scene._try_wait_active_unit(), "scheduled unit can wait")
	_assert_equal(seen_players, expected_players, "players act only in deterministic initiative order")
	_assert_true(scene.turn_log.has("enemy_blade:enemy_wait"), "enemy blade acts only when scheduled")
	_assert_true(scene.turn_log.has("enemy_rifle:enemy_wait"), "enemy rifle acts only when scheduled")
	_assert_true(scene.turn_log.has("commander:enemy_wait"), "commander acts only when scheduled")
	_assert_true(scene.turn_log.has("enemy_sniper:enemy_wait"), "enemy sniper acts only when scheduled")


func _test_faster_units_receive_more_future_activations(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var activation_counts := {}
	for _index in range(6):
		var active_id := str(scene.active_unit["id"])
		activation_counts[active_id] = int(activation_counts.get(active_id, 0)) + 1
		_assert_equal(scene.initiative_timeline[0], active_id, "front timeline unit owns the activation")
		_assert_true(scene._try_wait_active_unit(), "advance deterministic activation sample")

	_assert_true(
		int(activation_counts["arlen"]) > int(activation_counts["brann"]),
		"higher Speed unit receives more activations than slower unit over time"
	)


func _test_future_activation_resets_flags(scene: Control) -> void:
	_reset_turn_fixture(scene)
	_assert_true(scene._try_move_active_unit(Vector2i(2, 1)), "Arlen first activation move succeeds")
	_assert_true(scene._try_attack_active_unit(), "Arlen first activation attack succeeds")
	for _i in range(3):
		_assert_true(scene._try_wait_active_unit(), "advance remaining player activations")
	_assert_equal(scene.active_unit["id"], "arlen", "Arlen receives a future activation")
	_assert_equal(scene.active_unit["has_moved"], false, "future activation resets has_moved")
	_assert_equal(scene.active_unit["has_attacked"], false, "future activation resets has_attacked")
	_assert_equal(scene.active_unit["activation_complete"], false, "future activation resets activation_complete")


func _assert_true(actual: bool, message: String) -> void:
	if not actual:
		_failures.append("Expected true: %s" % message)


func _assert_false(actual: bool, message: String) -> void:
	if actual:
		_failures.append("Expected false: %s" % message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s but got %s" % [message, expected, actual])
