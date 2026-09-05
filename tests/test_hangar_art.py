import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class HangarArtTests(unittest.TestCase):
    def test_art_is_owned_by_ui_and_has_ten_masked_modules(self):
        source = (ROOT / 'src/ui/mech_assembly_view.gd').read_text()
        self.assertIn('hangar_art_library.gd', source)
        manifest = json.loads((ROOT / 'assets/hangar/detailed/modules.json').read_text())
        self.assertEqual(set(manifest), {'aegis', 'bulwark'})
        for family, modules in manifest.items():
            self.assertEqual(set(modules), {'Head', 'Body', 'Left Arm', 'Right Arm', 'Legs'})
            for profile in modules.values():
                self.assertTrue((ROOT / profile['mask'].removeprefix('res://')).is_file())
                self.assertEqual(len(profile['region']), 4)
                self.assertEqual(len(profile['rect']), 4)
            self.assertEqual(set(modules['Body']['sockets']), {'Head', 'Left Arm', 'Right Arm', 'Legs'})
            for slot in ('Head', 'Left Arm', 'Right Arm', 'Legs'):
                self.assertEqual(len(modules[slot]['anchor']), 2)
        library = (ROOT / 'src/ui/hangar_art_library.gd').read_text()
        self.assertNotIn('MechBuildModel', library)
        self.assertNotIn('hangar_art', (ROOT / 'src/main.gd').read_text())

    def test_background_is_part_of_native_editor(self):
        source = (ROOT / 'src/ui/hangar_editor.gd').read_text()
        self.assertIn('HangarBackground', source)
        self.assertTrue((ROOT / 'assets/hangar/detailed/hangar_background.png').is_file())
