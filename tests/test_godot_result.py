import unittest
from tools.gdscript_function_coverage import tests_passed


class GodotResultTests(unittest.TestCase):
    def test_runtime_error_cannot_pass_with_success_marker(self):
        self.assertFalse(tests_passed(0, "GODOT TESTS PASSED\nSCRIPT ERROR: Invalid access"))
        self.assertFalse(tests_passed(0, ""))
        self.assertFalse(tests_passed(1, "GODOT TESTS PASSED"))
        self.assertTrue(tests_passed(0, "GODOT TESTS PASSED\n"))
