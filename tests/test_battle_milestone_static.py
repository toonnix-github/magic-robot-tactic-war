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


if __name__ == "__main__":
    unittest.main()
