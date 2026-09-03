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
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_ATTACK, "attack action enters target selection")
	_assert_true(scene.targetable_tiles.has(scene._grid_key(enemy["grid"])), "attack action highlights legal targets")
	_assert_true(scene._confirm_attack_target(enemy), "confirming highlighted target resolves attack")
	_assert_equal(scene.active_unit["id"], "mira", "confirmed attack advances initiative")

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
	_run_attack_pipeline_acceptance(scene)
	_run_part_hp_acceptance(scene)
	_run_sword_acceptance(scene)

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


func _run_attack_pipeline_acceptance(scene: Control) -> void:
	var required_methods := [
		"_calculate_targetable_tiles",
		"_attack_preview",
		"_confirm_attack_target",
		"_cancel_attack_selection",
		"_try_attack_active_unit",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "attack pipeline API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_out_of_range_targets_cannot_be_confirmed(scene)
	_test_legal_target_can_be_selected_and_resolved_once(scene)
	_test_attack_cannot_be_used_twice_in_one_activation(scene)
	_test_cancel_target_selection_does_not_consume_attack(scene)
	_test_confirmed_attack_advances_initiative(scene)


func _run_part_hp_acceptance(scene: Control) -> void:
	var required_methods := [
		"_damage_part",
		"_apply_part_consequence",
		"_part_hp_ratio",
		"_overall_hp_ratio",
		"_is_unit_in_battle",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "part HP API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_each_part_takes_independent_damage(scene)
	_test_destroyed_parts_clamp_and_disable_orbs(scene)
	_test_head_destroyed_reduces_hit_preview(scene)
	_test_arm_destroyed_disables_mounted_weapon(scene)
	_test_legs_destroyed_removes_movement(scene)
	_test_body_destroyed_removes_unit_from_combat(scene)
	_test_part_state_survives_initiative_changes(scene)
	_test_placeholder_attack_damages_chosen_part(scene)


func _run_sword_acceptance(scene: Control) -> void:
	var required_methods := [
		"_weapon_data_for",
		"_roll_part_for_weapon",
		"_roll_hit",
		"_resolve_weapon_attack",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Sword API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_sword_cannot_target_beyond_range_one(scene)
	_test_sword_success_damages_exactly_one_part(scene)
	_test_sword_miss_damages_no_parts(scene)
	_test_sword_destroyed_arm_makes_weapon_unusable(scene)
	_test_sword_seed_reproduces_rolled_part(scene)
	_test_sword_ignores_manual_part_choice(scene)


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


func _set_sword_fixture(scene: Control, target_grid: Vector2i) -> Dictionary:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	arlen["weapon"] = "Sword"
	arlen["weapon_mount_part"] = "Right Arm"
	target["grid"] = target_grid
	scene._begin_activation(arlen)
	return {"attacker": arlen, "target": target}


func _part_hp_snapshot(unit) -> Dictionary:
	var snapshot := {}
	for part_name in ["Head", "Body", "Left Arm", "Right Arm", "Legs"]:
		snapshot[part_name] = int(unit["parts"][part_name]["hp"])
	return snapshot


func _changed_part_count(before: Dictionary, after: Dictionary) -> int:
	var count := 0
	for part_name in before.keys():
		if before[part_name] != after[part_name]:
			count += 1
	return count


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


func _test_out_of_range_targets_cannot_be_confirmed(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	target["grid"] = Vector2i(9, 6)
	scene._select_action("Attack")
	var preview: Dictionary = scene._attack_preview(arlen, target)
	_assert_false(preview["legal"], "out-of-range target preview is illegal")
	_assert_false(scene._confirm_attack_target(target), "out-of-range target confirmation is rejected")
	_assert_equal(scene.active_unit["id"], "arlen", "illegal target does not advance initiative")
	_assert_false(arlen["has_attacked"], "illegal target does not consume attack")


func _test_legal_target_can_be_selected_and_resolved_once(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	scene._select_action("Attack")
	var preview: Dictionary = scene._attack_preview(arlen, target)
	_assert_true(preview["legal"], "legal target preview is marked legal")
	_assert_equal(preview["hit_percent"], 80, "placeholder hit preview exposes deterministic Hit percent")
	_assert_true(scene._confirm_attack_target(target), "legal target confirmation resolves once")
	_assert_true(arlen["has_attacked"], "resolved attack marks has_attacked")
	_assert_true(arlen["activation_complete"], "resolved attack completes activation")


func _test_attack_cannot_be_used_twice_in_one_activation(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	arlen["has_attacked"] = true
	scene._select_action("Attack")
	_assert_false(scene._try_attack_active_unit(target), "already-consumed attack is rejected")
	_assert_equal(scene.active_unit["id"], "arlen", "rejected second attack does not advance initiative")


func _test_cancel_target_selection_does_not_consume_attack(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	scene._select_action("Attack")
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_ATTACK, "attack enters target-selection before cancel")
	_assert_equal(scene._preview_attack_target(arlen)["legal"], false, "previewing an ally marks target illegal")
	scene._cancel_attack_selection()
	_assert_equal(scene.active_unit["id"], "arlen", "cancel keeps current active unit")
	_assert_false(arlen["has_attacked"], "cancel does not consume attack")
	_assert_false(arlen["activation_complete"], "cancel does not complete activation")
	_assert_true(scene._can_attack(arlen), "attack remains legal after cancel")


func _test_confirmed_attack_advances_initiative(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var target = scene._unit_by_id("enemy_blade")
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(target), "confirmed attack resolves")
	_assert_equal(scene.active_unit["id"], "mira", "confirmed attack advances to next player activation")
	_assert_true(scene.turn_log.has("arlen:attack"), "confirmed attack is logged")


func _test_each_part_takes_independent_damage(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var target = scene._unit_by_id("enemy_blade")
	scene._damage_part(target, "Head", 15)
	scene._damage_part(target, "Left Arm", 40)
	_assert_equal(target["parts"]["Head"]["hp"], 65, "Head HP changes independently")
	_assert_equal(target["parts"]["Left Arm"]["hp"], 38, "Left Arm HP changes independently")
	_assert_equal(target["parts"]["Body"]["hp"], 85, "Body HP is unchanged by other part damage")


func _test_destroyed_parts_clamp_and_disable_orbs(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var target = scene._unit_by_id("enemy_blade")
	target["parts"]["Head"]["orb"] = {"id": "test_fire_orb"}
	var result: Dictionary = scene._damage_part(target, "Head", 999)
	_assert_equal(target["parts"]["Head"]["hp"], 0, "destroyed part clamps at zero")
	_assert_true(target["parts"]["Head"]["destroyed"], "destroyed flag is stored")
	_assert_true(target["parts"]["Head"]["orb_disabled"], "destroyed part disables installed Orb hook")
	_assert_equal(result["damage_applied"], 80, "damage result reports clamped applied damage")


func _test_head_destroyed_reduces_hit_preview(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	scene._damage_part(arlen, "Head", 999)
	var preview: Dictionary = scene._attack_preview(arlen, target)
	_assert_equal(preview["hit_percent"], 50, "Head destruction applies prototype accuracy penalty")


func _test_arm_destroyed_disables_mounted_weapon(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	scene._damage_part(arlen, "Right Arm", 999)
	_assert_true(arlen["weapon_disabled"], "destroying mounted weapon arm disables weapon")
	_assert_false(scene._can_attack(arlen), "unit with disabled mounted weapon cannot attack")


func _test_legs_destroyed_removes_movement(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	scene._damage_part(arlen, "Legs", 999)
	_assert_equal(arlen["current_move_range"], 0, "destroyed Legs set Move to zero")
	_assert_equal(arlen["dodge"], 0, "destroyed Legs set Dodge to zero")
	_assert_false(scene._can_move(arlen), "unit with destroyed Legs cannot move")
	_assert_equal(scene._calculate_reachable_tiles(arlen).size(), 0, "destroyed Legs expose no movement tiles")


func _test_body_destroyed_removes_unit_from_combat(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	var target_grid = target["grid"]
	scene._damage_part(target, "Body", 999)
	scene._rebuild_initiative_timeline()
	_assert_true(target["defeated"], "Body destruction defeats mech")
	_assert_false(scene._is_unit_in_battle(target), "Body-destroyed mech leaves normal combat")
	_assert_false(scene._occupied_by_any_unit(target_grid), "defeated mech no longer occupies its tile")
	_assert_false(scene._valid_attack_targets(arlen).has(target), "defeated mech is not a legal target")
	_assert_false(scene.initiative_timeline.has("enemy_blade"), "defeated mech leaves initiative")


func _test_part_state_survives_initiative_changes(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	scene._damage_part(arlen, "Head", 10)
	_assert_true(scene._try_wait_active_unit(), "advance away from damaged unit")
	_assert_equal(scene._unit_by_id("arlen")["parts"]["Head"]["hp"], 74, "part HP survives initiative changes")


func _test_placeholder_attack_damages_chosen_part(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var target = scene._unit_by_id("enemy_blade")
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(target, "Head"), "confirmed attack damages chosen part")
	_assert_equal(target["parts"]["Head"]["hp"], 55, "placeholder attack applies deterministic part damage")
	_assert_equal(scene.last_attack_result["part_name"], "Head", "attack result records damaged part")
	_assert_equal(scene.last_attack_result["damage_applied"], 25, "attack result records placeholder damage")


func _test_sword_cannot_target_beyond_range_one(scene: Control) -> void:
	var fixture := _set_sword_fixture(scene, Vector2i(3, 1))
	scene._select_action("Attack")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["range"], 1, "Sword range is data-driven as one")
	_assert_false(preview["legal"], "Sword cannot target beyond range one")
	_assert_false(scene._confirm_attack_target(fixture["target"], "", 11), "out-of-range Sword target is rejected")


func _test_sword_success_damages_exactly_one_part(scene: Control) -> void:
	var fixture := _set_sword_fixture(scene, Vector2i(2, 1))
	var before := _part_hp_snapshot(fixture["target"])
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "", 11), "Sword hit resolves against adjacent target")
	var after := _part_hp_snapshot(fixture["target"])
	_assert_equal(_changed_part_count(before, after), 1, "Sword damages exactly one part")
	_assert_equal(scene.last_attack_result["weapon"], "Sword", "Sword attack result records weapon")
	_assert_equal(scene.last_attack_result["damage_applied"], 45, "Sword applies strong single-hit damage")


func _test_sword_miss_damages_no_parts(scene: Control) -> void:
	var fixture := _set_sword_fixture(scene, Vector2i(2, 1))
	var before := _part_hp_snapshot(fixture["target"])
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "", 95), "Sword miss still consumes the attack")
	var after := _part_hp_snapshot(fixture["target"])
	_assert_equal(_changed_part_count(before, after), 0, "miss damages no part")
	_assert_false(scene.last_attack_result["hit"], "miss result is recorded")


func _test_sword_destroyed_arm_makes_weapon_unusable(scene: Control) -> void:
	var fixture := _set_sword_fixture(scene, Vector2i(2, 1))
	scene._damage_part(fixture["attacker"], "Right Arm", 999)
	_assert_true(fixture["attacker"]["weapon_disabled"], "destroyed equipped arm disables Sword")
	_assert_false(scene._can_attack(fixture["attacker"]), "Sword cannot attack with destroyed equipped arm")


func _test_sword_seed_reproduces_rolled_part(scene: Control) -> void:
	var fixture := _set_sword_fixture(scene, Vector2i(2, 1))
	var weapon_data: Dictionary = scene._weapon_data_for(fixture["attacker"])
	_assert_equal(scene._roll_part_for_weapon(weapon_data, 41), scene._roll_part_for_weapon(weapon_data, 41), "same seed reproduces same Sword part roll")
	_assert_equal(scene._roll_part_for_weapon(weapon_data, 41), "Left Arm", "Sword part roll follows data-driven weights")


func _test_sword_ignores_manual_part_choice(scene: Control) -> void:
	var fixture := _set_sword_fixture(scene, Vector2i(2, 1))
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "Head", 41), "Sword resolves even when caller passes manual part")
	_assert_equal(scene.last_attack_result["part_name"], "Left Arm", "normal Sword attack uses rolled part instead of manual part")


func _assert_true(actual: bool, message: String) -> void:
	if not actual:
		_failures.append("Expected true: %s" % message)


func _assert_false(actual: bool, message: String) -> void:
	if actual:
		_failures.append("Expected false: %s" % message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s but got %s" % [message, expected, actual])
