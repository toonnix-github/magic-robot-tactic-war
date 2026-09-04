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

    def test_coverage_instrumentation_emits_each_function_once(self):
        runner = (ROOT / "tools" / "gdscript_function_coverage.py").read_text(encoding="utf-8")
        self.assertIn("Engine.has_meta", runner)
        self.assertIn("Engine.set_meta", runner)

    def test_coverage_runner_instruments_all_src_gdscript_files(self):
        """#34 — coverage must follow code extracted out of src/main.gd."""
        runner = (ROOT / "tools" / "gdscript_function_coverage.py").read_text(encoding="utf-8")
        self.assertIn("SOURCE_GDSCRIPT_ROOT = Path(\"src\")", runner)
        self.assertIn("def production_gdscript_files(project_root: Path)", runner)
        self.assertIn("relative_path.rglob(\"*.gd\")", runner)


if __name__ == "__main__":
    unittest.main()
