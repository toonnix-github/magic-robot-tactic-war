"""Ownership and completeness contracts for the isolated fantasy preparation flow."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FantasyBuilderStaticTests(unittest.TestCase):
    def test_catalog_is_data_driven_and_complete(self):
        data = json.loads((ROOT / 'data/fantasy/build_catalog.json').read_text())
        self.assertEqual(set(data['jobs']), {'Knight', 'Warrior', 'Ranger', 'Mage', 'Healer'})
        self.assertEqual(len(data['fairies']), 6)
        self.assertEqual(len(data['slots']), 9)
        self.assertTrue(all('abilities' in f for f in data['fairies'].values()))
        self.assertTrue(all('rarity' not in f for f in data['fairies'].values()))

    def test_model_owns_rules_and_ui_delegates(self):
        model = (ROOT / 'src/data/fantasy_build_model.gd').read_text()
        screen = (ROOT / 'src/ui/fantasy_builder.gd').read_text()
        self.assertIn('func can_equip(', model)
        self.assertIn('func equip(', model)
        self.assertIn('func stats(', model)
        self.assertIn('model.equip(', screen)
        self.assertIn('model.preview_stats(', screen)
        self.assertNotIn('mech_build_model', model)
        self.assertNotIn('res://src/main.gd', screen)

    def test_scene_is_standalone(self):
        scene = (ROOT / 'scenes/fantasy_builder.tscn').read_text()
        self.assertIn('res://src/ui/fantasy_builder.gd', scene)
        self.assertNotIn('fantasy', (ROOT / 'src/main.gd').read_text())


if __name__ == '__main__':
    unittest.main()
