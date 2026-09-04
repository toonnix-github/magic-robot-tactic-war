import re
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MAIN_SCRIPT = ROOT / "src" / "main.gd"


class BattleMilestoneStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = MAIN_SCRIPT.read_text(encoding="utf-8")

    def test_grid_and_movement_constants_match_phase_1(self):
        self.assertRegex(self.source, r"const\s+GRID_COLUMNS\s*:=\s*10\b")
        self.assertRegex(self.source, r"const\s+GRID_ROWS\s*:=\s*7\b")
        self.assertRegex(self.source, r"const\s+MOVE_RANGE\s*:=\s*3\b")

    def test_primary_actions_are_limited_to_phase_1_set(self):
        match = re.search(r"const\s+PRIMARY_ACTIONS\s*:=\s*\[(?P<body>[^\]]+)\]", self.source)
        self.assertIsNotNone(match, "PRIMARY_ACTIONS constant is missing")
        actions = re.findall(r'"([^"]+)"', match.group("body"))
        self.assertEqual(actions, ["Move", "Attack", "Wait"])

    def test_four_phase_1_player_units_are_present(self):
        for pilot in ["Arlen", "Mira", "Sera", "Brann"]:
            self.assertIn(f'"name": "{pilot}"', self.source)
        self.assertEqual(len(re.findall(r'"team": "player"', self.source)), 4)

    def test_selection_and_reachable_movement_are_implemented(self):
        required_hooks = [
            "func _select_unit",
            "func _calculate_reachable_tiles",
            "func _handle_grid_tap",
            "func _occupied_by_opponent",
            "func _occupied_by_any_unit",
        ]
        for hook in required_hooks:
            self.assertIn(hook, self.source)

    def test_movement_rules_are_encoded(self):
        self.assertIn("allies may be traversed", self.source)
        self.assertIn('_occupied_by_opponent(next_grid, str(unit["team"]))', self.source)
        self.assertIn("not _occupied_by_any_unit(grid)", self.source)

    def test_turn_flow_state_machine_is_encoded(self):
        for state in [
            "TURN_START",
            "AWAITING_COMMAND",
            "SELECTING_MOVE",
            "MOVE_COMPLETE",
            "SELECTING_ATTACK",
            "ACTION_COMPLETE",
            "TURN_END",
        ]:
            self.assertIn(state, self.source)
        for hook in [
            "func _initialize_initiative",
            "func _begin_next_activation",
            "func _begin_activation",
            "func _can_move",
            "func _can_attack",
            "func _try_move_active_unit",
            "func _try_attack_active_unit",
            "func _try_wait_active_unit",
        ]:
            self.assertIn(hook, self.source)

    def test_attack_pipeline_hooks_are_encoded(self):
        for hook in [
            "func _calculate_targetable_tiles",
            "func _attack_preview",
            "func _confirm_attack_target",
            "func _cancel_attack_selection",
            "func _resolve_attack",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("PLACEHOLDER_HIT_PERCENT", self.source)
        self.assertIn("PLACEHOLDER_WEAPON_RANGES", self.source)

    def test_part_hp_hooks_are_encoded(self):
        for hook in [
            "func _damage_part",
            "func _apply_part_consequence",
            "func _part_hp_ratio",
            "func _overall_hp_ratio",
            "func _is_unit_in_battle",
        ]:
            self.assertIn(hook, self.source)
        for constant in [
            "PART_MAX_HP",
            "PLACEHOLDER_ATTACK_DAMAGE",
            "HEAD_DESTROYED_HIT_PENALTY",
        ]:
            self.assertIn(constant, self.source)

    def test_sword_weapon_hooks_are_encoded(self):
        for hook in [
            "func _weapon_data_for",
            "func _roll_part_for_weapon",
            "func _roll_hit",
            "func _resolve_weapon_attack",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn('"Sword"', self.source)

    def test_spear_weapon_hooks_are_encoded(self):
        for hook in [
            "func _spear_direction",
            "func _line_attack_targets",
            "func _resolve_spear_attack",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn('"secondary_damage"', self.source)

    def test_rifle_weapon_hooks_are_encoded(self):
        for hook in [
            "func _resolve_rifle_attack",
            "func _volley_part_seed",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn('"shot_count"', self.source)

    def test_sniper_weapon_defaults_are_encoded(self):
        self.assertIn('"Sniper"', self.source)
        self.assertIn('"range_min": 2', self.source)
        self.assertIn('"damage": 35', self.source)
        self.assertIn('"Body": 10', self.source)

    def test_shield_interception_hooks_are_encoded(self):
        for hook in [
            "func _shield_is_active",
            "func _can_shield_intercept",
            "func _intercepting_shield_for",
            "func _damage_shield",
            "func _resolve_blockable_shot",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn('"shield_hit_weight"', self.source)

    def test_terrain_los_and_cover_hooks_are_encoded(self):
        for hook in [
            "func _create_terrain",
            "func _set_tile_terrain",
            "func _terrain_at",
            "func _height_hit_modifier",
            "func _has_cover",
            "func _terrain_adjusted_damage",
            "func _can_traverse_step",
            "func _has_line_of_sight",
        ]:
            self.assertIn(hook, self.source)
        for constant in [
            "HEIGHT_HIT_PER_LEVEL",
            "HEIGHT_HIT_CAP",
            "COVER_DODGE_BONUS",
            "COVER_DAMAGE_REDUCTION_PERCENT",
        ]:
            self.assertIn(constant, self.source)

    def test_orb_framework_hooks_and_data_are_encoded(self):
        self.assertIn("const ORB_DATA", self.source)
        for hook in [
            "func _install_orb",
            "func _orb_data_for",
            "func _active_orbs",
            "func _orb_effects",
            "func _orb_adjusted_damage",
            "func _resolve_orb_proc",
            "func _apply_status",
            "func _has_status",
        ]:
            self.assertIn(hook, self.source)
        for value in [
            '"element": "Fire"',
            '"element": "Water"',
            '"element": "Lightning"',
            '"element": "Earth"',
            '"rarity": "N"',
            '"rarity": "R"',
            '"rarity": "SR"',
            '"rarity": "SSR"',
        ]:
            self.assertIn(value, self.source)

    def test_ai_and_auto_battle_hooks_are_encoded(self):
        for hook in [
            "func _resolve_ai_activation",
            "func _decide_ai_action",
            "func _score_attack_option",
            "func _score_move_tile",
            "func _opponents_of",
            "func _primary_objective_target",
            "func _next_simulation_seed",
            "func run_auto_battle",
            "func _is_battle_over",
            "func _battle_winner",
            "func _battle_summary",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("auto_battle", self.source)
        self.assertIn("simulation_seed", self.source)

    def test_ancient_ruins_mission_and_objective_are_encoded(self):
        self.assertIn("const MISSIONS_DATA", self.source)
        self.assertIn('"ancient_ruins"', self.source)
        self.assertIn('"defeat_commander"', self.source)
        self.assertIn('"Defeat Commander"', self.source)
        self.assertIn("func _load_mission", self.source)
        self.assertIn("current_mission", self.source)
        self.assertIn('"enemy_spear"', self.source)

    def test_crystal_quarry_mission_and_loot_are_encoded(self):
        self.assertIn('"crystal_quarry"', self.source)
        self.assertIn('"defeat_all"', self.source)
        self.assertIn('"Defeat All Enemies"', self.source)
        self.assertIn('"loot_table"', self.source)
        self.assertIn('"credits"', self.source)
        self.assertIn('"arcane_ore"', self.source)
        self.assertIn('"orb_fragments"', self.source)
        self.assertIn("func _roll_mission_loot", self.source)
        self.assertIn("reward_seed", self.source)
        self.assertIn('"scavenger_alpha"', self.source)

    def test_ascending_ridge_mission_and_slope_are_encoded(self):
        self.assertIn('"ascending_ridge"', self.source)
        self.assertIn("mission_swapped_sides", self.source)
        self.assertIn('"enemy_ridge_guard"', self.source)
        self.assertIn("swapped_sides", self.source)

    def test_phase1_stabilization_and_debug_tools_are_encoded(self):
        self.assertIn("func set_debug_seed", self.source)
        self.assertIn("func configure_player_loadouts", self.source)
        self.assertIn(":move:(", self.source)
        self.assertIn(":hit:", self.source)
        self.assertIn(":miss:", self.source)
        self.assertIn(":shield_intercept:", self.source)
        self.assertIn(":damage:", self.source)
        self.assertIn(":destroy:", self.source)
        self.assertIn(":orb_proc:", self.source)
        self.assertIn(":defeated", self.source)
        self.assertIn("mission_result:", self.source)

    def test_enemy_presentation_hooks_are_encoded(self):
        for hook in [
            "func _plan_ai_activation",
            "func _movement_path_to",
            "func _present_enemy_activation",
            "func _input_locked",
            "func _resolve_planned_ai_activation_fast",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("enemy_presentation_active", self.source)
        self.assertIn("enemy_presentation_log", self.source)
        self.assertIn("ENEMY_MOVE_STEP_SECONDS", self.source)

    def test_attack_presentation_hooks_are_encoded(self):
        for hook in [
            "func _resolve_attack_result",
            "func _build_attack_feedback_sequence",
            "func _attack_feedback_line",
            "func _present_attack_feedback",
            "func _present_attack_then_finish",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("attack_presentation_active", self.source)
        self.assertIn("attack_feedback_log", self.source)
        self.assertIn("attack_feedback_step_seconds", self.source)

    def test_attack_overlay_hooks_are_encoded(self):
        for hook in [
            "func _calculate_attack_overlay_tiles",
            "func _attack_overlay_for_tile",
            "func _attack_target_reason",
            "func _refresh_attack_overlay",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("attack_overlay_tiles", self.source)
    def test_movement_preview_hooks_are_encoded(self):
        for hook in [
            "func _preview_move_destination",
            "func _confirm_move",
            "func _cancel_move_preview",
            "func _clear_move_preview",
            "func _calculate_move_path",
            "func _draw_movement_preview",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("preview_move_destination", self.source)
        self.assertIn("preview_move_path", self.source)
        self.assertIn("move_confirm_rect", self.source)
        self.assertIn("move_cancel_rect", self.source)
        self.assertIn("MOVE_PREVIEW", self.source)


    def test_enemy_inspection_hooks_are_encoded(self):
        for hook in [
            "func _inspect_target",
            "func _inspect_unit",
            "func _target_inspection_data",
            "func _draw_enemy_inspection_panel",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("TARGET INSPECTION", self.source)
        self.assertIn("ENEMY INTEL", self.source)
        self.assertIn("shield_warning", self.source)

    def test_numeric_hp_hooks_are_encoded(self):
        for hook in [
            "func _part_hp_text",
            "func _shield_hp_text",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("DESTROYED", self.source)
        self.assertIn("BROKEN", self.source)

    def test_default_orb_loadouts_and_burn_status_are_encoded(self):
        for hook in [
            "func _apply_default_orb_loadouts",
            "func _apply_default_orb_loadout",
            "func _resolve_turn_start_statuses",
            "func _remove_status",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("DEFAULT_ORB_LOADOUTS", self.source)
        self.assertIn("BURN_DAMAGE", self.source)
        self.assertIn('"Burn"', self.source)

    def test_pilot_passives_are_encoded(self):
        for hook in [
            "func _pilot_data_for",
            "func _pilot_passive_for",
            "func _set_unit_pilot",
            "func _pilot_damage_modifier_percent",
            "func _pilot_hit_modifier",
            "func _pilot_orb_proc_bonus",
            "func _pilot_shield_damage_reduction",
            "func _calculate_attack_damage",
            "func _apply_default_pilot_loadouts",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("PILOT_DATA", self.source)
        for pilot in ["arlen", "mira", "sera", "brann"]:
            self.assertIn(f'"{pilot}"', self.source)
        for passive in ["part_breaker", "hawkeye", "elemental_resonance", "guardian_stance"]:
            self.assertIn(f'"{passive}"', self.source)

    def test_weapon_data_validation_is_encoded(self):
        for hook in [
            "func _validate_weapon_data",
            "func _validate_all_weapons_data",
        ]:
            self.assertIn(hook, self.source)
        spear_match = re.search(r'"Spear":\s*\{(?P<body>[^\}]+)\}', self.source)
        self.assertIsNotNone(spear_match, "Spear weapon data is present")
        self.assertNotIn('"part_weights": {"Body": 100}', spear_match.group("body"))
        sniper_match = re.search(r'"Sniper":\s*\{(?P<body>[^\}]+)\}', self.source)
        self.assertIsNotNone(sniper_match, "Sniper weapon data is present")
        self.assertIn('"Body": 10', sniper_match.group("body"))

    def test_mission_selector_and_debug_controls_are_encoded(self):
        for hook in [
            "func _select_mission",
            "func _restart_current_mission",
            "func _open_mission_selector",
            "func _close_mission_selector",
            "func _toggle_mission_selector",
            "func _set_auto_battle",
            "func _toggle_auto_battle",
            "func _set_fast_simulation",
            "func _toggle_fast_simulation",
            "func _set_simulation_seed",
            "func _cycle_debug_seed",
            "func _draw_debug_control_bar",
            "func _draw_mission_selector_overlay",
        ]:
            self.assertIn(hook, self.source)
        for mission in ["ancient_ruins", "crystal_quarry", "ascending_ridge"]:
            self.assertIn(f'"{mission}"', self.source)
        self.assertIn("purpose", self.source)
        self.assertIn("mission_selector_open", self.source)
        self.assertIn("fast_simulation", self.source)

    def test_auto_benchmark_suite_and_metrics_are_encoded(self):
        for hook in [
            "func run_auto_benchmark_suite",
            "func generate_benchmark_report_markdown",
            "func _is_player_id",
            "func _calculate_log_metrics",
        ]:
            self.assertIn(hook, self.source)
        self.assertIn("BENCHMARK_SEEDS", self.source)
        self.assertIn("SENSIBLE_LOADOUT", self.source)
        self.assertIn("MISMATCHED_LOADOUT", self.source)
        self.assertIn("player_wasted_turns", self.source)
        self.assertIn("enemy_wasted_turns", self.source)
        self.assertIn("player_damage_dealt", self.source)
        self.assertIn("player_damage_taken", self.source)

    def test_visible_auto_battle_playback_separates_auto_from_fast_sim(self):
        """#30 — auto_battle controls turn ownership, fast_simulation controls presentation bypass."""
        # Presentation bypass gates must check fast_simulation, not auto_battle
        # _present_enemy_activation bypass
        self.assertIn("if fast_simulation:", self.source)
        # _present_attack_feedback bypass
        self.assertIn("if not attack_presentation_enabled or fast_simulation:", self.source)
        # _resolve_attack presentation condition uses fast_simulation
        self.assertIn("and not fast_simulation", self.source)
        # _begin_next_activation enemy branch uses fast_simulation
        self.assertIn("if fast_simulation or not enemy_presentation_enabled:", self.source)
        # Player Auto branch: visible presentation when not fast_simulation
        self.assertIn("_present_enemy_activation.call_deferred(next_unit, player_plan)", self.source)
        # _set_auto_battle uses visible presentation when not fast_simulation
        self.assertIn("_present_enemy_activation.call_deferred(active_unit, plan)", self.source)
        # Auto toggle allowed during input lock
        self.assertIn('debug_rects.get("auto_toggle", Rect2()).has_point(press_position)', self.source)


    def test_combat_impact_and_event_feed_structures(self):
        """#31 — Verify UI structures for combat impact and event feed."""
        # Variables
        self.assertIn("var event_feed_messages", self.source)
        self.assertIn("var floating_texts", self.source)
        self.assertIn("var unit_shakes", self.source)
        
        # Functions
        self.assertIn("func _add_event_message", self.source)
        self.assertIn("func _add_floating_text", self.source)
        self.assertIn("func _start_unit_shake", self.source)
        self.assertIn("func _draw_event_feed", self.source)
        self.assertIn("func _draw_floating_texts", self.source)

    def test_phase1_architecture_modules_are_present(self):
        """#34 — Phase 1 responsibilities are split into explicit modules."""
        expected_modules = {
            "src/combat/combat_controller.gd": "class_name CombatController",
            "src/combat/grid_controller.gd": "class_name GridController",
            "src/ai/battle_ai.gd": "class_name BattleAI",
            "src/presentation/battle_presenter.gd": "class_name BattlePresenter",
            "src/ui/battle_hud.gd": "class_name BattleHud",
            "src/data/game_data.gd": "class_name GameData",
        }
        for relative_path, class_name in expected_modules.items():
            module_path = ROOT / relative_path
            self.assertTrue(module_path.exists(), f"{relative_path} is missing")
            self.assertIn(class_name, module_path.read_text(encoding="utf-8"))

    def test_main_wires_phase1_modules_instead_of_standing_alone(self):
        """#34 — main.gd remains scene orchestration/wiring for extracted systems."""
        for preload in [
            'preload("res://src/data/game_data.gd")',
            'preload("res://src/combat/grid_controller.gd")',
            'preload("res://src/combat/combat_controller.gd")',
            'preload("res://src/ai/battle_ai.gd")',
            'preload("res://src/presentation/battle_presenter.gd")',
            'preload("res://src/ui/battle_hud.gd")',
        ]:
            self.assertIn(preload, self.source)
        for controller_var in [
            "var grid_controller",
            "var combat_controller",
            "var battle_ai",
            "var battle_presenter",
            "var battle_hud",
        ]:
            self.assertIn(controller_var, self.source)
        self.assertIn("grid_controller.calculate_reachable_tiles", self.source)
        self.assertIn("battle_presenter.add_event_message", self.source)


if __name__ == "__main__":
    unittest.main()


