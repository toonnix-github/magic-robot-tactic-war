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

    def test_aegis_standalone_shoulders_have_image_coordinates(self):
        manifest = json.loads((ROOT / 'assets/hangar/detailed/modules.json').read_text())
        aegis = manifest['aegis']
        self.assertEqual(set(aegis['Body']['image_sockets']), {'Left Arm', 'Right Arm'})
        for slot in ('Left Arm', 'Right Arm'):
            for point in (aegis[slot]['image_anchor'], aegis['Body']['image_sockets'][slot]):
                self.assertEqual(len(point), 2)
                self.assertTrue(all(0 <= coordinate <= 1 for coordinate in point))
        self.assertNotIn('image_sockets', manifest['bulwark']['Body'])

    def test_standard_part_canvases_use_proportional_sizes_and_matching_arms(self):
        standard = json.loads((ROOT / 'docs/art/mech-part-image-standard.json').read_text())
        self.assertEqual(standard['pixel_density'], 4)
        self.assertEqual(standard['parts']['Head']['canvas'], [300, 320])
        self.assertEqual(standard['parts']['Body']['canvas'], [720, 768])
        self.assertEqual(standard['parts']['Right Arm']['canvas'], [384, 1152])
        self.assertEqual(standard['parts']['Left Arm']['canvas'], [384, 1152])
        self.assertEqual(standard['parts']['Legs']['canvas'], [1200, 1500])

        aegis = json.loads((ROOT / 'assets/hangar/detailed/modules.json').read_text())['aegis']
        expected_boxes = {
            'Head': [75, 80], 'Body': [180, 192],
            'Right Arm': [96, 288], 'Left Arm': [96, 288], 'Legs': [300, 375],
        }
        for part, expected_size in expected_boxes.items():
            self.assertEqual(aegis[part]['rect'][2:], expected_size)

    def test_body_box_is_slot_owned_instead_of_family_owned(self):
        library = (ROOT / 'src/ui/hangar_art_library.gd').read_text()
        self.assertIn('STANDARD_BODY_RECT', library)
        self.assertIn('STANDARD_SOCKET_POINTS', library)
        self.assertIn('slot == "Body"', library)
