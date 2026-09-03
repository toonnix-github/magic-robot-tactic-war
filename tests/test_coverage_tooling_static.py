from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class CoverageToolingStaticTests(unittest.TestCase):
    def test_gdscript_coverage_runner_exists(self):
        runner = ROOT / "tools" / "gdscript_function_coverage.py"
        self.assertTrue(runner.exists(), "GDScript coverage runner is missing")

    def test_godot_milestone_test_exists(self):
        godot_test = ROOT / "tests" / "godot" / "battle_milestone_test.gd"
        self.assertTrue(godot_test.exists(), "Godot headless milestone test is missing")

    def test_readme_documents_regression_and_coverage_commands(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("python -m unittest discover", readme)
        self.assertIn("python tools/gdscript_function_coverage.py --fail-under 80", readme)


if __name__ == "__main__":
    unittest.main()
