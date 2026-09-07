from pathlib import Path
import unittest
import subprocess
from unittest.mock import patch
from tools import gdscript_function_coverage as coverage


ROOT = Path(__file__).resolve().parents[1]


class CoverageToolingStaticTests(unittest.TestCase):
    def test_coverage_imports_assets_before_running_a_cold_copy(self):
        with patch.object(coverage.subprocess, 'run') as run:
            run.return_value = subprocess.CompletedProcess([], 0, '', '')
            coverage.run_godot('godot', Path('project'))
            self.assertEqual(run.call_count, 2)
            self.assertIn('--import', run.call_args_list[0].args[0])
            self.assertIn(coverage.GODOT_TEST_SCRIPT, run.call_args_list[1].args[0])

    def test_failed_asset_import_stops_coverage(self):
        with patch.object(coverage.subprocess, 'run') as run:
            run.return_value = subprocess.CompletedProcess([], 1, '', 'import failed')
            result = coverage.run_godot('godot', Path('project'))
            self.assertEqual(run.call_count, 1)
            self.assertIn('--import', run.call_args.args[0])
            self.assertEqual(result.returncode, 1)

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
