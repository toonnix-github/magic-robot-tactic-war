#!/usr/bin/env python3
"""Run Godot headless tests with lightweight GDScript function coverage.

This intentionally avoids modifying the working tree. It copies the project to a
temporary directory, instruments GDScript function entries with coverage prints,
runs the Godot milestone test, then reports function coverage for src/**/*.gd.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_GDSCRIPT_ROOT = Path("src")
GODOT_TEST_SCRIPT = "res://tests/godot/battle_milestone_test.gd"
COVERAGE_PREFIX = "__GDSCRIPT_COVERAGE__"
FUNCTION_RE = re.compile(r"^(?P<indent>\s*)func\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*\(")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Godot tests and enforce GDScript function coverage.")
    parser.add_argument("--fail-under", type=float, default=80.0, help="Minimum allowed coverage percentage.")
    parser.add_argument("--godot", help="Path to a Godot executable. Defaults to GODOT_BIN or PATH lookup.")
    parser.add_argument("--keep-temp", action="store_true", help="Keep the instrumented temp project for debugging.")
    return parser.parse_args()


def find_godot(explicit_path: str | None) -> str:
    candidates: list[str] = []
    if explicit_path:
        candidates.append(explicit_path)
    if os.environ.get("GODOT_BIN"):
        candidates.append(os.environ["GODOT_BIN"])

    for name in ["godot", "godot4", "godot4-headless"]:
        found = shutil.which(name)
        if found:
            candidates.append(found)

    portable_root = Path(tempfile.gettempdir()) / "codex-godot-portable"
    if portable_root.exists():
        candidates.extend(str(path) for path in portable_root.rglob("Godot*_console.exe"))
        candidates.extend(str(path) for path in portable_root.rglob("Godot*.exe"))

    for candidate in candidates:
        path = Path(candidate)
        if path.exists() or shutil.which(candidate):
            return str(path if path.exists() else candidate)

    raise FileNotFoundError(
        "Godot executable not found. Set GODOT_BIN or pass --godot with a Godot 4 executable path."
    )


def copy_project(destination: Path) -> None:
    def ignore(_directory: str, names: list[str]) -> set[str]:
        ignored = {".git", ".godot", "__pycache__", ".pytest_cache"}
        return {name for name in names if name in ignored or name.endswith(".pyc")}

    shutil.copytree(ROOT, destination, ignore=ignore, dirs_exist_ok=True)


def instrument_script(project_root: Path, relative_path: Path) -> list[str]:
    script_path = project_root / relative_path
    original_lines = script_path.read_text(encoding="utf-8").splitlines()
    instrumented_lines: list[str] = []
    functions: list[str] = []
    pending_function: tuple[str, str] | None = None

    def coverage_lines(function_name: str, indent: str) -> list[str]:
        marker = f"{COVERAGE_PREFIX}:{relative_path.as_posix()}:{function_name}"
        meta_key_source = f"{relative_path.as_posix()}_{function_name}"
        meta_key = "__gdscript_coverage_seen_" + re.sub(r"[^A-Za-z0-9_]", "_", meta_key_source)
        return [
            f'{indent}if not Engine.has_meta("{meta_key}"):',
            f'{indent}\tEngine.set_meta("{meta_key}", true)',
            f'{indent}\tprint("{marker}")',
        ]

    for line in original_lines:
        instrumented_lines.append(line)
        if pending_function is not None and line.rstrip().endswith(":"):
            function_name, indent = pending_function
            instrumented_lines.extend(coverage_lines(function_name, indent))
            pending_function = None
            continue

        match = FUNCTION_RE.match(line)
        if not match:
            continue

        function_name = match.group("name")
        functions.append(function_name)
        indent = match.group("indent") + "\t"
        if line.rstrip().endswith(":"):
            instrumented_lines.extend(coverage_lines(function_name, indent))
        else:
            pending_function = (function_name, indent)

    script_path.write_text("\n".join(instrumented_lines) + "\n", encoding="utf-8")
    return functions


def production_gdscript_files(project_root: Path) -> list[Path]:
    relative_path = project_root / SOURCE_GDSCRIPT_ROOT
    return [
        path.relative_to(project_root)
        for path in sorted(relative_path.rglob("*.gd"))
        if not path.name.endswith(".uid")
    ]


def run_godot(godot: str, project_root: Path) -> subprocess.CompletedProcess[str]:
    command = [godot, "--headless", "--path", str(project_root), "-s", GODOT_TEST_SCRIPT]
    return subprocess.run(command, text=True, capture_output=True, check=False)


def covered_functions(output: str, relative_path: Path) -> set[str]:
    prefix = f"{COVERAGE_PREFIX}:{relative_path.as_posix()}:"
    covered: set[str] = set()
    for line in output.splitlines():
        if line.startswith(prefix):
            covered.add(line.removeprefix(prefix).strip())
    return covered


def visible_output(output: str) -> str:
    return "\n".join(
        line for line in output.splitlines()
        if not line.startswith(COVERAGE_PREFIX)
    )


def tests_passed(returncode: int, output: str) -> bool:
    return returncode == 0 and "GODOT TESTS PASSED" in output and "ERROR:" not in output


def main() -> int:
    args = parse_args()
    godot = find_godot(args.godot)
    temp_root = Path(tempfile.mkdtemp(prefix="mrtw-gdscript-coverage-"))

    try:
        copy_project(temp_root)
        functions_by_script: dict[Path, list[str]] = {}
        for source_script in production_gdscript_files(temp_root):
            functions_by_script[source_script] = instrument_script(temp_root, source_script)
        result = run_godot(godot, temp_root)
        output = result.stdout + result.stderr
        filtered_output = visible_output(output)
        if filtered_output:
            print(filtered_output)

        if not tests_passed(result.returncode, output):
            print(f"Godot test command failed with exit code {result.returncode}", file=sys.stderr)
            return result.returncode or 1

        total = 0
        covered_count = 0
        missed: list[str] = []
        for source_script, functions in functions_by_script.items():
            covered = covered_functions(output, source_script)
            total += len(functions)
            covered_count += len(covered)
            missed.extend(
                f"{source_script.as_posix()}:{name}"
                for name in functions
                if name not in covered
            )
        percent = 100.0 if total == 0 else covered_count / total * 100.0

        print(f"GDScript function coverage: {covered_count}/{total} ({percent:.1f}%)")
        if missed:
            print("Missed functions: " + ", ".join(missed))

        if percent < args.fail_under:
            print(f"Coverage failure: {percent:.1f}% is below {args.fail_under:.1f}%", file=sys.stderr)
            return 1

        return 0
    finally:
        if args.keep_temp:
            print(f"Kept instrumented project at {temp_root}")
        else:
            shutil.rmtree(temp_root, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
