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
	_assert_equal(scene._height_at(Vector2i(9, 0)), 2, "rightmost band in Ancient Ruins reaches H2")
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
	_run_spear_acceptance(scene)
	_run_rifle_acceptance(scene)
	_run_sniper_acceptance(scene)
	_run_shield_acceptance(scene)
	_run_terrain_acceptance(scene)
	_run_orb_acceptance(scene)
	_run_ai_and_auto_acceptance(scene)
	_run_ancient_ruins_acceptance(scene)
	_run_crystal_quarry_acceptance(scene)
	_run_ascending_ridge_acceptance(scene)

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


func _run_spear_acceptance(scene: Control) -> void:
	var required_methods := [
		"_spear_direction",
		"_line_attack_targets",
		"_resolve_spear_attack",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Spear API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_spear_hits_tile_one_only_when_tile_two_empty(scene)
	_test_spear_hits_tile_one_and_two_enemies(scene)
	_test_spear_tile_two_receives_reduced_damage(scene)
	_test_spear_cannot_attack_diagonal_line(scene)
	_test_spear_action_consumes_one_attack(scene)


func _run_rifle_acceptance(scene: Control) -> void:
	var required_methods := [
		"_resolve_rifle_attack",
		"_volley_part_seed",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Rifle API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_rifle_uses_configured_shot_count(scene)
	_test_rifle_missed_shots_do_no_damage(scene)
	_test_rifle_successes_distribute_across_parts(scene)
	_test_rifle_seed_reproduces_volley(scene)
	_test_rifle_destroyed_arm_makes_weapon_unusable(scene)


func _run_sniper_acceptance(scene: Control) -> void:
	_test_sniper_cannot_target_inside_minimum_range(scene)
	_test_sniper_cannot_target_beyond_maximum_range(scene)
	_test_sniper_default_body_weight_is_ten_percent(scene)
	_test_sniper_seed_reproduces_precision_part_roll(scene)
	_test_sniper_missed_shot_ends_attack(scene)


func _run_shield_acceptance(scene: Control) -> void:
	var required_methods := [
		"_shield_is_active",
		"_can_shield_intercept",
		"_intercepting_shield_for",
		"_damage_shield",
		"_resolve_blockable_shot",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Shield API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_shield_valid_geometry_intercepts_protected_ally(scene)
	_test_shield_invalid_angle_does_not_intercept(scene)
	_test_shield_breaks_mid_rifle_volley_then_damage_continues(scene)
	_test_destroyed_shield_never_intercepts(scene)
	_test_shield_interception_works_for_enemy_team(scene)


func _run_terrain_acceptance(scene: Control) -> void:
	var required_methods := [
		"_create_terrain",
		"_set_tile_terrain",
		"_terrain_at",
		"_height_hit_modifier",
		"_has_cover",
		"_terrain_adjusted_damage",
		"_can_traverse_step",
		"_has_line_of_sight",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Terrain API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_height_advantage_caps_at_plus_fifteen(scene)
	_test_height_disadvantage_caps_at_minus_fifteen(scene)
	_test_equal_elevation_has_no_height_modifier(scene)
	_test_steep_elevation_step_blocks_movement(scene)
	_test_cover_modifies_preview_and_resolved_damage(scene)
	_test_los_blocker_prevents_target_selection(scene)


func _run_orb_acceptance(scene: Control) -> void:
	var required_methods := [
		"_install_orb",
		"_orb_data_for",
		"_active_orbs",
		"_orb_effects",
		"_orb_adjusted_damage",
		"_resolve_orb_proc",
		"_apply_status",
		"_has_status",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Orb API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_orb_data_includes_phase_one_elements_and_rarities(scene)
	_test_orb_passive_changes_combat_damage(scene)
	_test_orb_proc_is_seeded_and_applies_status(scene)
	_test_destroyed_host_part_disables_orb_effects(scene)
	_test_ssr_orb_supports_five_effects(scene)
	_test_orbs_do_not_add_action_buttons(scene)


func _reset_turn_fixture(scene: Control) -> void:
	scene._create_terrain()
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
	scene._unit_by_id("enemy_spear")["grid"] = Vector2i(7, 5)
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


func _set_spear_fixture(scene: Control, tile_one_grid: Vector2i, tile_two_grid: Vector2i = Vector2i(8, 6)) -> Dictionary:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var tile_one_target = scene._unit_by_id("enemy_blade")
	var tile_two_target = scene._unit_by_id("enemy_rifle")
	arlen["weapon"] = "Spear"
	arlen["weapon_mount_part"] = "Right Arm"
	tile_one_target["grid"] = tile_one_grid
	tile_two_target["grid"] = tile_two_grid
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 6)
	scene._begin_activation(arlen)
	return {"attacker": arlen, "tile_one": tile_one_target, "tile_two": tile_two_target}


func _set_rifle_fixture(scene: Control, target_grid: Vector2i = Vector2i(5, 1)) -> Dictionary:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	arlen["weapon"] = "Rifle"
	arlen["weapon_mount_part"] = "Right Arm"
	target["grid"] = target_grid
	scene._unit_by_id("enemy_rifle")["grid"] = Vector2i(8, 6)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 6)
	scene._begin_activation(arlen)
	return {"attacker": arlen, "target": target}


func _set_sniper_fixture(scene: Control, target_grid: Vector2i = Vector2i(6, 1)) -> Dictionary:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	arlen["weapon"] = "Sniper"
	arlen["weapon_mount_part"] = "Right Arm"
	target["grid"] = target_grid
	scene._unit_by_id("enemy_rifle")["grid"] = Vector2i(8, 6)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 6)
	scene._begin_activation(arlen)
	return {"attacker": arlen, "target": target}


func _set_player_shield_fixture(scene: Control, weapon := "Sniper", shield_grid := Vector2i(3, 3)) -> Dictionary:
	_reset_turn_fixture(scene)
	var attacker = scene._unit_by_id("enemy_rifle")
	var shield = scene._unit_by_id("brann")
	var protected = scene._unit_by_id("arlen")
	attacker["weapon"] = weapon
	attacker["grid"] = Vector2i(1, 3)
	shield["grid"] = shield_grid
	protected["grid"] = Vector2i(4, 3)
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(8, 6)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 6)
	return {"attacker": attacker, "shield": shield, "protected": protected}


func _set_enemy_shield_fixture(scene: Control) -> Dictionary:
	_reset_turn_fixture(scene)
	var attacker = scene._unit_by_id("sera")
	var shield = scene._unit_by_id("enemy_rifle")
	var protected = scene._unit_by_id("commander")
	attacker["weapon"] = "Rifle"
	attacker["grid"] = Vector2i(6, 3)
	shield["weapon"] = "Shield"
	shield["weapon_mount_part"] = "Left Arm"
	shield["shield_max_hp"] = 25
	shield["shield_hp"] = 25
	shield["shield_disabled"] = false
	shield["grid"] = Vector2i(4, 3)
	protected["grid"] = Vector2i(3, 3)
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(8, 6)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	return {"attacker": attacker, "shield": shield, "protected": protected}


func _set_terrain_attack_fixture(scene: Control, attacker_height: int, target_height: int, target_has_cover := false, blocker_grid = null) -> Dictionary:
	_reset_turn_fixture(scene)
	var attacker = scene._unit_by_id("mira")
	var target = scene._unit_by_id("enemy_blade")
	attacker["weapon"] = "Sniper"
	attacker["grid"] = Vector2i(1, 1)
	target["grid"] = Vector2i(4, 1)
	scene._unit_by_id("enemy_rifle")["grid"] = Vector2i(8, 4)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 6)
	scene._set_tile_terrain(attacker["grid"], {"height": attacker_height})
	scene._set_tile_terrain(target["grid"], {"height": target_height, "cover": target_has_cover})
	if blocker_grid != null:
		scene._set_tile_terrain(blocker_grid, {"blocks_los": true})
	return {"attacker": attacker, "target": target}


func _set_orb_attack_fixture(scene: Control) -> Dictionary:
	var fixture := _set_terrain_attack_fixture(scene, 1, 1)
	fixture["attacker"]["weapon"] = "Sniper"
	return fixture


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


func _volley_signature(result: Dictionary) -> Array:
	var signature := []
	for shot in result["shots"]:
		signature.append("%s:%s:%s" % [shot["shot_index"], shot["hit"], shot["part_name"]])
	return signature


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
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(3, 1)
	_assert_true(scene._try_move_active_unit(Vector2i(2, 1)), "move before attack succeeds")
	_assert_true(scene._try_attack_active_unit(), "attack after move succeeds")
	_assert_equal(scene._unit_by_id("arlen")["activation_complete"], true, "attack completes activation")
	_assert_equal(scene.active_unit["id"], "mira", "enemy auto-resolves and Mira becomes active")
	_assert_true(scene.turn_log.has("arlen:attack"), "attack is logged")
	_assert_true(scene.turn_log.has("enemy_blade:enemy_wait") or scene.turn_log.has("enemy_blade:attack"), "enemy between Arlen and Mira resolves")


func _test_attack_without_moving_advances_to_next_player(scene: Control) -> void:
	_reset_turn_fixture(scene)
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(2, 1)
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
	_assert_true(scene.turn_log.has("enemy_blade:enemy_wait") or scene.turn_log.has("enemy_blade:attack"), "enemy blade acts only when scheduled")
	_assert_true(scene.turn_log.has("enemy_rifle:enemy_wait") or scene.turn_log.has("enemy_rifle:attack"), "enemy rifle acts only when scheduled")
	_assert_true(scene.turn_log.has("enemy_spear:enemy_wait") or scene.turn_log.has("enemy_spear:attack") or scene.turn_log.has("enemy_spear:enemy_attack"), "enemy spear acts only when scheduled")
	_assert_true(scene.turn_log.has("commander:enemy_wait") or scene.turn_log.has("commander:attack"), "commander acts only when scheduled")

	_assert_true(scene.turn_log.has("enemy_sniper:enemy_wait") or scene.turn_log.has("enemy_sniper:attack"), "enemy sniper acts only when scheduled")


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
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(3, 1)
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
	target["grid"] = Vector2i(2, 1)
	scene._set_tile_terrain(arlen["grid"], {"height": 0})
	scene._set_tile_terrain(target["grid"], {"height": 0})
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
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(2, 1)
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
	target["grid"] = Vector2i(2, 1)
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
	target["grid"] = Vector2i(2, 1)
	scene._set_tile_terrain(arlen["grid"], {"height": 0})
	scene._set_tile_terrain(target["grid"], {"height": 0})
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
	scene._unit_by_id("arlen")["weapon"] = "Commander"
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


func _test_spear_hits_tile_one_only_when_tile_two_empty(scene: Control) -> void:
	var fixture := _set_spear_fixture(scene, Vector2i(2, 1))
	var tile_one_before := _part_hp_snapshot(fixture["tile_one"])
	var tile_two_before := _part_hp_snapshot(fixture["tile_two"])
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["tile_one"], "", 11), "Spear resolves against orthogonal tile-one target")
	_assert_equal(scene.last_attack_result["results"].size(), 1, "Spear hits only tile one when tile two is empty")
	_assert_equal(_changed_part_count(tile_one_before, _part_hp_snapshot(fixture["tile_one"])), 1, "tile-one enemy takes one part hit")
	_assert_equal(_changed_part_count(tile_two_before, _part_hp_snapshot(fixture["tile_two"])), 0, "empty tile-two lane target remains untouched")


func _test_spear_hits_tile_one_and_two_enemies(scene: Control) -> void:
	var fixture := _set_spear_fixture(scene, Vector2i(2, 1), Vector2i(3, 1))
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["tile_one"], "", 11), "Spear resolves through two occupied line tiles")
	_assert_equal(scene.last_attack_result["results"].size(), 2, "Spear can hit enemies on tile one and tile two in one action")
	_assert_equal(scene.last_attack_result["results"][0]["target_id"], "enemy_blade", "first Spear result is tile-one enemy")
	_assert_equal(scene.last_attack_result["results"][1]["target_id"], "enemy_rifle", "second Spear result is tile-two enemy")


func _test_spear_tile_two_receives_reduced_damage(scene: Control) -> void:
	var fixture := _set_spear_fixture(scene, Vector2i(2, 1), Vector2i(3, 1))
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["tile_one"], "", 11), "Spear resolves for damage comparison")
	_assert_equal(scene.last_attack_result["results"][0]["damage_applied"], 30, "tile-one Spear damage uses full base value")
	_assert_equal(scene.last_attack_result["results"][1]["damage_applied"], 22, "tile-two Spear damage uses reduced prototype value")


func _test_spear_cannot_attack_diagonal_line(scene: Control) -> void:
	var fixture := _set_spear_fixture(scene, Vector2i(2, 2), Vector2i(8, 6))
	scene._select_action("Attack")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["tile_one"])
	_assert_false(preview["legal"], "Spear cannot attack diagonally")
	_assert_equal(scene._spear_direction(fixture["attacker"], fixture["tile_one"]), Vector2i.ZERO, "diagonal target has no Spear direction")
	_assert_false(scene._confirm_attack_target(fixture["tile_one"], "", 11), "diagonal Spear target is rejected")


func _test_spear_action_consumes_one_attack(scene: Control) -> void:
	var fixture := _set_spear_fixture(scene, Vector2i(2, 1), Vector2i(3, 1))
	var arlen = fixture["attacker"]
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["tile_one"], "", 11), "Spear action resolves")
	_assert_true(arlen["has_attacked"], "Spear marks has_attacked")
	_assert_true(arlen["activation_complete"], "Spear completes activation")
	_assert_equal(scene.active_unit["id"], "mira", "Spear attack advances initiative once")
	_assert_false(scene.turn_log.has("arlen:attack:extra"), "Spear does not log an extra attack")


func _test_rifle_uses_configured_shot_count(scene: Control) -> void:
	var fixture := _set_rifle_fixture(scene)
	var weapon_data: Dictionary = scene._weapon_data_for(fixture["attacker"])
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "", 11), "Rifle volley resolves")
	_assert_equal(scene.last_attack_result["shots"].size(), int(weapon_data["shot_count"]), "Rifle produces configured shot attempts")
	_assert_equal(scene.active_unit["id"], "mira", "Rifle volley consumes one attack activation")


func _test_rifle_missed_shots_do_no_damage(scene: Control) -> void:
	var fixture := _set_rifle_fixture(scene)
	var before := _part_hp_snapshot(fixture["target"])
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "", 95), "Rifle all-miss volley still resolves")
	var after := _part_hp_snapshot(fixture["target"])
	_assert_equal(_changed_part_count(before, after), 0, "Rifle misses do no damage")
	for shot in scene.last_attack_result["shots"]:
		_assert_false(shot["hit"], "high-seed Rifle shot misses")


func _test_rifle_successes_distribute_across_parts(scene: Control) -> void:
	var fixture := _set_rifle_fixture(scene)
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "", 21), "Rifle hit volley resolves")
	var hit_parts := {}
	for shot in scene.last_attack_result["shots"]:
		if bool(shot["hit"]):
			hit_parts[shot["part_name"]] = true
	_assert_true(hit_parts.size() > 1, "Rifle successful shots can distribute across multiple parts")


func _test_rifle_seed_reproduces_volley(scene: Control) -> void:
	var first_fixture := _set_rifle_fixture(scene)
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(first_fixture["target"], "", 21), "first Rifle volley resolves")
	var first_signature := _volley_signature(scene.last_attack_result)
	var second_fixture := _set_rifle_fixture(scene)
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(second_fixture["target"], "", 21), "second Rifle volley resolves")
	_assert_equal(_volley_signature(scene.last_attack_result), first_signature, "same seed reproduces Rifle volley")


func _test_rifle_destroyed_arm_makes_weapon_unusable(scene: Control) -> void:
	var fixture := _set_rifle_fixture(scene)
	scene._damage_part(fixture["attacker"], "Right Arm", 999)
	_assert_true(fixture["attacker"]["weapon_disabled"], "destroyed equipped arm disables Rifle")
	_assert_false(scene._can_attack(fixture["attacker"]), "Rifle cannot attack with destroyed equipped arm")


func _test_sniper_cannot_target_inside_minimum_range(scene: Control) -> void:
	var fixture := _set_sniper_fixture(scene, Vector2i(2, 1))
	scene._select_action("Attack")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["min_range"], 2, "Sniper exposes data-driven minimum range")
	_assert_false(preview["legal"], "Sniper cannot target adjacent enemies")
	_assert_false(scene._confirm_attack_target(fixture["target"], "", 11), "inside-minimum Sniper target is rejected")


func _test_sniper_cannot_target_beyond_maximum_range(scene: Control) -> void:
	var fixture := _set_sniper_fixture(scene, Vector2i(8, 1))
	scene._select_action("Attack")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["range"], 6, "Sniper exposes data-driven maximum range")
	_assert_false(preview["legal"], "Sniper cannot target beyond maximum range")


func _test_sniper_default_body_weight_is_ten_percent(scene: Control) -> void:
	var fixture := _set_sniper_fixture(scene)
	var weapon_data: Dictionary = scene._weapon_data_for(fixture["attacker"])
	_assert_equal(int(weapon_data["damage"]), 35, "Sniper damage stays below Sword burst")
	_assert_equal(int(weapon_data["part_weights"]["Body"]), 10, "Sniper Body weight is exactly 10 percent")


func _test_sniper_seed_reproduces_precision_part_roll(scene: Control) -> void:
	var fixture := _set_sniper_fixture(scene)
	var weapon_data: Dictionary = scene._weapon_data_for(fixture["attacker"])
	_assert_equal(scene._roll_part_for_weapon(weapon_data, 35), scene._roll_part_for_weapon(weapon_data, 35), "same seed reproduces Sniper part roll")
	_assert_equal(scene._roll_part_for_weapon(weapon_data, 35), "Body", "Sniper seed follows weighted Body slot")


func _test_sniper_missed_shot_ends_attack(scene: Control) -> void:
	var fixture := _set_sniper_fixture(scene)
	var before := _part_hp_snapshot(fixture["target"])
	scene._select_action("Attack")
	_assert_true(scene._confirm_attack_target(fixture["target"], "", 95), "Sniper miss resolves and consumes Attack")
	_assert_false(scene.last_attack_result["hit"], "Sniper miss records miss result")
	_assert_equal(_changed_part_count(before, _part_hp_snapshot(fixture["target"])), 0, "Sniper miss deals no damage")
	_assert_true(fixture["attacker"]["has_attacked"], "Sniper miss marks has_attacked")
	_assert_true(fixture["attacker"]["activation_complete"], "Sniper miss completes activation")
	_assert_equal(scene.active_unit["id"], "mira", "Sniper miss advances initiative")


func _test_shield_valid_geometry_intercepts_protected_ally(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene)
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = scene._resolve_blockable_shot(fixture["attacker"], fixture["protected"], preview, "", 11, 35, 11)
	_assert_true(result["intercepted"], "valid shield geometry intercepts protected ally")
	_assert_equal(result["target_id"], "brann", "intercept redirects damage to shield bearer")
	_assert_equal(result["part_name"], "Shield", "intercepted damage lands on Shield HP")
	_assert_equal(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])), 0, "protected ally takes no damage from intercepted shot")


func _test_shield_invalid_angle_does_not_intercept(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene, "Sniper", Vector2i(4, 4))
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = scene._resolve_blockable_shot(fixture["attacker"], fixture["protected"], preview, "", 11, 35, 11)
	_assert_false(result.get("intercepted", false), "off-angle shield does not intercept")
	_assert_true(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])) > 0, "invalid angle lets target take normal damage")


func _test_shield_breaks_mid_rifle_volley_then_damage_continues(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene, "Rifle")
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = scene._resolve_rifle_attack(fixture["attacker"], fixture["protected"], preview, 11)
	_assert_equal(fixture["shield"]["shield_hp"], 0, "Rifle volley breaks Shield HP")
	_assert_true(fixture["shield"]["shield_disabled"], "broken Shield disables interception")
	_assert_true(result["shots"][0]["intercepted"], "first Rifle shot is intercepted")
	_assert_false(result["shots"][3].get("intercepted", false), "post-break Rifle shot continues to protected target")
	_assert_true(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])) > 0, "remaining volley damage reaches protected ally after shield break")


func _test_destroyed_shield_never_intercepts(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene)
	scene._damage_shield(fixture["shield"], 999)
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = scene._resolve_blockable_shot(fixture["attacker"], fixture["protected"], preview, "", 11, 35, 11)
	_assert_false(result.get("intercepted", false), "destroyed shield does not intercept")
	_assert_true(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])) > 0, "destroyed shield lets damage hit protected target")


func _test_shield_interception_works_for_enemy_team(scene: Control) -> void:
	var fixture := _set_enemy_shield_fixture(scene)
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = scene._resolve_blockable_shot(fixture["attacker"], fixture["protected"], preview, "", 11, 10, 11)
	_assert_true(result["intercepted"], "enemy shield can intercept for enemy ally")
	_assert_equal(result["target_id"], "enemy_rifle", "enemy shield bearer receives intercepted hit")
	_assert_equal(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])), 0, "enemy protected unit takes no damage from intercepted shot")


func _test_height_advantage_caps_at_plus_fifteen(scene: Control) -> void:
	var fixture := _set_terrain_attack_fixture(scene, 4, 0)
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["height_hit_modifier"], 15, "H4 shooting H0 caps height bonus at +15")
	_assert_equal(preview["hit_percent"], 95, "height advantage applies to preview hit percent")


func _test_height_disadvantage_caps_at_minus_fifteen(scene: Control) -> void:
	var fixture := _set_terrain_attack_fixture(scene, 0, 4)
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["height_hit_modifier"], -15, "H0 shooting H4 caps height penalty at -15")
	_assert_equal(preview["hit_percent"], 65, "height disadvantage applies to preview hit percent")


func _test_equal_elevation_has_no_height_modifier(scene: Control) -> void:
	var fixture := _set_terrain_attack_fixture(scene, 2, 2)
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["height_hit_modifier"], 0, "equal elevation has no height modifier")
	_assert_equal(preview["hit_percent"], 80, "equal elevation keeps base hit percent")


func _test_steep_elevation_step_blocks_movement(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var arlen = scene._unit_by_id("arlen")
	arlen["grid"] = Vector2i(1, 1)
	scene._set_tile_terrain(Vector2i(1, 1), {"height": 0})
	scene._set_tile_terrain(Vector2i(2, 1), {"height": 2})
	_assert_false(scene._can_traverse_step(Vector2i(1, 1), Vector2i(2, 1)), "movement cannot cross elevation difference greater than one")


func _test_cover_modifies_preview_and_resolved_damage(scene: Control) -> void:
	var fixture := _set_terrain_attack_fixture(scene, 1, 1, true)
	var target_before := _part_hp_snapshot(fixture["target"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["cover_dodge_modifier"], -10, "cover applies data-driven dodge penalty to incoming hit")
	_assert_true(int(preview["damage"]) < 35, "cover reduces incoming preview damage")
	var result: Dictionary = scene._resolve_weapon_attack(fixture["attacker"], fixture["target"], preview, "", 11, 35, 11)
	_assert_equal(result["damage_requested"], preview["damage"], "resolved attack uses preview cover-adjusted damage")
	_assert_true(_changed_part_count(target_before, _part_hp_snapshot(fixture["target"])) > 0, "covered target still takes reduced damage on hit")


func _test_los_blocker_prevents_target_selection(scene: Control) -> void:
	var fixture := _set_terrain_attack_fixture(scene, 1, 1, false, Vector2i(2, 1))
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	var targetable: Dictionary = scene._calculate_targetable_tiles(fixture["attacker"])
	_assert_false(scene._has_line_of_sight(fixture["attacker"]["grid"], fixture["target"]["grid"]), "terrain blocker breaks grid-ray LOS")
	_assert_false(preview["legal"], "LOS blocker makes attack preview illegal")
	_assert_false(targetable.has(scene._grid_key(fixture["target"]["grid"])), "LOS-blocked target is not selectable")


func _test_orb_data_includes_phase_one_elements_and_rarities(scene: Control) -> void:
	var elements := []
	var rarities := []
	for orb_id in scene.ORB_DATA.keys():
		var orb: Dictionary = scene.ORB_DATA[orb_id]
		if not elements.has(str(orb["element"])):
			elements.append(str(orb["element"]))
		if not rarities.has(str(orb["rarity"])):
			rarities.append(str(orb["rarity"]))
	for element in ["Fire", "Water", "Lightning", "Earth"]:
		_assert_true(elements.has(element), "Orb data includes %s element" % element)
	for rarity in ["N", "R", "SR", "SSR"]:
		_assert_true(rarities.has(rarity), "Orb data includes %s rarity" % rarity)


func _test_orb_passive_changes_combat_damage(scene: Control) -> void:
	var fixture := _set_orb_attack_fixture(scene)
	_assert_true(scene._install_orb(fixture["attacker"], "Right Arm", "fire_n"), "Fire N Orb installs into one part slot")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	_assert_equal(preview["orb_damage_modifier_percent"], 10, "Fire passive contributes damage modifier")
	_assert_true(int(preview["damage"]) > 35, "Orb passive increases preview damage")
	var result: Dictionary = scene._resolve_weapon_attack(fixture["attacker"], fixture["target"], preview, "", 11, 35, 11)
	_assert_equal(result["damage_requested"], preview["damage"], "resolved attack uses Orb-adjusted damage")


func _test_orb_proc_is_seeded_and_applies_status(scene: Control) -> void:
	var fixture := _set_orb_attack_fixture(scene)
	_assert_true(scene._install_orb(fixture["attacker"], "Left Arm", "lightning_r"), "Lightning R Orb installs")
	var first: Dictionary = scene._resolve_orb_proc(fixture["attacker"], fixture["target"], 12)
	var second: Dictionary = scene._resolve_orb_proc(fixture["attacker"], fixture["target"], 12)
	_assert_equal(first, second, "Orb proc result is reproduced by deterministic seed")
	_assert_true(first["triggered"], "seeded proc can trigger")
	_assert_equal(first["status"], "Shock", "Lightning proc applies configured status")
	_assert_true(scene._has_status(fixture["target"], "Shock"), "target status list records proc result")


func _test_destroyed_host_part_disables_orb_effects(scene: Control) -> void:
	var fixture := _set_orb_attack_fixture(scene)
	var attacker = fixture["attacker"]
	_assert_true(scene._install_orb(attacker, "Head", "fire_n"), "Orb installs on Head slot")
	var boosted_preview: Dictionary = scene._attack_preview(attacker, fixture["target"])
	_assert_true(int(boosted_preview["damage"]) > 35, "installed Orb affects damage before host part destruction")
	scene._damage_part(attacker, "Head", 999)
	var disabled_preview: Dictionary = scene._attack_preview(attacker, fixture["target"])
	_assert_true(attacker["parts"]["Head"]["orb_disabled"], "destroyed host part marks Orb disabled")
	_assert_equal(disabled_preview["orb_damage_modifier_percent"], 0, "destroyed host part disables Orb passive effects")
	_assert_equal(disabled_preview["damage"], 35, "disabled Orb no longer changes damage")


func _test_ssr_orb_supports_five_effects(scene: Control) -> void:
	var orb: Dictionary = scene._orb_data_for("earth_ssr")
	_assert_equal(str(orb["rarity"]), "SSR", "SSR Orb data resolves")
	_assert_equal(orb["effects"].size(), 5, "SSR Orb data supports five simultaneous effects")


func _test_orbs_do_not_add_action_buttons(scene: Control) -> void:
	_assert_equal(scene.PRIMARY_ACTIONS, ["Move", "Attack", "Wait"], "Orb framework does not add active skill buttons")
	_assert_false(scene.PRIMARY_ACTIONS.has("Orb"), "Orb is not a Phase 1 command")


func _run_ai_and_auto_acceptance(scene: Control) -> void:
	var required_methods := [
		"_resolve_ai_activation",
		"_decide_ai_action",
		"_score_attack_option",
		"_score_move_tile",
		"_opponents_of",
		"_primary_objective_target",
		"_next_simulation_seed",
		"run_auto_battle",
		"_is_battle_over",
		"_battle_winner",
		"_battle_summary",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "AI / auto API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_enemy_ai_moves_and_attacks_legally(scene)
	_test_ai_respects_shield_interception(scene)
	_test_ai_prefers_higher_elevation_when_moving(scene)
	_test_auto_battle_deterministic_simulation(scene)
	_test_auto_battle_completes_to_game_over(scene)


func _test_enemy_ai_moves_and_attacks_legally(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var enemy = scene._unit_by_id("enemy_blade")
	var target = scene._unit_by_id("arlen")
	scene._unit_by_id("mira")["grid"] = Vector2i(0, 6)
	enemy["grid"] = Vector2i(3, 1)
	target["grid"] = Vector2i(1, 1)

	scene._begin_activation(enemy)
	var decision: Dictionary = scene._decide_ai_action(enemy)
	_assert_equal(decision["action"], "Attack", "AI chooses Attack when in striking distance")
	_assert_equal(decision["move_to"], Vector2i(2, 1), "AI steps into range 1 to attack Arlen")
	_assert_equal(decision["target"]["id"], "arlen", "AI targets Arlen")
	var hp_before := _part_hp_snapshot(target)
	scene._resolve_enemy_activation(enemy)
	_assert_equal(enemy["grid"], Vector2i(2, 1), "AI moved legally to planned tile")
	_assert_true(enemy["has_moved"], "AI move consumed movement")
	_assert_true(enemy["has_attacked"], "AI attack consumed attack action")
	var hp_after := _part_hp_snapshot(target)
	_assert_true(_changed_part_count(hp_before, hp_after) > 0, "target took damage from legal AI attack")


func _test_ai_respects_shield_interception(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var enemy = scene._unit_by_id("enemy_rifle")
	var shield = scene._unit_by_id("brann")
	var protected = scene._unit_by_id("arlen")
	var open_target = scene._unit_by_id("sera")
	enemy["grid"] = Vector2i(1, 3)
	shield["grid"] = Vector2i(3, 3)
	protected["grid"] = Vector2i(4, 3)
	open_target["grid"] = Vector2i(1, 5)
	scene._begin_activation(enemy)
	var decision: Dictionary = scene._decide_ai_action(enemy)
	_assert_equal(decision["action"], "Attack", "AI chooses Attack")
	_assert_equal(decision["target"]["id"], "sera", "AI avoids shielded target and attacks unshielded target")


func _test_ai_prefers_higher_elevation_when_moving(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var enemy = scene._unit_by_id("enemy_sniper")
	var target = scene._unit_by_id("arlen")
	enemy["grid"] = Vector2i(7, 3)
	target["grid"] = Vector2i(1, 3)
	scene._set_tile_terrain(Vector2i(6, 3), {"height": 2})
	scene._set_tile_terrain(Vector2i(7, 3), {"height": 1})
	scene._begin_activation(enemy)
	var score_high: float = scene._score_move_tile(enemy, Vector2i(6, 3), target["grid"])
	var score_low: float = scene._score_move_tile(enemy, Vector2i(7, 4), target["grid"])
	_assert_true(score_high > score_low, "AI scores high ground move higher than low ground")


func _test_auto_battle_deterministic_simulation(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var result_one: Dictionary = scene.run_auto_battle(40, 42)
	_reset_turn_fixture(scene)
	var result_two: Dictionary = scene.run_auto_battle(40, 42)
	_assert_equal(result_one["winner"], result_two["winner"], "deterministic auto battle produces same winner")
	_assert_equal(result_one["turns"], result_two["turns"], "deterministic auto battle produces same turn count")
	_assert_equal(result_one["player_survivors"], result_two["player_survivors"], "deterministic auto battle produces same player survivors")
	_assert_equal(result_one["enemy_survivors"], result_two["enemy_survivors"], "deterministic auto battle produces same enemy survivors")
	_assert_equal(result_one["turn_log"], result_two["turn_log"], "deterministic auto battle produces identical log")


func _test_auto_battle_completes_to_game_over(scene: Control) -> void:
	_reset_turn_fixture(scene)
	var summary: Dictionary = scene.run_auto_battle(120, 1337)
	_assert_true(summary["is_over"], "auto battle runs to completion")
	_assert_true(summary["winner"] == "player" or summary["winner"] == "enemy", "auto battle declares winner")
	_assert_true(scene._is_battle_over(), "_is_battle_over reports true when complete")


func _run_ancient_ruins_acceptance(scene: Control) -> void:
	_test_ancient_ruins_commander_defeat_ends_battle_immediately(scene)
	_test_ancient_ruins_killing_non_commander_does_not_end_mission(scene)
	_test_ancient_ruins_terrain_has_no_mandatory_choke_and_modest_height(scene)
	_test_ancient_ruins_auto_battle_reproducible(scene)


func _test_ancient_ruins_commander_defeat_ends_battle_immediately(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var commander = scene._unit_by_id("commander")
	var blade = scene._unit_by_id("enemy_blade")
	_assert_true(scene._is_unit_in_battle(blade), "enemy blade alive before commander defeat")
	_assert_false(scene._is_battle_over(), "battle not over initially")
	scene._damage_part(commander, "Body", 999)
	_assert_false(scene._is_unit_in_battle(commander), "commander is defeated")
	_assert_true(scene._is_battle_over(), "destroying commander ends battle immediately")
	_assert_equal(scene._battle_winner(), "player", "player wins when commander is defeated")
	var summary: Dictionary = scene._battle_summary()
	_assert_true(summary["commander_defeated"], "summary records commander defeated")
	_assert_equal(summary["mission_id"], "ancient_ruins", "summary records ancient_ruins mission id")


func _test_ancient_ruins_killing_non_commander_does_not_end_mission(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var blade = scene._unit_by_id("enemy_blade")
	var commander = scene._unit_by_id("commander")
	scene._damage_part(blade, "Body", 999)
	_assert_false(scene._is_unit_in_battle(blade), "enemy blade is defeated")
	_assert_true(scene._is_unit_in_battle(commander), "commander is still in battle")
	_assert_false(scene._is_battle_over(), "killing non-commander enemy does not end mission")
	_assert_equal(scene._battle_winner(), "", "no winner while commander lives")


func _test_ancient_ruins_terrain_has_no_mandatory_choke_and_modest_height(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	for x in range(scene.GRID_COLUMNS):
		var walkable_in_col := 0
		for y in range(scene.GRID_ROWS):
			var grid := Vector2i(x, y)
			var h: int = scene._height_at(grid)
			_assert_true(h >= 0 and h <= 2, "Ancient Ruins heights are within modest H0-H2")
			walkable_in_col += 1
		_assert_true(walkable_in_col >= 2, "lane width is at least 2 without mandatory 1-tile bottlenecks")


func _test_ancient_ruins_auto_battle_reproducible(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var run1: Dictionary = scene.run_auto_battle(30, 1337)
	scene._load_mission("ancient_ruins")
	var run2: Dictionary = scene.run_auto_battle(30, 1337)
	_assert_equal(run1["winner"], run2["winner"], "Ancient Ruins Auto reproducible winner")
	_assert_equal(run1["turns"], run2["turns"], "Ancient Ruins Auto reproducible turns")
	_assert_equal(run1["commander_defeated"], run2["commander_defeated"], "Ancient Ruins Auto reproducible commander outcome")



func _run_crystal_quarry_acceptance(scene: Control) -> void:
	_test_crystal_quarry_objective_requires_all_enemies_defeated(scene)
	_test_crystal_quarry_victory_grants_automatic_loot(scene)
	_test_crystal_quarry_no_loot_pickup_interaction_on_battlefield(scene)
	_test_crystal_quarry_loot_distribution_reproducible_and_rarity_weighted(scene)
	_test_crystal_quarry_auto_battle_completes_deterministically(scene)


func _test_crystal_quarry_objective_requires_all_enemies_defeated(scene: Control) -> void:
	scene._load_mission("crystal_quarry")
	_assert_equal(scene.current_mission, "crystal_quarry", "Crystal Quarry is loaded")
	_assert_equal(_count_team(scene.units, "player"), 4, "four player units in Crystal Quarry")
	_assert_equal(_count_team(scene.units, "enemy"), 4, "four scavenger enemies in Crystal Quarry")
	var alpha = scene._unit_by_id("scavenger_alpha")
	var beta = scene._unit_by_id("scavenger_beta")
	var gamma = scene._unit_by_id("scavenger_gamma")
	var delta = scene._unit_by_id("scavenger_delta")
	scene._damage_part(alpha, "Body", 999)
	_assert_false(scene._is_unit_in_battle(alpha), "scavenger alpha defeated")
	_assert_false(scene._is_battle_over(), "defeat_all objective does not end after 1 enemy killed")
	_assert_equal(scene._battle_winner(), "", "no winner while other scavengers alive")
	scene._damage_part(beta, "Body", 999)
	scene._damage_part(gamma, "Body", 999)
	_assert_false(scene._is_battle_over(), "defeat_all objective does not end with 1 enemy remaining")
	scene._damage_part(delta, "Body", 999)
	_assert_true(scene._is_battle_over(), "defeat_all objective triggers victory when all 4 scavengers destroyed")
	_assert_equal(scene._battle_winner(), "player", "player is declared winner")


func _test_crystal_quarry_victory_grants_automatic_loot(scene: Control) -> void:
	scene._load_mission("crystal_quarry")
	for id in ["scavenger_alpha", "scavenger_beta", "scavenger_gamma", "scavenger_delta"]:
		scene._damage_part(scene._unit_by_id(id), "Body", 999)
	_assert_true(scene._is_battle_over(), "battle complete")
	var summary: Dictionary = scene._battle_summary(10)
	_assert_true(summary.has("loot"), "summary has loot dictionary")
	var loot: Dictionary = summary["loot"]
	_assert_equal(loot["credits"], 500, "500 credits awarded automatically on victory")
	_assert_equal(loot["arcane_ore"], 15, "15 arcane ore awarded automatically")
	_assert_equal(loot["orb_fragments"], 8, "8 orb fragments awarded automatically")
	_assert_true(loot["orb_drop"] in ["Fire Orb", "Water Orb", "Electric Orb", "Earth Orb"], "valid orb drop awarded")


func _test_crystal_quarry_no_loot_pickup_interaction_on_battlefield(scene: Control) -> void:
	scene._load_mission("crystal_quarry")
	_assert_equal(scene.PRIMARY_ACTIONS.size(), 3, "only 3 primary actions exist")
	_assert_true(scene.PRIMARY_ACTIONS.has("Move"), "Move action exists")
	_assert_true(scene.PRIMARY_ACTIONS.has("Attack"), "Attack action exists")
	_assert_true(scene.PRIMARY_ACTIONS.has("Wait"), "Wait action exists")
	_assert_false(scene.PRIMARY_ACTIONS.has("Pick Up"), "no Pick Up action exists")
	_assert_false(scene.PRIMARY_ACTIONS.has("Collect"), "no Collect action exists")


func _test_crystal_quarry_loot_distribution_reproducible_and_rarity_weighted(scene: Control) -> void:
	var loot_a: Dictionary = scene._roll_mission_loot("crystal_quarry", 999)
	var loot_b: Dictionary = scene._roll_mission_loot("crystal_quarry", 999)
	_assert_equal(loot_a["orb_drop"], loot_b["orb_drop"], "same seed produces same orb drop")
	_assert_equal(loot_a["credits"], loot_b["credits"], "same credits")
	var loot_empty: Dictionary = scene._roll_mission_loot("nonexistent_mission", 999)
	_assert_true(loot_empty.is_empty(), "unconfigured mission returns empty loot")


func _test_crystal_quarry_auto_battle_completes_deterministically(scene: Control) -> void:
	scene._load_mission("crystal_quarry")
	var run1: Dictionary = scene.run_auto_battle(65, 1337)
	scene._load_mission("crystal_quarry")
	var run2: Dictionary = scene.run_auto_battle(65, 1337)
	_assert_equal(run1["winner"], run2["winner"], "Crystal Quarry Auto reproducible winner")
	_assert_equal(run1["turns"], run2["turns"], "Crystal Quarry Auto reproducible turns")
	_assert_true(run1["is_over"], "Crystal Quarry Auto battle completes")


func _run_ascending_ridge_acceptance(scene: Control) -> void:
	_test_ascending_ridge_no_adjacent_step_exceeds_one_elevation(scene)
	_test_ascending_ridge_height_hit_modifier_clamps_at_cap(scene)
	_test_ascending_ridge_swapping_sides_alters_tactical_outcome(scene)
	_test_ascending_ridge_melee_can_reach_combat_via_slope(scene)
	_test_ascending_ridge_shield_protects_uphill_advancing_formation(scene)


func _test_ascending_ridge_no_adjacent_step_exceeds_one_elevation(scene: Control) -> void:
	scene._load_mission("ascending_ridge")
	var min_h := 99
	var max_h := -99
	for x in range(scene.GRID_COLUMNS):
		for y in range(scene.GRID_ROWS):
			var grid := Vector2i(x, y)
			var h: int = scene._height_at(grid)
			if h < min_h: min_h = h
			if h > max_h: max_h = h
			for dir in scene.DIRECTIONS:
				var neighbor: Vector2i = grid + dir
				if scene._is_in_bounds(neighbor):
					var nh: int = scene._height_at(neighbor)
					_assert_true(abs(h - nh) <= 1, "slope step delta at (%d,%d)->(%d,%d) is <= 1" % [x, y, neighbor.x, neighbor.y])

	_assert_equal(min_h, 0, "Ascending Ridge minimum elevation is H0")
	_assert_equal(max_h, 4, "Ascending Ridge maximum elevation is H4")


func _test_ascending_ridge_height_hit_modifier_clamps_at_cap(scene: Control) -> void:
	scene._load_mission("ascending_ridge")
	var low_unit = scene._unit_by_id("arlen")
	var high_unit = scene._unit_by_id("commander")
	low_unit["grid"] = Vector2i(0, 3)
	high_unit["grid"] = Vector2i(9, 3)
	var uphill_mod: int = scene._height_hit_modifier(low_unit, high_unit)
	var downhill_mod: int = scene._height_hit_modifier(high_unit, low_unit)
	_assert_equal(uphill_mod, -15, "uphill attack from H0 to H4 clamps at -15% hit")
	_assert_equal(downhill_mod, 15, "downhill attack from H4 to H0 clamps at +15% hit")


func _test_ascending_ridge_swapping_sides_alters_tactical_outcome(scene: Control) -> void:
	scene._load_mission("ascending_ridge", false)
	var arlen_uphill = scene._unit_by_id("arlen")
	_assert_true(arlen_uphill["grid"].x <= 2, "normal deployment starts player on low ground")
	var uphill_summary: Dictionary = scene.run_auto_battle(40, 1337)
	_assert_false(uphill_summary["swapped_sides"], "uphill summary records swapped_sides false")

	scene._load_mission("ascending_ridge", true)
	var arlen_downhill = scene._unit_by_id("arlen")
	_assert_true(arlen_downhill["grid"].x >= 7, "swapped deployment starts player on high ground")
	var downhill_summary: Dictionary = scene.run_auto_battle(40, 1337)
	_assert_true(downhill_summary["swapped_sides"], "downhill summary records swapped_sides true")
	_assert_true(uphill_summary["destroyed_parts"] != downhill_summary["destroyed_parts"], "uphill and downhill runs produce different tactical outcomes")



func _test_ascending_ridge_melee_can_reach_combat_via_slope(scene: Control) -> void:
	scene._load_mission("ascending_ridge", false)
	var blade = scene._unit_by_id("enemy_blade")
	blade["grid"] = Vector2i(6, 3)
	var arlen = scene._unit_by_id("arlen")
	arlen["grid"] = Vector2i(4, 3)
	var reachable: Dictionary = scene._calculate_reachable_tiles(arlen)
	_assert_true(reachable.has(scene._grid_key(Vector2i(5, 3))), "melee unit can legally step uphill toward target")


func _test_ascending_ridge_shield_protects_uphill_advancing_formation(scene: Control) -> void:
	scene._load_mission("ascending_ridge", false)
	var brann = scene._unit_by_id("brann")
	var mira = scene._unit_by_id("mira")
	var enemy_sniper = scene._unit_by_id("enemy_sniper")
	brann["grid"] = Vector2i(5, 3)
	mira["grid"] = Vector2i(4, 3)
	enemy_sniper["grid"] = Vector2i(8, 3)
	scene._begin_activation(enemy_sniper)
	var interceptor = scene._intercepting_shield_for(enemy_sniper, mira)
	_assert_equal(interceptor["id"], "brann", "shield formation intercepts downhill sniper shot targeting ally behind shield")


func _assert_true(actual: bool, message: String) -> void:




	if not actual:
		_failures.append("Expected true: %s" % message)


func _assert_false(actual: bool, message: String) -> void:
	if actual:
		_failures.append("Expected false: %s" % message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s but got %s" % [message, expected, actual])
