extends SceneTree

const MechBuildModelScript := preload("res://src/data/mech_build_model.gd")
const HangarScreenScript := preload("res://src/ui/hangar_screen.gd")

var _failures: Array[String] = []


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
	_assert_equal(scene.turn_state, scene.TurnState.MOVE_PREVIEW, "tap on reachable tile enters move preview")
	_assert_equal(arlen["grid"], Vector2i(1, 1), "tap alone does not move active unit")
	_assert_true(scene._confirm_move(), "confirming preview commits movement")
	_assert_equal(arlen["grid"], Vector2i(3, 1), "tap on reachable tile moves selected unit after confirm")

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
	_run_phase1_stabilization_acceptance(scene)
	await _run_enemy_presentation_acceptance(scene)
	await _run_attack_presentation_acceptance(scene)
	_run_attack_overlay_acceptance(scene)
	_run_movement_preview_acceptance(scene)
	_run_enemy_inspection_acceptance(scene)
	_run_numeric_hp_acceptance(scene)
	_run_orb_loadout_and_status_acceptance(scene)
	_run_pilot_passives_acceptance(scene)
	_run_weapon_data_validation_acceptance(scene)
	_run_mission_selector_and_debug_controls_acceptance(scene)
	_run_auto_benchmark_acceptance(scene)
	_run_visible_auto_playback_acceptance(scene)
	await _run_combat_impact_acceptance(scene)
	_run_phase1_architecture_acceptance(scene)
	_run_phase2_build_model_acceptance(scene)
	await _run_phase2_hangar_shell_acceptance(scene)
	_run_phase2_part_swap_tradeoffs_acceptance(scene)
	_run_phase2_weapon_offhand_rules_acceptance(scene)
	_run_phase2_orb_installation_acceptance(scene)
	_run_phase2_build_summary_and_signals_acceptance(scene)
	_run_phase2_squad_deploy_builds_acceptance(scene)
	_run_phase2_current_vs_inspected_hud_acceptance(scene)
	_run_phase2_effective_build_stats_acceptance(scene)
	await _run_phase2_build_fun_validation_acceptance(scene)

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
	_assert_true(scene.has_method("_spear_direction"), "Spear scene geometry API exists")
	_assert_true(scene.has_method("_line_attack_targets"), "Spear scene target lookup API exists")
	_assert_true(scene.combat_controller.has_method("resolve_spear_attack"), "Spear combat resolution lives in CombatController")
	if not _failures.is_empty():
		return

	_test_spear_hits_tile_one_only_when_tile_two_empty(scene)
	_test_spear_hits_tile_one_and_two_enemies(scene)
	_test_spear_tile_two_receives_reduced_damage(scene)
	_test_spear_cannot_attack_diagonal_line(scene)
	_test_spear_action_consumes_one_attack(scene)


func _run_rifle_acceptance(scene: Control) -> void:
	_assert_true(scene.combat_controller.has_method("resolve_rifle_attack"), "Rifle combat resolution lives in CombatController")
	_assert_true(scene.has_method("_volley_part_seed"), "Rifle seed compatibility API exists")
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
	_assert_true(scene.has_method("_shield_is_active"), "Shield state API exists")
	_assert_true(scene.has_method("_can_shield_intercept"), "Shield geometry API exists")
	_assert_true(scene.has_method("_intercepting_shield_for"), "Shield lookup API exists")
	_assert_true(scene.has_method("_damage_shield"), "Shield damage compatibility API exists")
	_assert_true(scene.combat_controller.has_method("resolve_blockable_shot"), "Shield/blockable combat resolution lives in CombatController")
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
	_assert_true(scene.has_method("_install_orb"), "Orb install API exists")
	_assert_true(scene.has_method("_orb_data_for"), "Orb data lookup API exists")
	_assert_true(scene.has_method("_active_orbs"), "Orb active list compatibility API exists")
	_assert_true(scene.has_method("_orb_adjusted_damage"), "Orb damage compatibility API exists")
	_assert_true(scene.has_method("_has_status"), "Status read compatibility API exists")
	_assert_true(scene.combat_controller.has_method("orb_effects"), "Orb effect aggregation lives in CombatController")
	_assert_true(scene.combat_controller.has_method("resolve_orb_proc"), "Orb proc resolution lives in CombatController")
	_assert_true(scene.combat_controller.has_method("apply_status"), "Status mutation lives in CombatController")
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
	shield["weapon"] = "Sword"
	shield["off_hand"] = "Shield"
	shield["weapon_mount_part"] = "Right Arm"
	shield["weapon_required_parts"] = ["Right Arm"]
	shield["off_hand_part"] = "Left Arm"
	shield["off_hand_disabled"] = false
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
	var result: Dictionary = _combat_blockable_shot(scene, fixture["attacker"], fixture["protected"], preview, "", 11, 35, 11)
	_assert_true(result["intercepted"], "valid shield geometry intercepts protected ally")
	_assert_equal(result["target_id"], "brann", "intercept redirects damage to shield bearer")
	_assert_equal(result["part_name"], "Shield", "intercepted damage lands on Shield HP")
	_assert_equal(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])), 0, "protected ally takes no damage from intercepted shot")


func _test_shield_invalid_angle_does_not_intercept(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene, "Sniper", Vector2i(4, 4))
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = _combat_blockable_shot(scene, fixture["attacker"], fixture["protected"], preview, "", 11, 35, 11)
	_assert_false(result.get("intercepted", false), "off-angle shield does not intercept")
	_assert_true(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])) > 0, "invalid angle lets target take normal damage")


func _test_shield_breaks_mid_rifle_volley_then_damage_continues(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene, "Rifle")
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = _combat_rifle_attack(scene, fixture["attacker"], fixture["protected"], preview, 11)
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
	var result: Dictionary = _combat_blockable_shot(scene, fixture["attacker"], fixture["protected"], preview, "", 11, 35, 11)
	_assert_false(result.get("intercepted", false), "destroyed shield does not intercept")
	_assert_true(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])) > 0, "destroyed shield lets damage hit protected target")


func _test_shield_interception_works_for_enemy_team(scene: Control) -> void:
	var fixture := _set_enemy_shield_fixture(scene)
	var protected_before := _part_hp_snapshot(fixture["protected"])
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = _combat_blockable_shot(scene, fixture["attacker"], fixture["protected"], preview, "", 11, 10, 11)
	_assert_true(result["intercepted"], "enemy shield can intercept for enemy ally")
	_assert_equal(result["target_id"], "enemy_rifle", "enemy shield bearer receives intercepted hit")
	_assert_equal(_changed_part_count(protected_before, _part_hp_snapshot(fixture["protected"])), 0, "enemy protected unit takes no damage from intercepted shot")


func _combat_blockable_shot(scene: Control, attacker, target, preview: Dictionary, part_name: String, hit_seed: int, damage: int, part_seed: int) -> Dictionary:
	return scene.combat_controller.resolve_blockable_shot(
		attacker,
		target,
		preview,
		part_name,
		hit_seed,
		damage,
		part_seed,
		scene.PART_NAMES,
		scene._weapon_data_for(attacker),
		Callable(scene, "_intercepting_shield_for"),
		Callable(scene, "_should_hit_shield"),
		Callable(scene, "_terrain_adjusted_damage"),
		Callable(scene, "_calculate_attack_damage"),
		Callable(scene, "_damage_part"),
		Callable(scene, "_damage_shield"),
		Callable(scene, "_pilot_shield_damage_reduction"),
		Callable(scene, "_combat_resolve_orb_proc")
	)


func _combat_rifle_attack(scene: Control, attacker, target, preview: Dictionary, seed: int) -> Dictionary:
	return scene.combat_controller.resolve_rifle_attack(
		attacker,
		target,
		preview,
		seed,
		scene.PART_NAMES,
		scene._weapon_data_for(attacker),
		Callable(scene, "_intercepting_shield_for"),
		Callable(scene, "_should_hit_shield"),
		Callable(scene, "_terrain_adjusted_damage"),
		Callable(scene, "_calculate_attack_damage"),
		Callable(scene, "_damage_part"),
		Callable(scene, "_damage_shield"),
		Callable(scene, "_pilot_shield_damage_reduction"),
		Callable(scene, "_combat_resolve_orb_proc")
	)


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
	var first: Dictionary = scene._combat_resolve_orb_proc(fixture["attacker"], fixture["target"], 12)
	var second: Dictionary = scene._combat_resolve_orb_proc(fixture["attacker"], fixture["target"], 12)
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
	_assert_true(scene.battle_ai.has_method("decide_action"), "AI decision flow lives in BattleAI")
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
	var decision: Dictionary = scene.battle_ai.decide_action(scene, enemy)
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
	var decision: Dictionary = scene.battle_ai.decide_action(scene, enemy)
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
	var run1: Dictionary = scene.run_auto_battle(120, 1337)
	scene._load_mission("crystal_quarry")
	var run2: Dictionary = scene.run_auto_battle(120, 1337)
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
	_assert_true(uphill_summary["destroyed_parts"] != downhill_summary["destroyed_parts"] or uphill_summary["turn_log"] != downhill_summary["turn_log"], "uphill and downhill runs produce different tactical outcomes")



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


func _run_phase1_stabilization_acceptance(scene: Control) -> void:
	_test_phase1_compact_battle_log_captures_all_event_types(scene)
	_test_phase1_debug_seed_is_selectable_and_reproducible(scene)
	_test_phase1_ancient_ruins_different_loadouts(scene)
	_test_phase1_attack_preview_contains_terrain_and_pattern(scene)
	_test_phase1_strict_turn_rules_enforced(scene)


func _test_phase1_compact_battle_log_captures_all_event_types(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var summary: Dictionary = scene.run_auto_battle(30, 1337)
	var log_str: String = " ".join(summary["turn_log"])
	_assert_true(log_str.contains(":move:"), "log captures move events")
	_assert_true(log_str.contains(":attack"), "log captures attack events")
	_assert_true(log_str.contains(":hit:") or log_str.contains(":miss:"), "log captures hit/miss events")
	_assert_true(log_str.contains(":damage:"), "log captures part damage events")


func _test_phase1_debug_seed_is_selectable_and_reproducible(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	scene.set_debug_seed(9999)
	var run1: Dictionary = scene.run_auto_battle(15, 9999)
	scene._load_mission("ancient_ruins")
	scene.set_debug_seed(9999)
	var run2: Dictionary = scene.run_auto_battle(15, 9999)
	_assert_equal(run1["winner"], run2["winner"], "debug seed reproduces same winner")
	_assert_equal(run1["turns"], run2["turns"], "debug seed reproduces same turns")
	_assert_equal(run1["turn_log"], run2["turn_log"], "debug seed reproduces identical turn log")


func _test_phase1_ancient_ruins_different_loadouts(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var default_run: Dictionary = scene.run_auto_battle(15, 1337)

	scene._load_mission("ancient_ruins")
	scene.configure_player_loadouts({
		"arlen": {"weapon": "Sword"},
		"mira": {"weapon": "Spear"},
		"sera": {"weapon": "Sword", "off_hand": "Shield"},
	})
	var alt_run: Dictionary = scene.run_auto_battle(15, 1337)
	_assert_true(default_run["turn_log"] != alt_run["turn_log"], "different weapon loadouts produce distinct tactical combat flows")



func _test_phase1_attack_preview_contains_terrain_and_pattern(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	target["grid"] = Vector2i(3, 3)
	arlen["grid"] = Vector2i(2, 3)
	scene._set_tile_terrain(Vector2i(2, 3), {"height": 0})
	scene._set_tile_terrain(Vector2i(3, 3), {"height": 1, "cover": true, "cover_dodge_bonus": 10})
	var preview: Dictionary = scene._attack_preview(arlen, target)
	_assert_true(preview.has("height_hit_modifier"), "preview has height modifier")
	_assert_true(preview.has("cover_dodge_modifier"), "preview has cover modifier")
	_assert_true(preview.has("weapon_pattern"), "preview has weapon pattern")
	_assert_equal(preview["weapon_pattern"], "line_2", "Spear has line_2 pattern")


func _run_enemy_presentation_acceptance(scene: Control) -> void:
	var required_methods := [
		"_plan_ai_activation",
		"_movement_path_to",
		"_present_enemy_activation",
		"_input_locked",
		"_resolve_planned_ai_activation_fast",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Enemy presentation API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_enemy_movement_presentation_records_each_path_step(scene)
	_test_enemy_presentation_blocks_player_mutation(scene)
	_test_fast_simulation_skips_enemy_presentation(scene)
	await _test_presented_enemy_activation_matches_fast_resolution(scene)


func _set_enemy_presentation_fixture(scene: Control) -> Dictionary:
	scene._load_mission("ancient_ruins")
	scene.enemy_presentation_enabled = true
	var enemy = scene._unit_by_id("enemy_blade")
	var target = scene._unit_by_id("arlen")
	scene._unit_by_id("mira")["grid"] = Vector2i(0, 6)
	scene._unit_by_id("sera")["grid"] = Vector2i(0, 5)
	scene._unit_by_id("brann")["grid"] = Vector2i(0, 4)
	enemy["grid"] = Vector2i(4, 1)
	target["grid"] = Vector2i(0, 1)
	for column in range(5):
		scene._set_tile_terrain(Vector2i(column, 1), {"height": 0})
	scene._begin_activation(enemy)
	return {"enemy": enemy, "target": target}


func _enemy_presentation_snapshot(scene: Control, enemy, target) -> Dictionary:
	return {
		"enemy_grid": enemy["grid"],
		"target_parts": _part_hp_snapshot(target),
		"turn_log": scene.turn_log.duplicate(),
		"active_id": str(scene.active_unit["id"]) if scene.active_unit != null else "",
		"simulation_seed": scene.simulation_seed,
	}


func _test_enemy_movement_presentation_records_each_path_step(scene: Control) -> void:
	var fixture := _set_enemy_presentation_fixture(scene)
	var plan: Dictionary = scene._plan_ai_activation(fixture["enemy"])
	_assert_equal(plan["path"].size(), 3, "enemy moving three tiles plans three visible path steps")
	_assert_equal(plan["path"][0], Vector2i(3, 1), "first path step is adjacent, not a teleport")
	_assert_equal(plan["path"][1], Vector2i(2, 1), "second path step is visible")
	_assert_equal(plan["path"][2], Vector2i(1, 1), "third path step reaches planned destination")


func _test_enemy_presentation_blocks_player_mutation(scene: Control) -> void:
	var fixture := _set_enemy_presentation_fixture(scene)
	scene.enemy_presentation_active = true
	var arlen = scene._unit_by_id("arlen")
	_assert_true(scene._input_locked(), "enemy presentation locks player input")
	_assert_false(scene._try_move_active_unit(arlen["grid"]), "player cannot mutate combat state during enemy presentation")
	scene.enemy_presentation_active = false


func _test_fast_simulation_skips_enemy_presentation(scene: Control) -> void:
	var fixture := _set_enemy_presentation_fixture(scene)
	scene.auto_battle = true
	var plan: Dictionary = scene._plan_ai_activation(fixture["enemy"])
	scene._resolve_planned_ai_activation_fast(fixture["enemy"], plan)
	_assert_equal(scene.enemy_presentation_log.size(), 0, "fast simulation skips presentation logs")
	_assert_false(scene.enemy_presentation_active, "fast simulation does not enter presentation state")
	scene.auto_battle = false


func _test_presented_enemy_activation_matches_fast_resolution(scene: Control) -> void:
	var fast_fixture := _set_enemy_presentation_fixture(scene)
	scene.set_debug_seed(2024)
	var fast_plan: Dictionary = scene._plan_ai_activation(fast_fixture["enemy"])
	scene._resolve_planned_ai_activation_fast(fast_fixture["enemy"], fast_plan)
	var fast_snapshot := _enemy_presentation_snapshot(scene, fast_fixture["enemy"], fast_fixture["target"])

	var presented_fixture := _set_enemy_presentation_fixture(scene)
	scene.set_debug_seed(2024)
	var presented_plan: Dictionary = scene._plan_ai_activation(presented_fixture["enemy"])
	await scene._present_enemy_activation(presented_fixture["enemy"], presented_plan)
	var presented_snapshot := _enemy_presentation_snapshot(scene, presented_fixture["enemy"], presented_fixture["target"])

	_assert_equal(presented_plan["path"], fast_plan["path"], "same seed plans same movement path with or without presentation")
	_assert_equal(presented_snapshot["enemy_grid"], fast_snapshot["enemy_grid"], "presented enemy ends on same grid as fast simulation")
	_assert_equal(presented_snapshot["target_parts"], fast_snapshot["target_parts"], "presented attack result matches fast simulation")
	_assert_equal(presented_snapshot["simulation_seed"], fast_snapshot["simulation_seed"], "presentation timing does not consume RNG")


func _run_attack_presentation_acceptance(scene: Control) -> void:
	var required_methods := [
		"_resolve_attack_result",
		"_build_attack_feedback_sequence",
		"_attack_feedback_line",
		"_present_attack_then_finish",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Attack presentation API exists: %s" % method)
	_assert_true(scene.battle_presenter.has_method("present_attack_feedback"), "Attack feedback pipeline lives in BattlePresenter")
	if not _failures.is_empty():
		return

	_test_miss_feedback_is_distinct_from_hit(scene)
	_test_hit_feedback_names_part_and_damage(scene)
	_test_rifle_feedback_lists_individual_shots(scene)
	_test_shield_intercept_feedback_names_shield_hp_loss(scene)
	_test_destroy_feedback_precedes_next_activation(scene)
	await _test_manual_attack_waits_for_feedback_before_initiative_advance(scene)
	await _test_attack_presentation_does_not_change_deterministic_result(scene)


func _attack_presentation_fixture(scene: Control, weapon := "Sniper", target_grid := Vector2i(4, 1)) -> Dictionary:
	scene._load_mission("ancient_ruins")
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var attacker = scene._unit_by_id("mira")
	var target = scene._unit_by_id("enemy_blade")
	attacker["weapon"] = weapon
	attacker["weapon_mount_part"] = "Right Arm"
	attacker["grid"] = Vector2i(1, 1)
	target["grid"] = target_grid
	scene._unit_by_id("arlen")["grid"] = Vector2i(0, 6)
	scene._unit_by_id("sera")["grid"] = Vector2i(0, 5)
	scene._unit_by_id("brann")["grid"] = Vector2i(0, 4)
	scene._begin_activation(attacker)
	return {"attacker": attacker, "target": target}


func _joined_feedback(scene: Control, attacker, target, result: Dictionary) -> String:
	return " | ".join(scene._build_attack_feedback_sequence(attacker, target, result))


func _test_miss_feedback_is_distinct_from_hit(scene: Control) -> void:
	var fixture := _attack_presentation_fixture(scene, "Sniper")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	var miss_result: Dictionary = scene._resolve_attack_result(fixture["attacker"], fixture["target"], preview, "", 95)
	var feedback := _joined_feedback(scene, fixture["attacker"], fixture["target"], miss_result)
	_assert_true(feedback.contains("Mira / Sniper -> Enemy Blade"), "feedback identifies attacker, weapon, and target")
	_assert_true(feedback.contains("MISS"), "miss feedback is explicit")
	_assert_false(feedback.contains("HIT /"), "miss feedback is distinguishable from hit")


func _test_hit_feedback_names_part_and_damage(scene: Control) -> void:
	var fixture := _attack_presentation_fixture(scene, "Sniper")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	var result: Dictionary = scene._resolve_attack_result(fixture["attacker"], fixture["target"], preview, "Right Arm", 11)
	var feedback := _joined_feedback(scene, fixture["attacker"], fixture["target"], result)
	_assert_true(feedback.contains("HIT /"), "hit feedback is explicit")
	_assert_true(feedback.contains(str(result["part_name"])), "hit feedback names damaged part")
	_assert_true(feedback.contains("-%d" % int(result["damage_applied"])), "hit feedback includes damage amount")


func _test_rifle_feedback_lists_individual_shots(scene: Control) -> void:
	var fixture := _attack_presentation_fixture(scene, "Rifle")
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	var result: Dictionary = scene._resolve_attack_result(fixture["attacker"], fixture["target"], preview, "", 11)
	var feedback := _joined_feedback(scene, fixture["attacker"], fixture["target"], result)
	_assert_true(feedback.contains("SHOT 1"), "Rifle feedback exposes first shot")
	_assert_true(feedback.contains("SHOT 4"), "Rifle feedback exposes final shot")
	_assert_true(feedback.contains("HIT") or feedback.contains("MISS"), "Rifle volley communicates per-shot outcomes")


func _test_shield_intercept_feedback_names_shield_hp_loss(scene: Control) -> void:
	var fixture := _set_player_shield_fixture(scene, "Sniper")
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["protected"])
	var result: Dictionary = scene._resolve_attack_result(fixture["attacker"], fixture["protected"], preview, "", 11)
	var feedback := _joined_feedback(scene, fixture["attacker"], fixture["protected"], result)
	_assert_true(feedback.contains("SHIELD INTERCEPT"), "shield interception is visible")
	_assert_true(feedback.contains("Brann"), "shield feedback names shield bearer")
	_assert_true(feedback.contains("Shield -%d" % int(result["damage_applied"])), "shield feedback reports Shield HP loss")


func _test_destroy_feedback_precedes_next_activation(scene: Control) -> void:
	var fixture := _attack_presentation_fixture(scene, "Sword", Vector2i(2, 1))
	fixture["attacker"]["weapon_mount_part"] = "Right Arm"
	fixture["target"]["parts"]["Body"]["hp"] = 20
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	var result: Dictionary = scene._resolve_attack_result(fixture["attacker"], fixture["target"], preview, "Body", 21)
	var sequence: Array = scene._build_attack_feedback_sequence(fixture["attacker"], fixture["target"], result)
	var joined := " | ".join(sequence)
	_assert_true(joined.contains("BODY DESTROYED"), "destroyed part feedback is stronger than ordinary hit")
	_assert_true(joined.contains("DEFEATED"), "Body destruction announces mech defeat")
	_assert_true(sequence.find("BODY DESTROYED / Enemy Blade DEFEATED") > sequence.find("HIT / Body"), "destruction feedback follows hit detail before advancement")


func _test_manual_attack_waits_for_feedback_before_initiative_advance(scene: Control) -> void:
	var fixture := _attack_presentation_fixture(scene, "Sniper")
	scene.attack_presentation_enabled = true
	scene.attack_feedback_step_seconds = 0.001
	_assert_true(scene._try_attack_active_unit(fixture["target"], "", 11), "manual attack starts feedback presentation")
	_assert_true(scene.attack_presentation_active, "attack feedback locks presentation")
	_assert_true(scene._input_locked(), "attack feedback locks mutating input")
	_assert_equal(scene.active_unit["id"], "mira", "initiative does not advance while attack feedback is visible")
	await scene.presented_attack_completed
	_assert_false(scene.attack_presentation_active, "attack feedback clears after sequence")
	_assert_true(scene.active_unit["id"] != "mira", "initiative advances only after attack feedback completes")


func _test_attack_presentation_does_not_change_deterministic_result(scene: Control) -> void:
	var fixture := _attack_presentation_fixture(scene, "Rifle")
	scene.attack_presentation_enabled = false
	scene.set_debug_seed(3030)
	var preview: Dictionary = scene._attack_preview(fixture["attacker"], fixture["target"])
	var result: Dictionary = scene._resolve_attack_result(fixture["attacker"], fixture["target"], preview, "", 21)
	var sequence: Array = scene._build_attack_feedback_sequence(fixture["attacker"], fixture["target"], result)
	var snapshot_before := _part_hp_snapshot(fixture["target"])
	var seed_before: int = int(scene.simulation_seed)

	scene.attack_presentation_enabled = true
	scene.attack_feedback_step_seconds = 0.001
	await scene.battle_presenter.present_attack_feedback(scene, fixture["attacker"], fixture["target"], result)

	_assert_equal(scene._build_attack_feedback_sequence(fixture["attacker"], fixture["target"], result), sequence, "presentation uses already-resolved deterministic attack data")
	_assert_equal(_part_hp_snapshot(fixture["target"]), snapshot_before, "presentation timing does not alter damage")
	_assert_equal(int(scene.simulation_seed), seed_before, "presentation timing does not consume RNG")


func _run_attack_overlay_acceptance(scene: Control) -> void:
	var required_methods := [
		"_calculate_attack_overlay_tiles",
		"_attack_overlay_for_tile",
		"_attack_target_reason",
		"_refresh_attack_overlay",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "Attack overlay API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_sword_overlay_is_orthogonal_range_one(scene)
	_test_sniper_overlay_shows_minimum_range_dead_zone(scene)
	_test_los_blocked_enemy_differs_from_out_of_range_enemy(scene)
	_test_spear_overlay_shows_straight_two_tile_lines(scene)
	_test_attack_overlay_and_preview_legality_agree(scene)


func _attack_overlay_fixture(scene: Control, weapon := "Sniper", attacker_grid := Vector2i(3, 3)) -> Dictionary:
	scene._load_mission("ancient_ruins")
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var attacker = scene._unit_by_id("mira")
	attacker["weapon"] = weapon
	attacker["weapon_mount_part"] = "Right Arm"
	attacker["grid"] = attacker_grid
	scene._unit_by_id("arlen")["grid"] = Vector2i(0, 6)
	scene._unit_by_id("sera")["grid"] = Vector2i(0, 5)
	scene._unit_by_id("brann")["grid"] = Vector2i(0, 4)
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(9, 6)
	scene._unit_by_id("enemy_rifle")["grid"] = Vector2i(8, 6)
	scene._unit_by_id("enemy_spear")["grid"] = Vector2i(9, 5)
	scene._unit_by_id("enemy_sniper")["grid"] = Vector2i(8, 5)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 4)
	scene._begin_activation(attacker)
	return {"attacker": attacker}


func _overlay_keys_for_status(overlay: Dictionary, statuses: Array) -> Array:
	var keys := []
	for key in overlay.keys():
		if statuses.has(str(overlay[key].get("status", ""))):
			keys.append(key)
	keys.sort()
	return keys


func _test_sword_overlay_is_orthogonal_range_one(scene: Control) -> void:
	var fixture := _attack_overlay_fixture(scene, "Sword", Vector2i(3, 3))
	var overlay: Dictionary = scene._calculate_attack_overlay_tiles(fixture["attacker"])
	var expected := ["2,3", "3,2", "3,4", "4,3"]
	_assert_equal(_overlay_keys_for_status(overlay, ["weapon_area", "legal_target"]), expected, "Sword overlay shows exactly four orthogonal range-1 tiles")
	_assert_equal(overlay["4,4"]["status"], "outside_range", "Sword overlay excludes diagonal tiles")


func _test_sniper_overlay_shows_minimum_range_dead_zone(scene: Control) -> void:
	var fixture := _attack_overlay_fixture(scene, "Sniper", Vector2i(3, 3))
	var overlay: Dictionary = scene._calculate_attack_overlay_tiles(fixture["attacker"])
	_assert_equal(overlay["4,3"]["status"], "minimum_range", "Sniper adjacent tile is minimum-range dead zone")
	_assert_equal(overlay["4,3"]["reason"], "Minimum range 2", "Sniper dead zone explains minimum range")
	_assert_true(["weapon_area", "legal_target"].has(str(overlay["5,3"]["status"])), "Sniper tile at range 2 is in weapon area")


func _test_los_blocked_enemy_differs_from_out_of_range_enemy(scene: Control) -> void:
	var fixture := _attack_overlay_fixture(scene, "Sniper", Vector2i(1, 1))
	var blocked = scene._unit_by_id("enemy_blade")
	var far = scene._unit_by_id("commander")
	blocked["grid"] = Vector2i(4, 1)
	far["grid"] = Vector2i(9, 6)
	scene._set_tile_terrain(Vector2i(2, 1), {"blocks_los": true})
	var overlay: Dictionary = scene._calculate_attack_overlay_tiles(fixture["attacker"])
	_assert_equal(overlay[scene._grid_key(blocked["grid"])]["status"], "los_blocked", "LOS-blocked target tile is categorized distinctly")
	_assert_equal(scene._attack_target_reason(fixture["attacker"], blocked), "LOS blocked", "LOS-blocked target gives LOS reason")
	_assert_equal(scene._attack_target_reason(fixture["attacker"], far), "Out of range", "out-of-range target gives range reason")


func _test_spear_overlay_shows_straight_two_tile_lines(scene: Control) -> void:
	var fixture := _attack_overlay_fixture(scene, "Spear", Vector2i(4, 3))
	var overlay: Dictionary = scene._calculate_attack_overlay_tiles(fixture["attacker"])
	for key in ["2,3", "3,3", "5,3", "6,3", "4,1", "4,2", "4,4", "4,5"]:
		_assert_true(["weapon_area", "legal_target"].has(str(overlay[key]["status"])), "Spear overlay includes straight line tile %s" % key)
	_assert_equal(overlay["5,4"]["status"], "outside_range", "Spear overlay excludes diagonal tile")
	_assert_equal(overlay["6,3"]["pattern"], "line_2", "Spear overlay exposes line_2 pattern")


func _test_attack_overlay_and_preview_legality_agree(scene: Control) -> void:
	var fixture := _attack_overlay_fixture(scene, "Rifle", Vector2i(3, 3))
	scene._unit_by_id("enemy_blade")["grid"] = Vector2i(5, 3)
	scene._unit_by_id("commander")["grid"] = Vector2i(9, 6)
	var overlay: Dictionary = scene._calculate_attack_overlay_tiles(fixture["attacker"])
	for unit in scene.units:
		if str(unit.get("team", "")) != "enemy":
			continue
		var preview: Dictionary = scene._attack_preview(fixture["attacker"], unit)
		var entry: Dictionary = overlay[scene._grid_key(unit["grid"])]
		_assert_equal(str(entry["status"]) == "legal_target", bool(preview["legal"]), "overlay and preview agree for %s" % str(unit["id"]))


func _test_phase1_strict_turn_rules_enforced(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var mira = scene._unit_by_id("mira")
	scene._begin_activation(arlen)
	_assert_true(scene._is_active_unit(arlen), "Arlen is active")
	_assert_false(scene._is_active_unit(mira), "Mira is not active")
	_assert_false(scene._can_move(mira), "non-active unit cannot move")
	_assert_false(scene._can_attack(mira), "non-active unit cannot attack")
	_assert_false(scene._can_wait(mira), "non-active unit cannot wait")


func _run_movement_preview_acceptance(scene: Control) -> void:
	var required_methods := [
		"_preview_move_destination",
		"_confirm_move",
		"_cancel_move_preview",
		"_clear_move_preview",
		"_calculate_move_path",
		"_draw_movement_preview",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "movement-preview API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_destination_tap_alone_never_consumes_movement(scene)
	_test_cancel_move_preserves_original_grid(scene)
	_test_confirm_move_moves_once_and_prevents_second_move(scene)
	_test_different_destination_can_be_previewed(scene)
	_test_illegal_destination_cannot_enter_confirm_state(scene)
	_test_move_confirm_attack_remains_valid(scene)


func _test_destination_tap_alone_never_consumes_movement(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	arlen["grid"] = Vector2i(2, 3)
	scene._begin_activation(arlen)
	var dest := Vector2i(3, 3)
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_MOVE, "Arlen starts in selecting move")
	scene._handle_grid_tap(scene._tile_center(dest))
	_assert_equal(scene.turn_state, scene.TurnState.MOVE_PREVIEW, "tapping destination enters MOVE_PREVIEW")
	_assert_equal(scene.preview_move_destination, dest, "preview destination is set")
	_assert_false(arlen["has_moved"], "destination tap alone never sets has_moved")
	_assert_equal(arlen["grid"], Vector2i(2, 3), "active unit remains on original tile during preview")
	_assert_false(scene.preview_move_path.is_empty(), "preview move path is calculated")
	scene.notification(CanvasItem.NOTIFICATION_DRAW)


func _test_cancel_move_preserves_original_grid(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	arlen["grid"] = Vector2i(2, 3)
	scene._begin_activation(arlen)
	scene._preview_move_destination(Vector2i(3, 3))
	_assert_equal(scene.turn_state, scene.TurnState.MOVE_PREVIEW, "in move preview")
	scene._cancel_move_preview()
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_MOVE, "cancelling preview returns to selecting move")
	_assert_equal(arlen["grid"], Vector2i(2, 3), "cancelling preserves original grid")
	_assert_false(arlen["has_moved"], "cancelling preserves has_moved = false")
	_assert_true(scene._can_move(arlen), "move action remains available after cancel")
	_assert_true(scene.preview_move_destination == null, "preview destination cleared on cancel")


func _test_confirm_move_moves_once_and_prevents_second_move(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	arlen["grid"] = Vector2i(2, 3)
	scene._begin_activation(arlen)
	var dest := Vector2i(3, 3)
	scene._preview_move_destination(dest)
	_assert_true(scene._confirm_move(), "confirm move succeeds")
	_assert_equal(arlen["grid"], dest, "active unit moved to confirmed destination")
	_assert_true(arlen["has_moved"], "has_moved is true after confirm")
	_assert_equal(scene.turn_state, scene.TurnState.MOVE_COMPLETE, "turn_state is MOVE_COMPLETE")
	_assert_false(scene._can_move(arlen), "second move in same activation is prevented")
	_assert_false(scene._confirm_move(), "cannot confirm move again after movement complete")


func _test_different_destination_can_be_previewed(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	arlen["grid"] = Vector2i(2, 3)
	scene._begin_activation(arlen)
	var dest1 := Vector2i(3, 3)
	var dest2 := Vector2i(2, 4)
	scene._preview_move_destination(dest1)
	_assert_equal(scene.preview_move_destination, dest1, "first destination previewed")
	scene._preview_move_destination(dest2)
	_assert_equal(scene.preview_move_destination, dest2, "destination updated to second choice without committing")
	_assert_equal(arlen["grid"], Vector2i(2, 3), "unit still at original tile")
	_assert_false(arlen["has_moved"], "has_moved still false after switching preview")


func _test_illegal_destination_cannot_enter_confirm_state(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var mira = scene._unit_by_id("mira")
	arlen["grid"] = Vector2i(2, 3)
	mira["grid"] = Vector2i(2, 4)
	scene._begin_activation(arlen)
	var occupied_dest: Vector2i = mira["grid"]
	_assert_false(scene._preview_move_destination(occupied_dest), "cannot preview occupied destination")
	_assert_true(scene.preview_move_destination == null, "preview destination remains null")
	var unreachable_dest := Vector2i(9, 6)
	_assert_false(scene._preview_move_destination(unreachable_dest), "cannot preview unreachable destination")
	_assert_true(scene.preview_move_destination == null, "preview destination still null")
	_assert_false(scene._confirm_move(), "cannot confirm without valid preview")


func _test_move_confirm_attack_remains_valid(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var enemy = scene._unit_by_id("enemy_blade")
	arlen["grid"] = Vector2i(2, 3)
	enemy["grid"] = Vector2i(4, 3)
	scene._begin_activation(arlen)
	scene._preview_move_destination(Vector2i(3, 3))
	_assert_true(scene._confirm_move(), "move confirmed")
	_assert_equal(scene.turn_state, scene.TurnState.MOVE_COMPLETE, "move complete")
	_assert_true(scene._can_attack(arlen), "attack remains available after move confirmation")
	scene._select_action("Attack")
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_ATTACK, "can transition to attack selection")
	_assert_true(scene._confirm_attack_target(enemy), "attack can be confirmed after move")


func _run_enemy_inspection_acceptance(scene: Control) -> void:
	var required_scene_methods := [
		"_target_inspection_data",
	]
	for method in required_scene_methods:
		_assert_true(scene.has_method(method), "enemy-inspection API exists: %s" % method)
	var required_hud_methods := [
		"inspect_target",
		"inspect_unit",
		"draw_enemy_inspection_panel",
	]
	for method in required_hud_methods:
		_assert_true(scene.battle_hud.has_method(method), "enemy-inspection HUD API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_inspect_two_enemies_without_consuming_action(scene)
	_test_target_panel_reflects_part_hp_and_destroyed_state(scene)
	_test_attack_preview_values_match_actual_validation(scene)
	_test_shielded_target_warning_when_interception_active(scene)
	_test_enemy_inspection_never_changes_active_unit_or_initiative(scene)


func _test_inspect_two_enemies_without_consuming_action(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var enemy1 = scene._unit_by_id("enemy_blade")
	var enemy2 = scene._unit_by_id("enemy_spear")
	scene._begin_activation(arlen)
	scene._select_action("Attack")
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_ATTACK, "in attack mode")

	scene.battle_hud.inspect_target(scene, enemy1)
	_assert_equal(scene.selected_unit["id"], "enemy_blade", "enemy 1 inspected")
	_assert_equal(scene.active_unit["id"], "arlen", "active unit unchanged after inspecting enemy 1")
	_assert_false(arlen["has_attacked"], "action not consumed by inspecting enemy 1")
	_assert_false(arlen["has_moved"], "move not consumed by inspecting enemy 1")
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_ATTACK, "still in attack mode")

	scene.battle_hud.inspect_target(scene, enemy2)
	_assert_equal(scene.selected_unit["id"], "enemy_spear", "enemy 2 inspected immediately")
	_assert_equal(scene.active_unit["id"], "arlen", "active unit unchanged after inspecting enemy 2")
	_assert_false(arlen["has_attacked"], "action not consumed by inspecting enemy 2")
	_assert_equal(scene.turn_state, scene.TurnState.SELECTING_ATTACK, "still in attack mode")


func _test_target_panel_reflects_part_hp_and_destroyed_state(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var enemy = scene._unit_by_id("enemy_blade")
	scene._damage_part(enemy, "Head", 100)
	var data: Dictionary = scene._target_inspection_data(enemy)
	_assert_equal(data["parts"]["Head"]["hp"], 0, "Head HP is 0 in target data")
	_assert_true(data["parts"]["Head"]["destroyed"], "Head marked destroyed in target data")
	_assert_true(data["parts"]["Body"]["hp"] > 0, "Body HP is positive")
	_assert_false(data["parts"]["Body"]["destroyed"], "Body not destroyed")
	_assert_true(data["consequences"].size() > 0, "Consequences list has penalty for destroyed Head")

	scene._damage_part(enemy, str(enemy["weapon_mount_part"]), 100)
	data = scene._target_inspection_data(enemy)
	_assert_true(bool(enemy["weapon_disabled"]), "weapon disabled after mount destroyed")

	scene._load_mission("ascending_ridge")
	var guard = scene._unit_by_id("enemy_ridge_guard")
	var guard_data: Dictionary = scene._target_inspection_data(guard)
	_assert_true(guard_data["has_shield"], "guard has shield in target data")
	_assert_equal(guard_data["shield_hp"], guard["shield_hp"], "shield HP matches")
	_assert_equal(guard_data["shield_max_hp"], guard["shield_max_hp"], "shield max HP matches")


func _test_attack_preview_values_match_actual_validation(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var enemy = scene._unit_by_id("enemy_blade")
	arlen["grid"] = Vector2i(2, 3)
	enemy["grid"] = Vector2i(4, 3)
	scene._begin_activation(arlen)
	scene._select_action("Attack")
	var data: Dictionary = scene._target_inspection_data(enemy)
	var preview: Dictionary = scene._attack_preview(arlen, enemy)
	_assert_equal(data["attack_preview"]["legal"], preview["legal"], "target data preview legality matches")
	_assert_equal(data["attack_preview"]["hit_percent"], preview["hit_percent"], "target data preview hit% matches")
	_assert_equal(data["attack_preview"]["damage"], preview["damage"], "target data preview damage matches")
	_assert_equal(data["attack_preview"]["weapon_pattern"], preview["weapon_pattern"], "target data weapon pattern matches")


func _test_shielded_target_warning_when_interception_active(scene: Control) -> void:
	scene._load_mission("ascending_ridge")
	var sera = scene._unit_by_id("sera")
	var guard = scene._unit_by_id("enemy_ridge_guard")
	var enemy = scene._unit_by_id("enemy_blade")
	sera["grid"] = Vector2i(1, 3)
	guard["grid"] = Vector2i(3, 3)
	enemy["grid"] = Vector2i(4, 3)
	scene._begin_activation(sera)
	scene._select_action("Attack")
	_assert_true(scene._can_shield_intercept(guard, sera, enemy, scene._weapon_data_for(sera)), "guard can intercept")
	var data: Dictionary = scene._target_inspection_data(enemy)
	_assert_true(data["shield_interceptor"] != null, "shield interceptor identified")
	_assert_true(str(data["shield_warning"]).contains("Ridge Guard"), "shield warning mentions intercepting guard")


func _test_enemy_inspection_never_changes_active_unit_or_initiative(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	scene._begin_activation(arlen)
	var active_before: String = scene.active_unit["id"]
	var timeline_before: Array = scene.initiative_timeline.duplicate()

	scene.battle_hud.inspect_unit(scene, scene._unit_by_id("commander"))
	_assert_equal(scene.active_unit["id"], active_before, "active unit unchanged after ally/enemy inspection")
	_assert_equal(scene.initiative_timeline, timeline_before, "initiative timeline unchanged after inspection")

	scene.battle_hud.inspect_target(scene, scene._unit_by_id("enemy_blade"))
	_assert_equal(scene.active_unit["id"], active_before, "active unit unchanged after target inspection")
	_assert_equal(scene.initiative_timeline, timeline_before, "initiative timeline unchanged after target inspection")

	scene.notification(CanvasItem.NOTIFICATION_DRAW)


func _run_numeric_hp_acceptance(scene: Control) -> void:
	var required_methods := [
		"_part_hp_text",
		"_shield_hp_text",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "numeric HP API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_part_hp_numbers_match_simulation_state_before_and_after_damage(scene)
	_test_destroyed_part_displays_zero_and_destroyed_label(scene)
	_test_shield_numeric_hp_decreases_on_damage(scene)
	_test_selecting_different_unit_updates_numeric_hp(scene)


func _test_part_hp_numbers_match_simulation_state_before_and_after_damage(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var body_hp := int(arlen["parts"]["Body"]["hp"])
	var body_max := int(arlen["parts"]["Body"]["max_hp"])
	_assert_equal(scene._part_hp_text(arlen, "Body"), "%d / %d" % [body_hp, body_max], "body displays numeric HP matching simulation")
	var head_hp := int(arlen["parts"]["Head"]["hp"])
	var head_max := int(arlen["parts"]["Head"]["max_hp"])
	_assert_equal(scene._part_hp_text(arlen, "Head"), "%d / %d" % [head_hp, head_max], "head displays numeric HP matching simulation")

	scene._damage_part(arlen, "Body", 35)
	_assert_equal(scene._part_hp_text(arlen, "Body"), "%d / %d" % [body_hp - 35, body_max], "part HP text reflects reduced HP after damage")

	scene._damage_part(arlen, "Body", 15)
	_assert_equal(scene._part_hp_text(arlen, "Body"), "%d / %d" % [body_hp - 50, body_max], "part HP text updates continuously on damage")


func _test_destroyed_part_displays_zero_and_destroyed_label(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	scene._damage_part(arlen, "Right Arm", 100)
	_assert_true(bool(arlen["parts"]["Right Arm"]["destroyed"]), "part marked destroyed")
	_assert_equal(scene._part_hp_text(arlen, "Right Arm"), "0 / 100 DESTROYED", "destroyed part displays 0 and DESTROYED label")

	scene._damage_part(arlen, "Left Arm", 250)
	_assert_equal(scene._part_hp_text(arlen, "Left Arm"), "0 / 100 DESTROYED", "overkilled part displays exactly 0, never negative")


func _test_shield_numeric_hp_decreases_on_damage(scene: Control) -> void:
	scene._load_mission("ascending_ridge")
	var guard = scene._unit_by_id("enemy_ridge_guard")
	_assert_true(int(guard["shield_max_hp"]) > 0, "guard has shield")
	_assert_equal(scene._shield_hp_text(guard), "%d / %d" % [guard["shield_hp"], guard["shield_max_hp"]], "initial shield HP text matches state")

	var initial_hp: int = int(guard["shield_hp"])
	scene._damage_shield(guard, 20)
	_assert_equal(scene._shield_hp_text(guard), "%d / %d" % [initial_hp - 20, guard["shield_max_hp"]], "shield numeric HP decreases after damage")

	scene._damage_shield(guard, initial_hp)
	_assert_equal(scene._shield_hp_text(guard), "0 / %d BROKEN" % int(guard["shield_max_hp"]), "broken shield displays 0 and BROKEN label")

	var blade = scene._unit_by_id("enemy_blade")
	_assert_equal(scene._shield_hp_text(blade), "", "unit without shield returns empty string")


func _test_selecting_different_unit_updates_numeric_hp(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var enemy = scene._unit_by_id("enemy_blade")
	var arlen_head_hp := int(arlen["parts"]["Head"]["hp"])
	var enemy_head_hp := int(enemy["parts"]["Head"]["hp"])
	scene._damage_part(enemy, "Head", 40)

	scene._select_unit(arlen)
	_assert_equal(scene.selected_unit["id"], "arlen", "arlen is selected")
	_assert_equal(scene._part_hp_text(scene.selected_unit, "Head"), "%d / 100" % arlen_head_hp, "arlen has initial Head HP")

	scene._select_unit(enemy)
	_assert_equal(scene.selected_unit["id"], "enemy_blade", "enemy is selected")
	_assert_equal(scene._part_hp_text(scene.selected_unit, "Head"), "%d / 100" % (enemy_head_hp - 40), "selected enemy displays damaged Head HP")

	scene.notification(CanvasItem.NOTIFICATION_DRAW)


func _run_orb_loadout_and_status_acceptance(scene: Control) -> void:
	var required_methods := [
		"_apply_default_orb_loadouts",
		"_apply_default_orb_loadout",
		"_resolve_turn_start_statuses",
		"_remove_status",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "orb loadout and status API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_player_units_start_normal_missions_with_default_orb_loadouts(scene)
	_test_visible_orb_proc_in_normal_combat(scene)
	_test_burn_deterministic_gameplay_effect(scene)
	_test_destroying_host_part_disables_orb_immediately(scene)
	_test_no_orb_adds_primary_action_buttons(scene)


func _test_player_units_start_normal_missions_with_default_orb_loadouts(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var mira = scene._unit_by_id("mira")
	var sera = scene._unit_by_id("sera")
	var brann = scene._unit_by_id("brann")

	# Arlen: Fire N on Right Arm (melee/part pressure support)
	_assert_equal(arlen["parts"]["Right Arm"]["orb"], "fire_n", "Arlen has fire_n on Right Arm")
	_assert_equal(scene._orb_damage_modifier_percent(arlen), 10, "Arlen has +10% damage from Fire N")

	# Mira: Water R on Right Arm, Lightning R on Head (accuracy/precision support)
	_assert_equal(mira["parts"]["Right Arm"]["orb"], "water_r", "Mira has water_r on Right Arm")
	_assert_equal(mira["parts"]["Head"]["orb"], "lightning_r", "Mira has lightning_r on Head")
	_assert_equal(scene._orb_hit_modifier(mira), 10, "Mira has +10% hit bonus from dual Orbs")

	# Sera: Fire SR on Right Arm (strongest elemental/proc identity)
	_assert_equal(sera["parts"]["Right Arm"]["orb"], "fire_sr", "Sera has fire_sr on Right Arm")

	# Brann: Earth SSR on Left Arm (Earth/defensive support)
	_assert_equal(brann["parts"]["Left Arm"]["orb"], "earth_ssr", "Brann has earth_ssr on Left Arm")

	# Verify elements across the squad: Fire, Water, Lightning, Earth
	var elements := {}
	for unit in [arlen, mira, sera, brann]:
		for orb in scene._active_orbs(unit):
			elements[str(orb["element"])] = true
	_assert_true(elements.has("Fire"), "Fire element is represented")
	_assert_true(elements.has("Water"), "Water element is represented")
	_assert_true(elements.has("Lightning"), "Lightning element is represented")
	_assert_true(elements.has("Earth"), "Earth element is represented")

	# Verify each player unit has active orbs
	_assert_true(scene._active_orbs(arlen).size() > 0, "Arlen has active orbs")
	_assert_true(scene._active_orbs(mira).size() > 0, "Mira has active orbs")
	_assert_true(scene._active_orbs(sera).size() > 0, "Sera has active orbs")
	_assert_true(scene._active_orbs(brann).size() > 0, "Brann has active orbs")


func _test_visible_orb_proc_in_normal_combat(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var sera = scene._unit_by_id("sera")
	var target = scene._unit_by_id("enemy_blade")

	# Fire SR has 35% Burn proc. With seed 0: 0 % 100 = 0 < 35 -> procs!
	var proc: Dictionary = scene._combat_resolve_orb_proc(sera, target, 0)
	_assert_true(proc["triggered"], "Sera Fire SR proc triggers deterministically")
	_assert_equal(proc["status"], "Burn", "Fire SR procs Burn")
	_assert_true(scene._has_status(target, "Burn"), "target has Burn status applied")

	# Verify attack feedback presentation includes the proc line
	var fake_result := {
		"hit": true,
		"part_name": "Body",
		"damage_applied": 12,
		"orb_proc": {"triggered": true, "status": "Burn"}
	}
	var feedback: String = " | ".join(scene._build_attack_feedback_sequence(sera, target, fake_result))
	_assert_true(feedback.contains("ORB PROC / Burn"), "attack feedback sequence includes visible ORB PROC / Burn")


func _test_burn_deterministic_gameplay_effect(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var enemy = scene._unit_by_id("enemy_blade")
	scene.combat_controller.apply_status(enemy, "Burn", scene.turn_log)
	_assert_true(scene._has_status(enemy, "Burn"), "enemy starts with Burn")

	var body_before: int = int(enemy["parts"]["Body"]["hp"])
	scene._begin_activation(enemy)
	var body_after: int = int(enemy["parts"]["Body"]["hp"])
	_assert_equal(body_after, body_before - scene.BURN_DAMAGE, "Burn deals exactly BURN_DAMAGE to Body at activation start")
	_assert_false(scene._has_status(enemy, "Burn"), "Burn is consumed after activation tick")

	var log_str: String = " ".join(scene.turn_log)
	_assert_true(log_str.contains("%s:status:Burn:%d" % [enemy["id"], scene.BURN_DAMAGE]), "turn log records Burn status damage")

	# Lethal Burn test
	var target = scene._unit_by_id("enemy_spear")
	target["parts"]["Body"]["hp"] = 5
	scene.combat_controller.apply_status(target, "Burn", scene.turn_log)
	scene._begin_activation(target)
	_assert_equal(target["parts"]["Body"]["hp"], 0, "lethal Burn reduces Body HP to 0")
	_assert_true(bool(target["defeated"]), "lethal Burn marks unit defeated")
	_assert_false(scene._is_unit_in_battle(target), "defeated unit is removed from battle")


func _test_destroying_host_part_disables_orb_immediately(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var sera = scene._unit_by_id("sera")
	var enemy = scene._unit_by_id("enemy_blade")
	_assert_equal(scene._orb_damage_modifier_percent(sera), 10, "Sera has +10% damage bonus before host part damage")

	scene._damage_part(sera, "Right Arm", 100)
	_assert_true(bool(sera["parts"]["Right Arm"]["destroyed"]), "Right Arm is destroyed")
	_assert_true(bool(sera["parts"]["Right Arm"]["orb_disabled"]), "Orb on destroyed host part is disabled")
	_assert_equal(scene._orb_damage_modifier_percent(sera), 0, "passive damage bonus lost immediately when host part destroyed")
	_assert_equal(scene._active_orbs(sera).size(), 0, "no active orbs remaining on Sera")

	var proc: Dictionary = scene._combat_resolve_orb_proc(sera, enemy, 0)
	_assert_false(proc["triggered"], "disabled Orb cannot trigger proc")


func _test_no_orb_adds_primary_action_buttons(scene: Control) -> void:
	_assert_equal(scene.PRIMARY_ACTIONS, ["Move", "Attack", "Wait"], "primary actions remain strictly Move, Attack, Wait")
	_assert_equal(scene.action_rects.size(), 3, "action rects size remains exactly 3")


func _run_pilot_passives_acceptance(scene: Control) -> void:
	var required_methods := [
		"_pilot_data_for",
		"_pilot_passive_for",
		"_set_unit_pilot",
		"_pilot_damage_modifier_percent",
		"_pilot_hit_modifier",
		"_pilot_orb_proc_bonus",
		"_pilot_shield_damage_reduction",
		"_calculate_attack_damage",
		"_apply_default_pilot_loadouts",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "pilot passive API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_each_pilot_has_passive_defined_in_data(scene)
	_test_arlen_passive_influences_part_pressure_damage(scene)
	_test_mira_passive_influences_ranged_accuracy(scene)
	_test_sera_passive_influences_orb_proc_behavior(scene)
	_test_brann_passive_reinforces_shield_defense(scene)
	_test_no_pilot_creates_extra_primary_action(scene)
	_test_inspection_panel_exposes_pilot_identity(scene)


func _test_each_pilot_has_passive_defined_in_data(scene: Control) -> void:
	var required_pilots := ["arlen", "mira", "sera", "brann"]
	for pid in required_pilots:
		_assert_true(scene.PILOT_DATA.has(pid), "pilot data contains %s" % pid)
		var pdata: Dictionary = scene.PILOT_DATA[pid]
		_assert_true(pdata.has("name") and pdata.has("title") and pdata.has("passive"), "%s has required metadata" % pid)
		var passive: Dictionary = pdata["passive"]
		_assert_true(passive.has("id") and passive.has("name") and passive.has("desc"), "%s has passive description" % pid)


func _test_arlen_passive_influences_part_pressure_damage(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var target = scene._unit_by_id("enemy_blade")
	target["parts"]["Head"]["hp"] = 100
	_assert_equal(scene._pilot_damage_modifier_percent(arlen, target, "Head"), 0, "Arlen gets no bonus against undamaged part")
	target["parts"]["Head"]["hp"] = 80
	_assert_equal(scene._pilot_damage_modifier_percent(arlen, target, "Head"), 15, "Arlen gets +15% bonus against damaged part")
	_assert_equal(scene._calculate_attack_damage(arlen, 20, target, "Head"), 25, "calculated damage includes +10% orb and +15% pilot bonus (total +25%)")
	scene._set_unit_pilot(arlen, "")
	_assert_equal(scene._pilot_damage_modifier_percent(arlen, target, "Head"), 0, "removing pilot removes part pressure bonus")
	_assert_equal(scene._calculate_attack_damage(arlen, 20, target, "Head"), 22, "calculated damage returns to base orb damage without pilot")
	scene._set_unit_pilot(arlen, "arlen")


func _test_mira_passive_influences_ranged_accuracy(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var mira = scene._unit_by_id("mira")
	var target = scene._unit_by_id("enemy_blade")
	mira["grid"] = Vector2i(1, 1)
	target["grid"] = Vector2i(3, 1)
	_assert_equal(scene._pilot_hit_modifier(mira, target), 0, "Mira gets no accuracy bonus at distance < 4")
	target["grid"] = Vector2i(5, 1)
	_assert_equal(scene._pilot_hit_modifier(mira, target), 15, "Mira gets +15% hit bonus at distance >= 4")
	scene._set_unit_pilot(mira, "")
	_assert_equal(scene._pilot_hit_modifier(mira, target), 0, "removing pilot removes Hawkeye bonus")
	scene._set_unit_pilot(mira, "mira")


func _test_sera_passive_influences_orb_proc_behavior(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var sera = scene._unit_by_id("sera")
	_assert_equal(scene._pilot_orb_proc_bonus(sera), 15, "Sera has +15% orb proc bonus")
	scene._set_unit_pilot(sera, "")
	_assert_equal(scene._pilot_orb_proc_bonus(sera), 0, "removing pilot removes orb proc bonus")
	scene._set_unit_pilot(sera, "sera")


func _test_brann_passive_reinforces_shield_defense(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var brann = scene._unit_by_id("brann")
	_assert_equal(scene._pilot_shield_damage_reduction(brann), 5, "Brann has 5 shield damage reduction")
	_assert_equal(int(brann["shield_max_hp"]), 40, "Brann shield max HP includes +15 bonus (25 + 15 = 40)")
	var enemy = scene._unit_by_id("enemy_blade")
	enemy["grid"] = brann["grid"] + Vector2i(1, 0)
	var preview: Dictionary = scene._attack_preview(enemy, brann)
	var res: Dictionary = scene.combat_controller.resolve_shield_damage(
		enemy,
		brann,
		brann,
		preview,
		0,
		30,
		false,
		scene._weapon_data_for(enemy),
		Callable(scene, "_terrain_adjusted_damage"),
		Callable(scene, "_calculate_attack_damage"),
		Callable(scene, "_damage_shield"),
		Callable(scene, "_pilot_shield_damage_reduction"),
		Callable(scene, "_combat_resolve_orb_proc")
	)
	_assert_equal(res["damage_applied"], 25, "Shield damage absorbed by Guardian Stance (30 - 5 = 25)")
	scene._set_unit_pilot(brann, "")
	_assert_equal(scene._pilot_shield_damage_reduction(brann), 0, "removing pilot removes shield reduction")
	scene._set_unit_pilot(brann, "brann")


func _test_no_pilot_creates_extra_primary_action(scene: Control) -> void:
	_assert_equal(scene.PRIMARY_ACTIONS, ["Move", "Attack", "Wait"], "primary actions remain strictly Move, Attack, Wait with pilots")
	_assert_equal(scene.action_rects.size(), 3, "action rects size remains exactly 3 with pilots")


func _test_inspection_panel_exposes_pilot_identity(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	var arlen = scene._unit_by_id("arlen")
	var data: Dictionary = scene._target_inspection_data(arlen)
	_assert_true(data.has("pilot"), "inspection data contains pilot key")
	var pilot: Dictionary = data["pilot"]
	_assert_equal(pilot.get("name"), "Arlen", "inspection data shows pilot name")
	_assert_equal(pilot.get("passive_name"), "Part Breaker", "inspection data shows pilot passive name")


func _run_weapon_data_validation_acceptance(scene: Control) -> void:
	var required_methods := [
		"_validate_weapon_data",
		"_validate_all_weapons_data",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "weapon validation API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_all_defined_weapons_pass_validation(scene)
	_test_spear_body_weight_not_100_and_neutrally_distributed(scene)
	_test_sniper_body_weight_remains_ten_percent(scene)
	_test_invalid_weapon_part_weights_fail_validation(scene)
	_test_weapons_remain_tactically_distinct(scene)


func _test_all_defined_weapons_pass_validation(scene: Control) -> void:
	var result: Dictionary = scene._validate_all_weapons_data()
	_assert_true(bool(result.get("valid", false)), "all configured weapons pass data validation")
	_assert_true(result.get("errors", {}).is_empty(), "no validation errors in default weapon set")


func _test_spear_body_weight_not_100_and_neutrally_distributed(scene: Control) -> void:
	var spear: Dictionary = scene.WEAPON_DATA["Spear"]
	var weights: Dictionary = spear["part_weights"]
	_assert_true(int(weights.get("Body", 0)) != 100, "Spear default Body weight is no longer 100%")
	_assert_equal(int(weights.get("Head", 0)), 20, "Spear Head weight is 20%")
	_assert_equal(int(weights.get("Body", 0)), 20, "Spear Body weight is 20%")
	_assert_equal(int(weights.get("Left Arm", 0)), 20, "Spear Left Arm weight is 20%")
	_assert_equal(int(weights.get("Right Arm", 0)), 20, "Spear Right Arm weight is 20%")
	_assert_equal(int(weights.get("Legs", 0)), 20, "Spear Legs weight is 20%")


func _test_sniper_body_weight_remains_ten_percent(scene: Control) -> void:
	var sniper: Dictionary = scene.WEAPON_DATA["Sniper"]
	var weights: Dictionary = sniper["part_weights"]
	_assert_equal(int(weights.get("Body", 0)), 10, "Sniper Body weight remains exactly 10%")
	_assert_equal(int(weights.get("Head", 0)), 30, "Sniper Head weight is 30%")


func _test_invalid_weapon_part_weights_fail_validation(scene: Control) -> void:
	var bad_total := {
		"name": "Bad Weapon",
		"range_min": 1,
		"range_max": 2,
		"damage": 20,
		"part_weights": {"Head": 20, "Body": 20},
	}
	var res1: Dictionary = scene._validate_weapon_data(bad_total)
	_assert_false(bool(res1.get("valid", true)), "weapon with weight total != 100 fails validation")

	var bad_part := {
		"name": "Bad Part",
		"range_min": 1,
		"range_max": 2,
		"damage": 20,
		"part_weights": {"Head": 50, "Wing": 50},
	}
	var res2: Dictionary = scene._validate_weapon_data(bad_part)
	_assert_false(bool(res2.get("valid", true)), "weapon with invalid part name fails validation")

	var neg_weight := {
		"name": "Neg Weight",
		"range_min": 1,
		"range_max": 2,
		"damage": 20,
		"part_weights": {"Head": 110, "Body": -10},
	}
	var res3: Dictionary = scene._validate_weapon_data(neg_weight)
	_assert_false(bool(res3.get("valid", true)), "weapon with negative weight fails validation")


func _test_weapons_remain_tactically_distinct(scene: Control) -> void:
	var sword: Dictionary = scene.WEAPON_DATA["Sword"]
	var spear: Dictionary = scene.WEAPON_DATA["Spear"]
	var rifle: Dictionary = scene.WEAPON_DATA["Rifle"]
	var sniper: Dictionary = scene.WEAPON_DATA["Sniper"]

	_assert_equal(sword["pattern"], "single", "Sword is single target")
	_assert_equal(sword["range_max"], 1, "Sword is range 1")
	_assert_equal(sword["damage"], 45, "Sword has high single hit damage")

	_assert_equal(spear["pattern"], "line_2", "Spear has line_2 pattern")
	_assert_equal(spear["range_max"], 2, "Spear reaches range 2")
	_assert_equal(spear["damage"], 30, "Spear tile 1 damage is 30")
	_assert_equal(spear["secondary_damage"], 22, "Spear tile 2 damage is 22")

	_assert_equal(rifle["pattern"], "volley", "Rifle has volley pattern")
	_assert_equal(rifle["shot_count"], 4, "Rifle fires 4 shots")
	_assert_equal(rifle["damage"], 10, "Rifle has 10 damage per shot")

	_assert_equal(sniper["range_min"], 2, "Sniper has minimum range 2")
	_assert_equal(sniper["range_max"], 6, "Sniper reaches range 6")
	_assert_equal(sniper["part_weights"]["Head"], 30, "Sniper head weight is highest at 30%")


func _run_mission_selector_and_debug_controls_acceptance(scene: Control) -> void:
	var required_methods := [
		"_select_mission",
		"_restart_current_mission",
		"_open_mission_selector",
		"_close_mission_selector",
		"_toggle_mission_selector",
		"_set_auto_battle",
		"_toggle_auto_battle",
		"_set_fast_simulation",
		"_toggle_fast_simulation",
		"_set_simulation_seed",
		"_cycle_debug_seed",
		"_draw_debug_control_bar",
		"_draw_mission_selector_overlay",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "mission selector API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_each_mission_can_be_selected_and_launched(scene)
	_test_ascending_ridge_both_deployment_directions(scene)
	_test_manual_and_auto_mode_toggle_before_battle(scene)
	_test_fast_simulation_toggles_presentation(scene)
	_test_debug_seed_selection_and_cycling(scene)
	_test_restart_restores_initial_mission_state_and_loadouts(scene)
	_test_deterministic_reproducibility_with_same_seed_mission_loadout(scene)
	_test_mission_selector_overlay_toggle_and_content(scene)


func _test_each_mission_can_be_selected_and_launched(scene: Control) -> void:
	scene._select_mission("ancient_ruins", false)
	_assert_equal(scene.current_mission, "ancient_ruins", "Ancient Ruins selected and loaded")
	_assert_equal(scene.turn_number, 1, "starts at turn 1")

	scene._select_mission("crystal_quarry", false)
	_assert_equal(scene.current_mission, "crystal_quarry", "Crystal Quarry selected and loaded")
	_assert_equal(scene.turn_number, 1, "Crystal Quarry starts at turn 1")

	scene._select_mission("ascending_ridge", false)
	_assert_equal(scene.current_mission, "ascending_ridge", "Ascending Ridge selected and loaded")
	_assert_equal(scene.turn_number, 1, "Ascending Ridge starts at turn 1")


func _test_ascending_ridge_both_deployment_directions(scene: Control) -> void:
	scene._select_mission("ascending_ridge", false)
	_assert_false(scene.mission_swapped_sides, "normal deployment is uphill (swapped_sides = false)")
	var arlen = scene._unit_by_id("arlen")
	var enemy = scene._unit_by_id("commander")
	_assert_true(arlen["grid"].x < enemy["grid"].x, "player starts on left side for uphill assault")

	scene._select_mission("ascending_ridge", true)
	_assert_true(scene.mission_swapped_sides, "swapped deployment is downhill (swapped_sides = true)")
	arlen = scene._unit_by_id("arlen")
	enemy = scene._unit_by_id("commander")
	_assert_true(arlen["grid"].x > enemy["grid"].x, "player starts on right ridge for downhill defense")


func _test_manual_and_auto_mode_toggle_before_battle(scene: Control) -> void:
	scene._select_mission("ancient_ruins", false)
	scene._set_auto_battle(false)
	_assert_false(scene.auto_battle, "manual mode can be set before battle")

	scene._toggle_auto_battle()
	_assert_true(scene.auto_battle, "auto mode can be toggled on")

	scene._toggle_auto_battle()
	_assert_false(scene.auto_battle, "auto mode can be toggled off")


func _test_fast_simulation_toggles_presentation(scene: Control) -> void:
	scene._set_fast_simulation(true)
	_assert_true(scene.fast_simulation, "fast simulation can be enabled")
	_assert_false(scene.enemy_presentation_enabled, "presentation disabled in fast simulation")
	_assert_false(scene.attack_presentation_enabled, "attack presentation disabled in fast simulation")

	scene._toggle_fast_simulation()
	_assert_false(scene.fast_simulation, "fast simulation toggled off")
	_assert_true(scene.enemy_presentation_enabled, "presentation restored for manual play")
	_assert_true(scene.attack_presentation_enabled, "attack presentation restored for manual play")


func _test_debug_seed_selection_and_cycling(scene: Control) -> void:
	scene._set_simulation_seed(1337)
	_assert_equal(scene.simulation_seed, 1337, "simulation seed set to 1337")
	_assert_equal(scene.current_debug_seed, 1337, "current debug seed recorded")

	var cycled: int = scene._cycle_debug_seed()
	_assert_equal(scene.simulation_seed, cycled, "cycled seed applied to simulation")
	_assert_equal(scene.current_debug_seed, cycled, "cycled debug seed updated")


func _test_restart_restores_initial_mission_state_and_loadouts(scene: Control) -> void:
	scene._select_mission("ancient_ruins", false)
	scene.configure_player_loadouts({"arlen": {"weapon": "Sword"}})
	var arlen = scene._unit_by_id("arlen")
	_assert_equal(arlen["weapon"], "Sword", "custom weapon configured")
	scene._damage_part(arlen, "Head", 30)
	_assert_true(arlen["parts"]["Head"]["hp"] < 84, "Arlen Head took damage")

	scene._restart_current_mission()
	arlen = scene._unit_by_id("arlen")
	_assert_equal(scene.turn_number, 1, "turn number reset to 1 on restart")
	_assert_equal(arlen["weapon"], "Sword", "configured weapon preserved across restart")
	_assert_equal(arlen["parts"]["Head"]["hp"], 84, "Head HP restored to initial 84")
	_assert_true(scene.turn_log.is_empty(), "turn log reset on restart")


func _test_deterministic_reproducibility_with_same_seed_mission_loadout(scene: Control) -> void:
	scene._select_mission("ancient_ruins", false)
	scene.configure_player_loadouts({"arlen": {"weapon": "Sword"}})
	scene.set_debug_seed(42)
	var run1: Dictionary = scene.run_auto_battle(20, 42)

	scene._restart_current_mission()
	scene.set_debug_seed(42)
	var run2: Dictionary = scene.run_auto_battle(20, 42)

	_assert_equal(run1["winner"], run2["winner"], "reproducible winner with same seed and loadout")
	_assert_equal(run1["turns"], run2["turns"], "reproducible turns with same seed and loadout")
	_assert_equal(run1["turn_log"].size(), run2["turn_log"].size(), "reproducible turn log size")


func _test_mission_selector_overlay_toggle_and_content(scene: Control) -> void:
	scene._open_mission_selector()
	_assert_true(scene.mission_selector_open, "mission selector is open")

	for m_id in ["ancient_ruins", "crystal_quarry", "ascending_ridge"]:
		var m_data: Dictionary = scene.MISSIONS_DATA[m_id]
		_assert_true(m_data.has("purpose"), "%s has purpose description" % m_id)
		_assert_true(str(m_data["purpose"]).length() > 10, "%s purpose is descriptive" % m_id)

	scene.notification(CanvasItem.NOTIFICATION_DRAW)

	scene._close_mission_selector()
	_assert_false(scene.mission_selector_open, "mission selector closed")

	scene._toggle_mission_selector()
	_assert_true(scene.mission_selector_open, "mission selector toggled open")
	scene._close_mission_selector()


func _run_auto_benchmark_acceptance(scene: Control) -> void:
	var required_methods := [
		"run_auto_benchmark_suite",
		"generate_benchmark_report_markdown",
		"_is_player_id",
		"_calculate_log_metrics",
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "auto benchmark API exists: %s" % method)
	if not _failures.is_empty():
		return

	_test_auto_benchmark_constants_and_loadouts(scene)
	_test_auto_benchmark_suite_execution_and_metrics(scene)
	_test_auto_benchmark_sensible_vs_mismatched_divergence(scene)
	_test_auto_benchmark_markdown_report_generation(scene)


func _test_auto_benchmark_constants_and_loadouts(scene: Control) -> void:
	_assert_equal(scene.BENCHMARK_SEEDS.size(), 5, "five benchmark seeds defined")
	_assert_true(scene.BENCHMARK_SEEDS.has(1337), "benchmark seeds contains standard seed 1337")

	_assert_true(scene.SENSIBLE_LOADOUT.has("arlen"), "sensible loadout contains arlen")
	_assert_true(scene.SENSIBLE_LOADOUT.has("mira"), "sensible loadout contains mira")
	_assert_true(scene.SENSIBLE_LOADOUT.has("sera"), "sensible loadout contains sera")
	_assert_true(scene.SENSIBLE_LOADOUT.has("brann"), "sensible loadout contains brann")

	_assert_equal(scene.SENSIBLE_LOADOUT["mira"]["weapon"], "Sniper", "sensible mira uses Sniper with Hawkeye")
	_assert_equal(scene.SENSIBLE_LOADOUT["sera"]["weapon"], "Rifle", "sensible sera uses Rifle with Elemental Resonance")
	_assert_equal(scene.SENSIBLE_LOADOUT["brann"]["weapon"], "Sword", "sensible brann uses one weapon with Guardian Stance")
	_assert_equal(scene.SENSIBLE_LOADOUT["brann"]["off_hand"], "Shield", "sensible brann uses Shield off-hand")

	_assert_equal(scene.MISMATCHED_LOADOUT["mira"]["weapon"], "Sword", "mismatched mira uses Sword disabling Hawkeye")
	_assert_equal(scene.MISMATCHED_LOADOUT["sera"]["weapon"], "Sword", "mismatched sera uses Sword with no procs")
	_assert_false(scene.MISMATCHED_LOADOUT["sera"].has("off_hand"), "mismatched sera has no off-hand utility")
	_assert_equal(scene.MISMATCHED_LOADOUT["brann"]["weapon"], "Spear", "mismatched brann uses Spear with no shield")


func _test_auto_benchmark_suite_execution_and_metrics(scene: Control) -> void:
	var results: Dictionary = scene.run_auto_benchmark_suite([42, 1337])
	_assert_true(results.has("scenarios"), "suite results contain scenarios")
	var scenarios: Dictionary = results["scenarios"]
	_assert_true(scenarios.has("ancient_ruins_sensible"), "scenario ancient_ruins_sensible present")
	_assert_true(scenarios.has("ancient_ruins_mismatched"), "scenario ancient_ruins_mismatched present")
	_assert_true(scenarios.has("crystal_quarry_auto"), "scenario crystal_quarry_auto present")
	_assert_true(scenarios.has("ascending_ridge_uphill"), "scenario ascending_ridge_uphill present")
	_assert_true(scenarios.has("ascending_ridge_downhill"), "scenario ascending_ridge_downhill present")

	var sens: Dictionary = scenarios["ancient_ruins_sensible"]
	_assert_equal(sens["runs"].size(), 2, "sensible scenario executed 2 test seeds")
	var r0: Dictionary = sens["runs"][0]
	_assert_true(r0.has("player_damage_dealt"), "run summary contains player_damage_dealt")
	_assert_true(r0.has("player_damage_taken"), "run summary contains player_damage_taken")
	_assert_true(r0.has("player_wasted_turns"), "run summary contains player_wasted_turns")
	_assert_true(r0.has("enemy_wasted_turns"), "run summary contains enemy_wasted_turns")
	_assert_true(r0.has("player_destroyed_parts"), "run summary contains player_destroyed_parts")
	_assert_true(r0.has("enemy_destroyed_parts"), "run summary contains enemy_destroyed_parts")
	_assert_true(int(r0["player_damage_dealt"]) > 0, "player dealt positive damage in run")


func _test_auto_benchmark_sensible_vs_mismatched_divergence(scene: Control) -> void:
	scene._load_mission("ancient_ruins")
	scene.configure_player_loadouts(scene.SENSIBLE_LOADOUT)
	var sens_res: Dictionary = scene.run_auto_battle(150, 1337)

	scene._load_mission("ancient_ruins")
	scene.configure_player_loadouts(scene.MISMATCHED_LOADOUT)
	var mis_res: Dictionary = scene.run_auto_battle(150, 1337)

	_assert_equal(sens_res["winner"], "player", "sensible build wins on seed 1337")
	_assert_equal(mis_res["winner"], "enemy", "mismatched build loses on seed 1337")
	_assert_true(sens_res["activations"] < mis_res["activations"], "sensible build wins in fewer activations than mismatched build")
	_assert_true(sens_res["player_wasted_turns"] < mis_res["player_wasted_turns"], "sensible build wastes fewer turns")
	_assert_true(sens_res["player_damage_taken"] < mis_res["player_damage_taken"], "sensible build takes less damage")


func _test_auto_benchmark_markdown_report_generation(scene: Control) -> void:
	var results: Dictionary = scene.run_auto_benchmark_suite([42])
	var md: String = scene.generate_benchmark_report_markdown(results)
	_assert_true(md.contains("# Phase 1 Auto Benchmark & Replay Evidence Report"), "report header is present")
	_assert_true(md.contains("Build first, command second"), "report contains core premise")
	_assert_true(md.contains("Scenario 1: Ancient Ruins — Sensible vs Mismatched Build"), "scenario 1 table present")
	_assert_true(md.contains("Scenario 2: Ascending Ridge — Uphill Assault vs Downhill Defense"), "scenario 2 table present")
	_assert_true(md.contains("Scenario 3: Crystal Quarry — Repeatable Farm Battle"), "scenario 3 table present")
	_assert_true(md.contains("Answers to Phase 1 Design Questions"), "design question answers present")


func _run_visible_auto_playback_acceptance(scene: Control) -> void:
	# #30 — Visible Auto battle playback with optional fast simulation
	scene._load_mission("ancient_ruins", false)
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	scene.fast_simulation = true
	scene.simulation_seed = 1337
	var result_fast: Dictionary = scene.run_auto_battle(150, 1337)
	_assert_true(result_fast.get("activations", 0) > 0, "#30: fast auto completes activations")
	_assert_true(result_fast.has("winner"), "#30: fast auto produces a winner")

	scene._load_mission("ancient_ruins", false)
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	scene.fast_simulation = false
	scene.simulation_seed = 1337
	var result_visible: Dictionary = scene.run_auto_battle(150, 1337)
	_assert_equal(result_visible["activations"], result_fast["activations"],
		"#30: deterministic result matches between fast and non-fast auto")
	_assert_equal(result_visible["winner"], result_fast["winner"],
		"#30: winner matches between fast and non-fast auto")

	scene._load_mission("ancient_ruins", false)
	scene.enemy_presentation_enabled = true
	scene.attack_presentation_enabled = true
	scene.fast_simulation = false
	scene.auto_battle = true
	var arlen = scene._unit_by_id("arlen")
	_assert_true(arlen != null, "#30: arlen exists for visible auto test")
	if arlen != null:
		_assert_true(str(arlen.get("team", "")) == "player", "#30: arlen is player team")

	scene.enemy_presentation_active = true
	_assert_true(scene._input_locked(), "#30: input locked during enemy presentation")
	scene.enemy_presentation_active = false
	scene.attack_presentation_active = true
	_assert_true(scene._input_locked(), "#30: input locked during attack presentation")
	scene.attack_presentation_active = false
	_assert_false(scene._input_locked(), "#30: input unlocked when no presentation active")

	scene._set_fast_simulation(true)
	_assert_true(scene.fast_simulation, "#30: fast_simulation set to true")
	_assert_false(scene.enemy_presentation_enabled, "#30: enemy presentation disabled in fast sim")
	_assert_false(scene.attack_presentation_enabled, "#30: attack presentation disabled in fast sim")
	scene._set_fast_simulation(false)
	_assert_false(scene.fast_simulation, "#30: fast_simulation set to false")
	_assert_true(scene.enemy_presentation_enabled, "#30: enemy presentation enabled outside fast sim")
	_assert_true(scene.attack_presentation_enabled, "#30: attack presentation enabled outside fast sim")
	
	scene.auto_battle = false


func _run_combat_impact_acceptance(scene: Control) -> void:
	# #31 — Combat impact animation and concise combat event feed
	var required_methods := [
		"_add_event_message",
		"_add_floating_text",
		"_start_unit_shake",
		"_draw_event_feed",
		"_draw_floating_texts"
	]
	for method in required_methods:
		_assert_true(scene.has_method(method), "#31: Presentation method exists: %s" % method)
	if not _failures.is_empty():
		return

	scene._load_mission("ancient_ruins", false)
	scene.enemy_presentation_enabled = true
	scene.attack_presentation_enabled = true
	scene.fast_simulation = false
	scene.auto_battle = false

	var fixture_miss := _attack_presentation_fixture(scene, "Sniper")
	scene.enemy_presentation_enabled = true
	scene.attack_presentation_enabled = true
	scene.fast_simulation = false
	
	scene.event_feed_messages.clear()
	scene.floating_texts.clear()
	scene.unit_shakes.clear()
	scene.attack_feedback_step_seconds = 0.001
	
	# Force a miss
	scene.set_debug_seed(95)
	var preview_miss: Dictionary = scene._attack_preview(fixture_miss["attacker"], fixture_miss["target"])
	var result_miss: Dictionary = scene._resolve_attack_result(fixture_miss["attacker"], fixture_miss["target"], preview_miss, "", 95)
	
	await scene.battle_presenter.present_attack_feedback(scene, fixture_miss["attacker"], fixture_miss["target"], result_miss)
	_assert_true(scene.event_feed_messages.size() > 0, "#31: miss produces event feed message")
	var miss_feed: String = str(scene.event_feed_messages.back().get("text", "")) if scene.event_feed_messages.size() > 0 else ""
	_assert_true(miss_feed.to_lower().contains("miss"), "#31: event feed mentions miss")
	_assert_true(scene.floating_texts.size() > 0, "#31: miss produces floating text")
	var miss_float: String = str(scene.floating_texts.back().get("text", "")) if scene.floating_texts.size() > 0 else ""
	_assert_true(miss_float == "MISS", "#31: floating text says MISS")
	_assert_false(scene.unit_shakes.has(fixture_miss["target"]["id"]), "#31: miss does NOT shake target")

	scene.event_feed_messages.clear()
	scene.floating_texts.clear()
	
	# Force a hit
	var fixture_hit := _attack_presentation_fixture(scene, "Sniper")
	scene.enemy_presentation_enabled = true
	scene.attack_presentation_enabled = true
	scene.fast_simulation = false
	var preview_hit: Dictionary = scene._attack_preview(fixture_hit["attacker"], fixture_hit["target"])
	var result_hit: Dictionary = scene._resolve_attack_result(fixture_hit["attacker"], fixture_hit["target"], preview_hit, "", 1)
	await scene.battle_presenter.present_attack_feedback(scene, fixture_hit["attacker"], fixture_hit["target"], result_hit)
	
	var hit_messages: Array = scene.event_feed_messages.map(func(m): return str(m.get("text", "")))
	_assert_true(hit_messages.any(func(m): return m.contains("attacks")), "#31: hit produces attack announcement")
	_assert_true(hit_messages.any(func(m): return m.contains("-")), "#31: hit produces damage announcement")
	
	var hit_floats: Array = scene.floating_texts.map(func(f): return str(f.get("text", "")))
	_assert_true(hit_floats.any(func(f): return f.begins_with("-")), "#31: hit produces numeric floating damage")
	_assert_true(scene.unit_shakes.has(fixture_hit["target"]["id"]), "#31: hit DOES shake target")


func _run_phase1_architecture_acceptance(scene: Control) -> void:
	# #34 — architecture modules are loadable and wired without changing deterministic outcomes.
	for module_path in [
		"res://src/data/game_data.gd",
		"res://src/combat/grid_controller.gd",
		"res://src/combat/combat_controller.gd",
		"res://src/ai/battle_ai.gd",
		"res://src/presentation/battle_presenter.gd",
		"res://src/ui/battle_hud.gd"
	]:
		_assert_true(load(module_path) != null, "#34: module loads: %s" % module_path)

	for property_name in [
		"grid_controller",
		"combat_controller",
		"battle_ai",
		"battle_presenter",
		"battle_hud"
	]:
		_assert_true(scene.get(property_name) != null, "#34: scene wires %s" % property_name)

	_assert_true(scene.WEAPON_DATA == scene.game_data.WEAPON_DATA, "#34: weapon data is sourced from GameData")
	_assert_true(scene.ORB_DATA == scene.game_data.ORB_DATA, "#34: Orb data is sourced from GameData")
	_assert_true(scene.MISSIONS_DATA == scene.game_data.MISSIONS_DATA, "#34: mission data is sourced from GameData")

	for method in [
		"initialize_part_state",
		"damage_part",
		"damage_shield",
		"active_orbs",
		"resolve_turn_start_statuses"
	]:
		_assert_true(scene.combat_controller.has_method(method), "#34: CombatController owns %s" % method)

	_assert_true(scene.battle_ai.has_method("plan_activation"), "#34: BattleAI owns planning")
	_assert_true(scene.battle_presenter.has_method("present_enemy_activation"), "#34: BattlePresenter owns enemy presentation sequencing")
	_assert_true(scene.battle_hud.has_method("target_inspection_data"), "#34: BattleHud owns inspection data shaping")

	scene.fast_simulation = true
	scene.auto_battle = false
	scene._load_mission("ancient_ruins", false)
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var first_result: Dictionary = scene.run_auto_battle(60, 4242)
	scene.fast_simulation = true
	scene.auto_battle = false
	scene._load_mission("ancient_ruins", false)
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var replay_result: Dictionary = scene.run_auto_battle(60, 4242)
	_assert_equal(replay_result["winner"], first_result["winner"], "#34: same seed replay preserves winner")
	_assert_equal(replay_result["turn_log"], first_result["turn_log"], "#34: same seed replay preserves deterministic combat log")


func _run_phase2_build_model_acceptance(scene: Control) -> void:
	# #35 — Phase 2 build/loadout domain model.
	var model = MechBuildModelScript.new()
	for method in [
		"prototype_builds",
		"validate_build",
		"normalize_build",
		"build_summary",
		"battle_loadout_for_build",
		"weapon_handedness"
	]:
		_assert_true(model.has_method(method), "#35: build model exposes %s" % method)
	if not _failures.is_empty():
		return

	_test_phase2_default_builds_validate(scene, model)
	_test_phase2_weapon_handedness_and_off_hand_rules(scene, model)
	_test_phase2_invalid_builds_are_rejected_or_normalized(scene, model)
	_test_phase2_orb_slots_and_battle_loadout_are_derived(scene, model)


func _test_phase2_default_builds_validate(scene: Control, model) -> void:
	var builds: Dictionary = model.prototype_builds()
	for unit_id in ["arlen", "mira", "sera", "brann"]:
		_assert_true(builds.has(unit_id), "#35: prototype build exists for %s" % unit_id)
		var build: Dictionary = builds.get(unit_id, {})
		var validation: Dictionary = model.validate_build(build, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
		_assert_true(bool(validation.get("valid", false)), "#35: default build validates for %s" % unit_id)
		var parts: Dictionary = build.get("parts", {})
		for part_name in scene.PART_NAMES:
			_assert_true(parts.has(part_name), "#35: %s build configures %s" % [unit_id, part_name])

	_assert_equal(builds["arlen"]["weapon"], "Spear", "#35: Arlen keeps Phase 1 spear role as a 2H build")
	_assert_equal(builds["mira"]["weapon"], "Sniper", "#35: Mira keeps Phase 1 sniper role as a 2H build")
	_assert_equal(builds["sera"]["weapon"], "Rifle", "#35: Sera keeps Phase 1 rifle role as a 1H build")
	_assert_equal(builds["brann"]["off_hand"], "Shield", "#35: Brann preserves shield identity as off-hand equipment")


func _test_phase2_weapon_handedness_and_off_hand_rules(scene: Control, model) -> void:
	_assert_equal(model.weapon_handedness("Sword"), "1H", "#35: Sword is 1H")
	_assert_equal(model.weapon_handedness("Rifle"), "1H", "#35: Rifle is 1H")
	_assert_equal(model.weapon_handedness("Spear"), "2H", "#35: Spear is 2H")
	_assert_equal(model.weapon_handedness("Sniper"), "2H", "#35: Sniper is 2H")
	_assert_equal(model.weapon_handedness("Shield"), "", "#35: Shield is not a weapon")

	var builds: Dictionary = model.prototype_builds()
	var brann_summary: Dictionary = model.build_summary(builds["brann"], scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_equal(brann_summary["weapon_handedness"], "1H", "#35: Brann's weapon uses one hand")
	_assert_equal(brann_summary["weapon_arm"], "Right Arm", "#35: 1H weapons mount to right arm")
	_assert_true(bool(brann_summary["off_hand_slot_enabled"]), "#35: 1H weapons keep off-hand enabled")
	_assert_equal(brann_summary["off_hand"], "Shield", "#35: shield is off-hand equipment")
	_assert_true(bool(brann_summary["has_shield"]), "#35: shield summary flags shield behavior")

	var arlen_summary: Dictionary = model.build_summary(builds["arlen"], scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_equal(arlen_summary["weapon_handedness"], "2H", "#35: Spear uses both hands")
	_assert_true(bool(arlen_summary["uses_both_arms"]), "#35: 2H weapon reserves both arms")
	_assert_false(bool(arlen_summary["off_hand_slot_enabled"]), "#35: 2H weapon disables off-hand slot")
	_assert_equal(arlen_summary["off_hand"], "", "#35: 2H summary has no off-hand equipment")


func _test_phase2_invalid_builds_are_rejected_or_normalized(scene: Control, model) -> void:
	var builds: Dictionary = model.prototype_builds()
	var sniper_shield: Dictionary = builds["mira"].duplicate(true)
	sniper_shield["off_hand"] = "Shield"
	var invalid_two_hand: Dictionary = model.validate_build(sniper_shield, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_false(bool(invalid_two_hand.get("valid", true)), "#35: Sniper + Shield raw build is invalid")
	_assert_true(str(invalid_two_hand.get("errors", [])).contains("2H"), "#35: invalid reason names 2H off-hand rule")

	var normalized: Dictionary = model.normalize_build(sniper_shield, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_equal(normalized["off_hand"], "", "#35: normalization removes off-hand from 2H weapon")
	var normalized_validation: Dictionary = model.validate_build(normalized, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_true(bool(normalized_validation.get("valid", false)), "#35: normalized Sniper build validates")

	var shield_weapon: Dictionary = builds["brann"].duplicate(true)
	shield_weapon["weapon"] = "Shield"
	var invalid_shield_weapon: Dictionary = model.validate_build(shield_weapon, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_false(bool(invalid_shield_weapon.get("valid", true)), "#35: Shield cannot be equipped as the required weapon")

	var missing_part: Dictionary = builds["sera"].duplicate(true)
	missing_part["parts"].erase("Head")
	var invalid_missing_part: Dictionary = model.validate_build(missing_part, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_false(bool(invalid_missing_part.get("valid", true)), "#35: missing required mech part is invalid")


func _test_phase2_orb_slots_and_battle_loadout_are_derived(scene: Control, model) -> void:
	var builds: Dictionary = model.prototype_builds()
	var brann_summary: Dictionary = model.build_summary(builds["brann"], scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	var orb_slots: Dictionary = brann_summary.get("orb_slots", {})
	for part_name in scene.PART_NAMES:
		_assert_true(orb_slots.has(part_name), "#35: derived summary exposes Orb slot for %s" % part_name)
	_assert_equal(orb_slots["Left Arm"], "earth_ssr", "#35: Brann's default Orb stays on Left Arm")

	var loadout: Dictionary = model.battle_loadout_for_build(builds["brann"], scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_equal(loadout["pilot"], "brann", "#35: battle loadout keeps pilot separate")
	_assert_equal(loadout["weapon"], "Sword", "#35: battle loadout exposes the required weapon")
	_assert_equal(loadout["off_hand"], "Shield", "#35: battle loadout exposes shield as off-hand")
	_assert_true(bool(loadout["has_shield"]), "#35: battle loadout exposes shield behavior")
	_assert_equal(loadout["weapon_mount_part"], "Right Arm", "#35: battle setup can mount 1H weapon")
	_assert_equal(loadout["orbs"]["Left Arm"], "earth_ssr", "#35: battle loadout carries Orb slots")


func _run_phase2_hangar_shell_acceptance(scene: Control) -> void:
	# #36 — Hangar shell and mech part overview.
	var packed_scene: PackedScene = load("res://scenes/hangar.tscn")
	_assert_true(packed_scene != null, "#36: Hangar scene loads")
	_assert_true(HangarScreenScript != null, "#36: Hangar script loads")
	if packed_scene == null:
		return

	var hangar: Control = packed_scene.instantiate() as Control
	root.add_child(hangar)
	await process_frame

	for method in [
		"select_unit",
		"select_next_unit",
		"select_previous_unit",
		"current_build_summary",
		"part_rows",
		"weapon_panel_data",
		"layout_metrics"
	]:
		_assert_true(hangar.has_method(method), "#36: Hangar exposes %s" % method)
	if not _failures.is_empty():
		hangar.queue_free()
		return

	_test_phase2_hangar_switches_between_units(hangar)
	_test_phase2_hangar_part_rows_show_build_overview(scene, hangar)
	_test_phase2_hangar_weapon_and_off_hand_state(hangar)
	_test_phase2_hangar_uses_model_summary(scene, hangar)
	_test_phase2_hangar_pointer_navigation(hangar)
	_test_phase2_hangar_layout_bounds(hangar)
	hangar.queue_free()


func _test_phase2_hangar_switches_between_units(hangar: Control) -> void:
	_assert_equal(hangar.current_unit_id, "arlen", "#36: Hangar opens on Arlen")
	var visited: Array[String] = []
	for _i in range(4):
		visited.append(str(hangar.current_unit_id))
		hangar.select_next_unit()
	_assert_equal(visited, ["arlen", "mira", "sera", "brann"], "#36: next cycles through all four units")
	_assert_equal(hangar.current_unit_id, "arlen", "#36: next wraps without leaving Hangar")

	hangar.select_previous_unit()
	_assert_equal(hangar.current_unit_id, "brann", "#36: previous wraps to Brann")
	_assert_true(hangar.select_unit("sera"), "#36: direct unit selection succeeds")
	_assert_equal(hangar.current_unit_id, "sera", "#36: direct selection updates current unit")
	_assert_false(hangar.select_unit("unknown"), "#36: unknown unit selection is rejected")
	_assert_equal(hangar.current_unit_id, "sera", "#36: rejected selection keeps current unit")


func _test_phase2_hangar_part_rows_show_build_overview(scene: Control, hangar: Control) -> void:
	hangar.select_unit("brann")
	var rows: Array = hangar.part_rows()
	_assert_equal(rows.size(), scene.PART_NAMES.size(), "#36: Hangar shows five primary part rows")
	for index in range(scene.PART_NAMES.size()):
		var row: Dictionary = rows[index]
		_assert_equal(row["part_name"], scene.PART_NAMES[index], "#36: part row order follows source-of-truth parts")
		_assert_true(str(row.get("part_id", "")) != "", "#36: part row has equipped part identity")
		_assert_true(str(row.get("durability", "")).contains("HP"), "#36: part row shows durability contribution")
		_assert_true(row.has("orb_state"), "#36: part row exposes Orb slot state")
	_assert_equal(rows[2]["orb_id"], "earth_ssr", "#36: Left Arm row shows Brann's installed Orb")
	_assert_equal(rows[2]["orb_state"], "Earth Bulwark", "#36: Orb slot state names installed Orb")


func _test_phase2_hangar_weapon_and_off_hand_state(hangar: Control) -> void:
	hangar.select_unit("arlen")
	var arlen_panel: Dictionary = hangar.weapon_panel_data()
	_assert_equal(arlen_panel["weapon"], "Spear", "#36: Arlen weapon appears")
	_assert_equal(arlen_panel["weapon_handedness"], "2H", "#36: Arlen spear is shown as 2H")
	_assert_equal(arlen_panel["arm_occupancy"], "Both Arms", "#36: 2H weapon communicates both arms occupied")
	_assert_equal(arlen_panel["off_hand"], "Disabled by 2H weapon", "#36: 2H build explains off-hand disabled")

	hangar.select_unit("brann")
	var brann_panel: Dictionary = hangar.weapon_panel_data()
	_assert_equal(brann_panel["weapon"], "Sword", "#36: Brann weapon appears")
	_assert_equal(brann_panel["weapon_handedness"], "1H", "#36: Brann sword is shown as 1H")
	_assert_equal(brann_panel["arm_occupancy"], "Right Arm weapon / Left Arm off-hand", "#36: 1H build communicates right/off-hand split")
	_assert_equal(brann_panel["off_hand"], "Shield", "#36: Shield appears as off-hand equipment")


func _test_phase2_hangar_uses_model_summary(scene: Control, hangar: Control) -> void:
	hangar.select_unit("mira")
	var summary: Dictionary = hangar.current_build_summary()
	var model_summary: Dictionary = hangar.build_model.build_summary(
		hangar.builds["mira"],
		scene.WEAPON_DATA,
		scene.ORB_DATA,
		scene.PART_NAMES
	)
	_assert_equal(summary["weapon"], model_summary["weapon"], "#36: Hangar weapon reads from build model")
	_assert_equal(summary["weapon_handedness"], model_summary["weapon_handedness"], "#36: Hangar handedness reads from build model")
	_assert_equal(summary["orb_slots"], model_summary["orb_slots"], "#36: Hangar Orb slots read from build model")


func _test_phase2_hangar_pointer_navigation(hangar: Control) -> void:
	hangar.select_unit("arlen")
	hangar.nav_rects["next"] = Rect2(Vector2(0, 0), Vector2(40, 40))
	hangar.unit_tab_rects["brann"] = Rect2(Vector2(50, 0), Vector2(80, 40))
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(10, 10)
	hangar._gui_input(click)
	_assert_equal(hangar.current_unit_id, "mira", "#36: pointer input can move to next unit")

	click.position = Vector2(60, 10)
	hangar._gui_input(click)
	_assert_equal(hangar.current_unit_id, "brann", "#36: pointer input can select a unit tab")


func _test_phase2_hangar_layout_bounds(hangar: Control) -> void:
	var metrics: Dictionary = hangar.layout_metrics()
	_assert_equal(metrics["design_size"], Vector2(1280, 590), "#36: Hangar targets fixed landscape resolution")
	_assert_true(bool(metrics["within_design_bounds"]), "#36: Hangar layout stays inside landscape bounds")
	_assert_true(float(metrics["part_row_height"]) >= 48.0, "#36: part rows remain readable on mobile landscape")


func _run_phase2_part_swap_tradeoffs_acceptance(scene: Control) -> void:
	# #37 — Part swapping with meaningful trade-offs and stat deltas.
	var model = MechBuildModelScript.new()
	for method in [
		"part_catalog",
		"build_stats",
		"part_delta",
		"swap_part",
		"strictly_superior_options"
	]:
		_assert_true(model.has_method(method), "#37: build model exposes %s" % method)
	if not _failures.is_empty():
		return

	_test_phase2_part_catalog_has_sidegrades(scene, model)
	_test_phase2_part_delta_uses_existing_stats(scene, model)
	_test_phase2_part_swap_preserves_orb_slot(scene, model)
	_test_phase2_hangar_part_swap_flow(scene, model)


func _test_phase2_part_catalog_has_sidegrades(scene: Control, model) -> void:
	for part_name in scene.PART_NAMES:
		var options: Array = model.part_catalog(part_name)
		_assert_true(options.size() >= 2, "#37: %s has multiple prototype options" % part_name)
		_assert_equal(model.strictly_superior_options(part_name), [], "#37: %s catalog has no strictly superior option" % part_name)


func _test_phase2_part_delta_uses_existing_stats(scene: Control, model) -> void:
	var build: Dictionary = model.prototype_builds()["arlen"]
	var delta: Dictionary = model.part_delta(build, "Legs", "sprinter_legs", scene.PART_NAMES)
	_assert_equal(delta["part_name"], "Legs", "#37: delta names the highlighted part")
	_assert_equal(delta["from_part"], "aegis_legs", "#37: delta records current part")
	_assert_equal(delta["to_part"], "sprinter_legs", "#37: delta records candidate part")
	_assert_true(delta["display_lines"].has("Move 3 -> 4"), "#37: delta shows Move increase")
	_assert_true(delta["display_lines"].has("Legs HP 100 -> 72"), "#37: delta shows HP trade-off")
	_assert_true(int(delta["stat_delta"]["dodge"]) > 0, "#37: sprinter legs improve Dodge")
	_assert_true(int(delta["stat_delta"]["max_hp"]) < 0, "#37: sprinter legs reduce durability")


func _test_phase2_part_swap_preserves_orb_slot(scene: Control, model) -> void:
	var build: Dictionary = model.prototype_builds()["brann"]
	var swapped: Dictionary = model.swap_part(build, "Left Arm", "guard_left_arm", scene.PART_NAMES)
	_assert_equal(swapped["parts"]["Left Arm"], "guard_left_arm", "#37: part swap updates authoritative build part")
	_assert_equal(swapped["orbs"]["Left Arm"], "earth_ssr", "#37: part swap preserves Orb slot association")
	var validation: Dictionary = model.validate_build(swapped, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_true(bool(validation.get("valid", false)), "#37: swapped build remains valid")


func _test_phase2_hangar_part_swap_flow(scene: Control, model) -> void:
	var hangar := HangarScreenScript.new()
	hangar._ready()
	hangar.select_unit("arlen")
	_assert_true(hangar.highlight_part("Legs"), "#37: Hangar can highlight Legs")
	var options: Array = hangar.available_part_options("Legs")
	_assert_true(options.size() >= 2, "#37: Hangar exposes part choices")
	var preview: Dictionary = hangar.preview_part_delta("Legs", "sprinter_legs")
	_assert_true(preview["display_lines"].has("Move 3 -> 4"), "#37: Hangar previews stat delta before commit")
	_assert_true(hangar.swap_part("Legs", "sprinter_legs"), "#37: Hangar commits selected part")
	var summary: Dictionary = hangar.current_build_summary()
	_assert_equal(summary["parts"]["Legs"], "sprinter_legs", "#37: Hangar updates model-backed build after swap")
	var rows: Array = hangar.part_rows()
	_assert_equal(rows[4]["part_id"], "sprinter_legs", "#37: Hangar part rows refresh after swap")
	_assert_equal(model.build_stats(hangar.builds["arlen"])["move"], 4, "#37: swapped build updates derived Move")
	hangar.queue_free()


func _run_phase2_weapon_offhand_rules_acceptance(scene: Control) -> void:
	# #38 — Weapon handedness and off-hand equipment in battle.
	for method in [
		"_off_hand_data_for",
		"_configure_unit_equipment_state",
		"_weapon_required_parts",
		"_has_off_hand_shield"
	]:
		_assert_true(scene.has_method(method), "#38: battle scene exposes %s" % method)
	if not _failures.is_empty():
		return

	_test_phase2_invalid_two_hand_offhand_is_not_equipped(scene)
	_test_phase2_one_hand_weapon_can_use_shield_offhand(scene)
	_test_phase2_one_hand_arm_destruction_rules(scene)
	_test_phase2_two_hand_arm_destruction_rules(scene)
	_test_phase2_attack_has_no_weapon_choice_command(scene)


func _test_phase2_invalid_two_hand_offhand_is_not_equipped(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	scene.configure_player_loadouts({
		"arlen": {
			"weapon": "Sniper",
			"off_hand": "Shield",
		},
	})
	var arlen = scene._unit_by_id("arlen")
	_assert_equal(arlen["weapon"], "Sniper", "#38: 2H weapon remains equipped")
	_assert_equal(arlen["off_hand"], "", "#38: invalid 2H off-hand is removed")
	_assert_false(scene._has_off_hand_shield(arlen), "#38: 2H + Shield cannot be equipped")
	_assert_equal(int(arlen["shield_max_hp"]), 0, "#38: rejected Shield grants no Shield HP")


func _test_phase2_one_hand_weapon_can_use_shield_offhand(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	scene.configure_player_loadouts({
		"sera": {
			"weapon": "Rifle",
			"off_hand": "Shield",
		},
	})
	var sera = scene._unit_by_id("sera")
	_assert_equal(sera["weapon"], "Rifle", "#38: Rifle remains attack weapon")
	_assert_equal(sera["off_hand"], "Shield", "#38: Shield equips as off-hand")
	_assert_true(scene._has_off_hand_shield(sera), "#38: 1H + Shield is active")
	_assert_true(int(sera["shield_max_hp"]) > 0, "#38: Shield off-hand grants Shield HP")


func _test_phase2_one_hand_arm_destruction_rules(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	scene.configure_player_loadouts({
		"sera": {
			"weapon": "Rifle",
			"off_hand": "Shield",
		},
	})
	var sera = scene._unit_by_id("sera")
	scene._damage_part(sera, "Left Arm", 100)
	_assert_false(bool(sera["weapon_disabled"]), "#38: 1H left arm loss does not disable right-arm weapon")
	_assert_true(bool(sera["off_hand_disabled"]), "#38: left arm loss disables off-hand")
	_assert_false(scene._shield_is_active(sera), "#38: disabled off-hand Shield cannot guard")

	scene._load_mission("ancient_ruins", false)
	scene.configure_player_loadouts({
		"sera": {
			"weapon": "Rifle",
			"off_hand": "Shield",
		},
	})
	sera = scene._unit_by_id("sera")
	scene._damage_part(sera, "Right Arm", 100)
	_assert_true(bool(sera["weapon_disabled"]), "#38: 1H right arm loss disables weapon")
	_assert_false(bool(sera["off_hand_disabled"]), "#38: right arm loss does not disable off-hand by itself")


func _test_phase2_two_hand_arm_destruction_rules(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	scene.configure_player_loadouts({
		"arlen": {
			"weapon": "Spear",
		},
	})
	var arlen = scene._unit_by_id("arlen")
	scene._damage_part(arlen, "Left Arm", 100)
	_assert_true(bool(arlen["weapon_disabled"]), "#38: 2H left arm loss disables weapon")

	scene._load_mission("ancient_ruins", false)
	scene.configure_player_loadouts({
		"arlen": {
			"weapon": "Spear",
		},
	})
	arlen = scene._unit_by_id("arlen")
	scene._damage_part(arlen, "Right Arm", 100)
	_assert_true(bool(arlen["weapon_disabled"]), "#38: 2H right arm loss disables weapon")


func _test_phase2_attack_has_no_weapon_choice_command(scene: Control) -> void:
	_assert_equal(scene.PRIMARY_ACTIONS, ["Move", "Attack", "Wait"], "#38: primary commands remain Move Attack Wait")
	_assert_false(scene.PRIMARY_ACTIONS.has("Weapon"), "#38: no weapon-selection command exists")
	_assert_false(scene.PRIMARY_ACTIONS.has("Item"), "#38: off-hand does not add item command")


func _run_phase2_orb_installation_acceptance(scene: Control) -> void:
	var GameDataScript = load("res://src/data/game_data.gd")
	var model = preload("res://src/data/mech_build_model.gd").new()
	var HangarScreenScript = load("res://src/ui/hangar_screen.gd")

	for method in ["install_orb", "remove_orb"]:
		_assert_true(model.has_method(method), "#39: build model exposes %s" % method)
	if not _failures.is_empty(): return

	_test_phase2_install_orb(scene, model)
	_test_phase2_remove_orb(scene, model)
	_test_phase2_hangar_orb_flow(scene, model, HangarScreenScript)
	_test_phase2_battle_uses_configured_orb_loadout_and_host_part_destruction(scene, model)


func _test_phase2_install_orb(scene: Control, model) -> void:
	var build: Dictionary = model.prototype_builds()["sera"]
	var updated = model.install_orb(build, "Head", "lightning_r", scene.PART_NAMES)
	_assert_equal(updated["orbs"]["Head"], "lightning_r", "#39: install_orb sets Orb correctly")
	_assert_true(model.validate_build(updated, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)["valid"], "#39: build with orb valid")


func _test_phase2_remove_orb(scene: Control, model) -> void:
	var build: Dictionary = model.prototype_builds()["sera"]
	build = model.install_orb(build, "Head", "lightning_r", scene.PART_NAMES)
	var removed = model.remove_orb(build, "Head", scene.PART_NAMES)
	_assert_false(removed["orbs"].has("Head"), "#39: remove_orb clears Orb slot")


func _test_phase2_hangar_orb_flow(scene: Control, model, HangarScreenScript) -> void:
	var hangar = HangarScreenScript.new()
	hangar._ready()
	hangar.select_unit("sera")
	_assert_true(hangar.highlight_part("Head"), "#39: Hangar highlights Head")
	var options = hangar.available_orb_options("Head")
	_assert_true(options.size() > 0, "#39: Hangar exposes orb choices")
	_assert_true(hangar.install_orb("Head", "lightning_r"), "#39: Hangar commits orb install")
	_assert_equal(hangar.current_build_summary()["orb_slots"]["Head"], "lightning_r", "#39: Hangar updates model after orb install")
	_assert_true(hangar.install_orb("Head", "water_r"), "#39: Hangar replaces existing orb")
	_assert_equal(hangar.current_build_summary()["orb_slots"]["Head"], "water_r", "#39: Hangar updates model after orb replace")
	_assert_true(hangar.remove_orb("Head"), "#39: Hangar removes orb")
	_assert_equal(hangar.current_build_summary()["orb_slots"]["Head"], "", "#39: Hangar updates model after orb remove")
	hangar.queue_free()


func _test_phase2_battle_uses_configured_orb_loadout_and_host_part_destruction(scene: Control, model) -> void:
	scene._load_mission("ancient_ruins", false)
	var build: Dictionary = model.prototype_builds()["sera"]
	build = model.install_orb(build, "Head", "lightning_r", scene.PART_NAMES)
	var loadout: Dictionary = model.battle_loadout_for_build(build, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	scene.configure_player_loadouts({"sera": loadout})
	var sera = scene._unit_by_id("sera")
	_assert_equal(sera["parts"]["Head"]["orb"], "lightning_r", "#39: battle unit equips configured Orb on Head")
	scene._damage_part(sera, "Head", 100)
	_assert_true(bool(sera["parts"]["Head"]["orb_disabled"]), "#39: destroying host part disables configured Orb")


func _run_phase2_build_summary_and_signals_acceptance(scene: Control) -> void:
	var model = preload("res://src/data/mech_build_model.gd").new()
	var HangarScreenScript = load("res://src/ui/hangar_screen.gd")

	_assert_true(model.has_method("build_signals"), "#40: build model exposes build_signals")
	if not _failures.is_empty():
		return

	_test_phase2_build_signals_content(scene, model)
	_test_phase2_build_signals_react_to_changes(scene, model)
	_test_phase2_hangar_signals_flow(scene, model, HangarScreenScript)


func _test_phase2_build_signals_content(scene: Control, model) -> void:
	var build: Dictionary = model.prototype_builds()["mira"]
	var signals: Dictionary = model.build_signals(build, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_true(signals.has("summary_line"), "#40: signals include summary_line")
	_assert_true(signals.has("role_tags"), "#40: signals include role_tags")
	_assert_true(signals.has("key_stats"), "#40: signals include key_stats")
	_assert_true(signals["summary_line"].contains("Sniper"), "#40: summary line contains weapon identity")
	_assert_true(signals["summary_line"].contains("2H"), "#40: summary line contains handedness")
	_assert_true(signals["summary_line"].contains("Move"), "#40: summary line contains Move signal")


func _test_phase2_build_signals_react_to_changes(scene: Control, model) -> void:
	var build: Dictionary = model.prototype_builds()["mira"]
	var initial_signals: Dictionary = model.build_signals(build, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	var initial_move: int = int(initial_signals["key_stats"]["move"])

	var modified: Dictionary = model.swap_part(build, "Legs", "sprinter_legs", scene.PART_NAMES)
	var modified_signals: Dictionary = model.build_signals(modified, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_equal(int(modified_signals["key_stats"]["move"]), initial_move + 1, "#40: signals reflect updated Move")

	# Shield off-hand reaction
	var sera_build: Dictionary = model.prototype_builds()["sera"]
	var sera_shield: Dictionary = sera_build.duplicate(true)
	sera_shield["off_hand"] = "Shield"
	var shield_signals: Dictionary = model.build_signals(sera_shield, scene.WEAPON_DATA, scene.ORB_DATA, scene.PART_NAMES)
	_assert_true(shield_signals["role_tags"].has("Shield Guard") or shield_signals["summary_line"].contains("Shield"), "#40: signals reflect Shield off-hand")


func _test_phase2_hangar_signals_flow(scene: Control, model, HangarScreenScript) -> void:
	var hangar = HangarScreenScript.new()
	hangar._ready()
	hangar.select_unit("mira")
	_assert_true(hangar.has_method("current_build_signals"), "#40: hangar exposes current_build_signals")
	var sigs: Dictionary = hangar.current_build_signals()
	_assert_true(sigs.has("summary_line"), "#40: hangar returns build signals")
	_assert_true(sigs["summary_line"].contains("Sniper"), "#40: hangar signals match current unit build")

	hangar.swap_part("Legs", "sprinter_legs")
	var updated_sigs: Dictionary = hangar.current_build_signals()
	_assert_equal(int(updated_sigs["key_stats"]["move"]), 4, "#40: hangar signals update immediately on part change")
	hangar.queue_free()


func _run_phase2_squad_deploy_builds_acceptance(scene: Control) -> void:
	var HangarScreenScript = load("res://src/ui/hangar_screen.gd")
	var hangar = HangarScreenScript.new()
	hangar._ready()

	_assert_true(hangar.has_signal("deploy_requested"), "#41: hangar has deploy_requested signal")
	_assert_true(hangar.has_method("squad_overview"), "#41: hangar has squad_overview method")
	_assert_true(hangar.has_method("deploy_loadouts"), "#41: hangar has deploy_loadouts method")
	_assert_true(hangar.has_method("deploy"), "#41: hangar has deploy method")
	_assert_true(scene.has_method("deploy_hangar_builds"), "#41: scene has deploy_hangar_builds method")
	_assert_true(scene.has_method("configure_player_builds"), "#41: scene has configure_player_builds method")

	if not _failures.is_empty():
		hangar.queue_free()
		return

	_test_phase2_squad_overview_content(hangar)
	_test_phase2_deploy_hangar_builds_to_battle(scene, hangar)
	_test_phase2_redeploy_after_hangar_change(scene, hangar)
	hangar.queue_free()


func _test_phase2_squad_overview_content(hangar) -> void:
	var overview: Array = hangar.squad_overview()
	_assert_equal(overview.size(), 4, "#41: squad overview contains all 4 units")
	for unit_info in overview:
		_assert_true(unit_info.has("unit_id"), "#41: squad item has unit_id")
		_assert_true(unit_info.has("pilot"), "#41: squad item has pilot")
		_assert_true(unit_info.has("mech"), "#41: squad item has mech")
		_assert_true(unit_info.has("weapon"), "#41: squad item has weapon")
		_assert_true(unit_info.has("move"), "#41: squad item has move")
		_assert_true(unit_info.has("summary_line"), "#41: squad item has summary_line")


func _test_phase2_deploy_hangar_builds_to_battle(scene: Control, hangar) -> void:
	scene._load_mission("ancient_ruins", false)
	hangar.select_unit("arlen")
	hangar.swap_part("Legs", "sprinter_legs")
	hangar.install_orb("Head", "lightning_r")

	hangar.select_unit("sera")
	var sera_build = hangar.builds["sera"].duplicate(true)
	sera_build["off_hand"] = "Shield"
	hangar.builds["sera"] = sera_build

	scene.deploy_hangar_builds(hangar)

	var arlen = scene._unit_by_id("arlen")
	_assert_equal(int(arlen["base_move_range"]), 4, "#41: Arlen deployed with sprinter_legs Move 4")
	_assert_equal(int(arlen["parts"]["Legs"]["max_hp"]), 72, "#41: Arlen Legs part HP updated from sprinter_legs")
	_assert_equal(arlen["parts"]["Head"]["orb"], "lightning_r", "#41: Arlen deployed with installed Head Orb")

	var sera = scene._unit_by_id("sera")
	_assert_equal(sera["off_hand"], "Shield", "#41: Sera deployed with Shield off-hand")
	_assert_true(scene._has_off_hand_shield(sera), "#41: Sera has active off-hand Shield in battle")


func _test_phase2_redeploy_after_hangar_change(scene: Control, hangar) -> void:
	scene._load_mission("ancient_ruins", false)
	hangar.select_unit("arlen")
	hangar.swap_part("Legs", "bulwark_legs")

	scene.deploy_hangar_builds(hangar)

	var arlen = scene._unit_by_id("arlen")
	_assert_equal(int(arlen["base_move_range"]), 2, "#41: Arlen re-deployed with bulwark_legs Move 2")
	_assert_equal(int(arlen["parts"]["Legs"]["max_hp"]), 132, "#41: Arlen Legs part HP updated from bulwark_legs")


func _run_phase2_current_vs_inspected_hud_acceptance(scene: Control) -> void:
	var hud = scene.battle_hud
	for method in [
		"draw_current_unit_panel",
		"draw_inspected_unit_panel",
		"current_unit",
		"inspected_unit",
	]:
		_assert_true(hud.has_method(method), "#42: battle_hud exposes %s" % method)

	if not _failures.is_empty():
		return

	_test_phase2_left_panel_tracks_active_unit(scene)
	_test_phase2_inspecting_enemy_tracks_right_panel_without_changing_turn(scene)
	_test_phase2_inspecting_ally_tracks_right_panel_without_changing_turn(scene)
	_test_phase2_both_panels_reflect_part_and_orb_status(scene)


func _test_phase2_left_panel_tracks_active_unit(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	var active = scene.active_unit
	_assert_equal(scene.battle_hud.current_unit(scene)["id"], active["id"], "#42: Left panel tracks current active unit")


func _test_phase2_inspecting_enemy_tracks_right_panel_without_changing_turn(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	var enemy = scene._unit_by_id("enemy_spear")
	scene.battle_hud.inspect_unit(scene, enemy)
	_assert_equal(scene.battle_hud.inspected_unit(scene)["id"], "enemy_spear", "#42: Right panel tracks inspected enemy")
	_assert_equal(scene.active_unit["id"], "arlen", "#42: Inspecting enemy does not transfer turn ownership")
	_assert_equal(scene.battle_hud.current_unit(scene)["id"], "arlen", "#42: Left panel remains current active unit")


func _test_phase2_inspecting_ally_tracks_right_panel_without_changing_turn(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	var ally = scene._unit_by_id("mira")
	scene.battle_hud.inspect_unit(scene, ally)
	_assert_equal(scene.battle_hud.inspected_unit(scene)["id"], "mira", "#42: Right panel tracks inspected ally")
	_assert_equal(scene.active_unit["id"], "arlen", "#42: Inspecting ally does not transfer turn ownership")
	_assert_equal(scene.battle_hud.current_unit(scene)["id"], "arlen", "#42: Left panel remains current active unit")


func _test_phase2_both_panels_reflect_part_and_orb_status(scene: Control) -> void:
	scene._load_mission("ancient_ruins", false)
	var enemy = scene._unit_by_id("enemy_spear")
	scene.battle_hud.inspect_unit(scene, enemy)
	scene._damage_part(enemy, "Left Arm", 100)
	var inspected = scene.battle_hud.inspected_unit(scene)
	_assert_true(bool(inspected["parts"]["Left Arm"]["destroyed"]), "#42: inspected unit reflects destroyed part")
	var current = scene.battle_hud.current_unit(scene)
	_assert_equal(current["id"], "arlen", "#42: current unit remains intact")


func _run_phase2_build_fun_validation_acceptance(scene: Control) -> void:
	_test_phase2_build_validation_methods_exist(scene)
	_test_phase2_mira_build_comparison(scene)
	await _test_phase2_playable_flow()


func _run_phase2_effective_build_stats_acceptance(scene: Control) -> void:
	var controller = scene.combat_controller
	for method in ["configured_speed", "effective_dodge", "effective_defense", "defense_adjusted_damage"]:
		_assert_true(controller.has_method(method), "#60: CombatController owns %s" % method)
	if not _failures.is_empty():
		return
	scene._load_mission("ancient_ruins", false)
	var builds: Dictionary = scene.mech_build_model.prototype_builds()
	scene.configure_player_builds(builds)
	var sera = scene._unit_by_id("sera")
	var brann = scene._unit_by_id("brann")
	_assert_equal(sera["speed"], 15, "#60: part Speed modifies data-driven pilot Speed")
	_assert_equal(scene._effective_dodge(brann), 7, "#60: active Earth Orb adds Dodge to frame rating")
	_assert_equal(scene._effective_defense(brann), 28, "#60: active Earth Orb adds Defense")
	var enemy = scene._unit_by_id("enemy_blade")
	_assert_equal(scene._calculate_attack_damage(enemy, 100, brann, "Body"), 72, "#60: Defense reduces part damage by percentage")
	_assert_equal(scene._calculate_attack_damage(enemy, 100, brann, "Shield"), 100, "#60: mech Defense does not reduce Shield damage")
	var base_dodge: int = int(brann["dodge"])
	brann["grid"] = Vector2i(4, 3)
	enemy["grid"] = Vector2i(5, 3)
	var base_preview: Dictionary = scene._attack_preview(enemy, brann)
	brann["dodge"] = base_dodge + 5
	var evasive_preview: Dictionary = scene._attack_preview(enemy, brann)
	_assert_equal(evasive_preview["hit_percent"], base_preview["hit_percent"] - 5, "#60: Dodge rating changes incoming hit chance relative to neutral 10")
	brann["dodge"] = base_dodge
	scene._damage_part(brann, "Left Arm", 999)
	_assert_equal(scene._effective_defense(brann), 23, "#60: destroyed Orb host removes Defense bonus")
	_assert_equal(scene._effective_dodge(brann), 2, "#60: destroyed Orb host removes Dodge bonus")
	scene._damage_part(brann, "Legs", 999)
	_assert_equal(scene._effective_dodge(brann), 0, "#60: destroyed Legs force effective Dodge to zero")
	var breakdown: Dictionary = scene.mech_build_model.build_combat_breakdown(
		builds["brann"], scene.WEAPON_DATA, scene.ORB_DATA, scene.PILOT_DATA, scene.PART_NAMES, scene.UNIT_INITIATIVE_DATA
	)
	_assert_equal(breakdown["effective_stats"]["speed"], 1, "#60: Bulwark final Speed is clamped for its pilot baseline")
	_assert_equal(breakdown["effective_stats"]["defense"], 28, "#60: Hangar effective Defense includes Orb")
	_assert_equal(breakdown["effective_stats"]["dodge"], 7, "#60: Hangar effective Dodge includes Orb")


func _test_phase2_playable_flow() -> void:
	var path := "res://scenes/preparation_flow.tscn"
	_assert_true(ResourceLoader.exists(path), "#43: playable preparation entry scene exists")
	if not ResourceLoader.exists(path):
		return
	var flow = load(path).instantiate()
	root.add_child(flow)
	await process_frame
	var editor = flow.editor
	var arlen_breakdown: Dictionary = flow.hangar.build_model.build_combat_breakdown(
		flow.hangar.builds["arlen"], flow.hangar.GameDataScript.WEAPON_DATA, flow.hangar.GameDataScript.ORB_DATA, flow.hangar.GameDataScript.PILOT_DATA, flow.hangar.GameDataScript.PART_NAMES
	)
	_assert_equal(arlen_breakdown["orb_bonuses"]["damage_percent"], 10, "#58: effective breakdown includes Orb damage")
	_assert_equal(arlen_breakdown["effective_stats"]["attack_hit_percent"], 81, "#58: effective hit combines weapon and parts")
	_assert_true(str(arlen_breakdown["pilot_effect"]).contains("damaged enemy parts"), "#58: conditional pilot effect remains visible")
	var brann_breakdown: Dictionary = flow.hangar.build_model.build_combat_breakdown(
		flow.hangar.builds["brann"], flow.hangar.GameDataScript.WEAPON_DATA, flow.hangar.GameDataScript.ORB_DATA, flow.hangar.GameDataScript.PILOT_DATA, flow.hangar.GameDataScript.PART_NAMES
	)
	_assert_equal(brann_breakdown["effective_stats"]["shield_hp"], 40, "#58: Shield HP includes pilot bonus")
	_assert_true(editor.weapon_details.text.contains("Range 1-2"), "#58: weapon range is explained")
	_assert_true(editor.weapon_details.text.contains("Both arms"), "#58: required arms are explained")
	_assert_true(editor.weapon_select.get_item_text(0).contains("R1-1"), "#58: weapon menu compares range before selection")
	editor.mech_view.part_selected.emit("Right Arm")
	_assert_true(editor.orb_details.text.contains("Damage +10%"), "#58: Orb effect is explained")
	_assert_true(editor.orb_select.get_item_text(1).contains("Damage +10%"), "#58: Orb menu compares effects before selection")
	_assert_true(editor.stat_breakdown.text.contains("PART FRAME"), "#58: part bonuses are labeled")
	_assert_true(editor.stat_breakdown.text.contains("EFFECTIVE LOADOUT"), "#58: effective values are labeled")
	var equipment_state: Dictionary = editor.mech_view.equipment_visual_state()
	_assert_equal(equipment_state["weapon"], "Spear", "#58: illustrated weapon follows build")
	_assert_true(equipment_state["weapon_visible"], "#58: equipped weapon is illustrated")
	_assert_true(editor.has_method("preview_part"), "#58: visual part preview exists")
	if editor.has_method("preview_part"):
		var original: Dictionary = flow.hangar.builds.duplicate(true)
		editor.mech_view.buttons["Body"].pressed.emit()
		_assert_equal(flow.hangar.highlighted_part_name, "Body", "#58: mech body selection opens body choices")
		editor.preview_part("bulwark_body")
		_assert_equal(flow.hangar.builds, original, "#58: preview does not equip")
		_assert_true(editor.deploy_button.disabled, "#58: resolve preview before deploying")
		_assert_true(editor.comparison.text.contains("110"), "#58: comparison includes old HP")
		_assert_true(editor.comparison.text.contains("138"), "#58: comparison includes new HP")
		editor.cancel_button.pressed.emit()
		_assert_equal(flow.hangar.builds, original, "#58: Cancel preserves equipped build")
		_assert_false(editor.deploy_button.disabled, "#58: Cancel restores deployment")
		editor.preview_part("bulwark_body")
		editor.equip_button.pressed.emit()
		_assert_equal(flow.hangar.builds["arlen"]["parts"]["Body"], "bulwark_body", "#58: Equip commits candidate")
		_assert_equal(editor.mech_view.display_build["parts"]["Body"], "bulwark_body", "#58: illustration reflects equipped part")
		for orb_slot in ["Head", "Body", "Right Arm", "Left Arm", "Legs"]:
			var marker: Vector2 = editor.mech_view.orb_marker_position(orb_slot)
			var part_rect: Rect2 = editor.mech_view.buttons[orb_slot].get_rect().grow(-12.0)
			_assert_true(part_rect.has_point(marker), "#58: %s Orb marker stays inside its part" % orb_slot)
		editor.mech_view.part_selected.emit("Head")
	editor.unit_select.item_selected.emit(1)
	_assert_equal(flow.hangar.current_unit_id, "mira", "#43: actual selector changes unit")
	editor.weapon_select.item_selected.emit(1)
	_assert_equal(flow.hangar.builds["mira"]["weapon"], "Rifle", "#43: actual weapon control changes build")
	editor.shield_toggle.toggled.emit(true)
	_assert_equal(flow.hangar.builds["mira"]["off_hand"], "Shield", "#43: actual off-hand control changes build")
	equipment_state = editor.mech_view.equipment_visual_state()
	_assert_true(equipment_state["shield_visible"], "#58: equipped Shield is illustrated")
	var chosen_part: String = flow.hangar.available_part_options("Head")[1]["id"]
	editor.preview_part(chosen_part)
	editor.equip_button.pressed.emit()
	editor.orb_select.item_selected.emit(1)
	_assert_equal(flow.hangar.builds["mira"]["parts"]["Head"], chosen_part, "#43: part control applies selection")
	_assert_true(flow.hangar.builds["mira"]["orbs"].has("Head"), "#43: Orb control installs selected Orb")
	var chosen: Dictionary = flow.hangar.builds.duplicate(true)
	editor.deploy_button.pressed.emit()
	_assert_true(flow.battle == null, "#58: Deploy opens review before battle")
	_assert_true(editor.review_overlay.visible, "#58: squad review is visible")
	_assert_true(editor.review_text.text.contains("Arlen") and editor.review_text.text.contains("Mira") and editor.review_text.text.contains("Sera") and editor.review_text.text.contains("Brann"), "#58: review shows all four mechs")
	_assert_true(editor.review_text.text.contains("Ancient Ruins"), "#58: review shows selected mission")
	editor.close_review_button.pressed.emit()
	_assert_false(editor.review_overlay.visible, "#58: review can return to editing without deploying")
	editor.deploy_button.pressed.emit()
	var quarry_index: int = editor.mission_ids.find("crystal_quarry")
	editor.mission_select.item_selected.emit(quarry_index)
	_assert_true(editor.review_text.text.contains("Crystal Quarry"), "#58: selected mission updates squad review")
	editor.confirm_deploy_button.pressed.emit()
	_assert_true(flow.battle != null, "#43: Deploy opens a battle")
	_assert_equal(flow.battle.current_mission, "crystal_quarry", "#58: reviewed mission is deployed")
	_assert_equal(flow.battle._unit_by_id("mira")["weapon"], "Rifle", "#43: actual deploy transfers equipment")
	flow.battle.run_auto_battle(150, 42)
	flow._process(0.0)
	_assert_true(flow.return_button.visible, "#43: completed battle offers return")
	flow.return_button.pressed.emit()
	_assert_equal(flow.hangar.builds, chosen, "#43: return preserves prepared squad")
	_assert_true(flow.editor.visible, "#43: result returns to editable Hangar")
	editor.weapon_select.item_selected.emit(3)
	_assert_equal(flow.hangar.builds["mira"]["off_hand"], "", "#43: 2H selection clears Shield")
	_assert_true(editor.shield_toggle.disabled, "#43: 2H disables Shield control")
	editor.orb_select.item_selected.emit(0)
	_assert_false(flow.hangar.builds["mira"]["orbs"].has("Head"), "#43: Empty removes Orb")
	editor.mech_view.part_selected.emit("Legs")
	_assert_equal(flow.hangar.highlighted_part_name, "Legs", "#43: all part slots are selectable")
	flow.free()


func _test_phase2_build_validation_methods_exist(scene: Control) -> void:
	_assert_true(scene.has_method("run_phase2_build_validation_suite"), "#43: scene has run_phase2_build_validation_suite")
	_assert_true(scene.has_method("generate_phase2_validation_report_markdown"), "#43: scene has generate_phase2_validation_report_markdown")


func _test_phase2_mira_build_comparison(scene: Control) -> void:
	var before_units: Array = scene.units.duplicate(true)
	var results: Dictionary = scene.run_phase2_build_validation_suite([42, 101])
	_assert_equal(scene.units, before_units, "#43: validation preserves the caller's battle")
	_assert_true(results.has("scenarios"), "#43: results contains scenarios")
	var scenarios: Dictionary = results.get("scenarios", {})
	_assert_true(scenarios.has("mira_precision_fragile"), "#43: results contains mira_precision_fragile")
	_assert_true(scenarios.has("mira_durable_shield"), "#43: results contains mira_durable_shield")
	var report_md: String = scene.generate_phase2_validation_report_markdown(results)
	_assert_true(report_md.contains("Phase 2 Build-Fun Validation Report"), "#43: markdown report has correct header")
	_assert_true(report_md.contains("mira_precision_fragile"), "#43: markdown report covers Build A")
	_assert_true(report_md.contains("mira_durable_shield"), "#43: markdown report covers Build B")
	_assert_false(report_md.contains("implemented and verified green"), "#43: generator cannot grant sign-off")
	_assert_true(report_md.contains("Human playtest: pending"), "#43: report labels missing human evidence")
	for scenario in scenarios.values():
		_assert_true(float(scenario.get("avg_mira_dmg_dealt", 0)) > 0, "#43: real attack damage is measured")
		_assert_true(scenario.has("builds"), "#43: exact squad configuration is retained")
		for run in scenario["runs"]:
			_assert_true(run.has("mira_damage_taken"), "#43: per-seed evidence is retained")
	var helper_path := "res://src/testing/phase2_build_validation.gd"
	if ResourceLoader.exists(helper_path):
		var helper = load(helper_path).new()
		var metrics: Dictionary = helper.unit_metrics([
			"mira:attack", "enemy:damage:Shield:7", "enemy:damage:Body:13", "mira:hit:enemy",
			"enemy:damage:Body:3", "enemy:status:Burn:3",
			"enemy:attack", "mira:damage:Body:9", "enemy:hit:mira",
			"mira:damage:Body:3", "mira:status:Burn:3", "mira:shield_intercept:arlen"
		], "mira")
		_assert_equal(metrics["mira_damage_dealt"], 20, "#43: direct damage includes Shield but excludes later Burn")
		_assert_equal(metrics["mira_damage_taken"], 12, "#43: Burn damage counted once")
		_assert_equal(metrics["mira_shield_intercepts"], 1, "#43: intercepts belong to Mira")


func _assert_true(actual: bool, message: String) -> void:





	if not actual:
		_failures.append("Expected true: %s" % message)


func _assert_false(actual: bool, message: String) -> void:
	if actual:
		_failures.append("Expected false: %s" % message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s but got %s" % [message, expected, actual])

