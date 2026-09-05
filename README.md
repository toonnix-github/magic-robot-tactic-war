# magic-robot-tactic-war
Mobile tactical RPG combining modular mechs, magic Orbs, part-based damage, and short grid battles.

Current scope: [Phase 2 Build Your Mech](docs/phase2-scope.md). Run the Godot project to edit equipment, deploy the squad, and return after a battle. See [the progress review](docs/phase2-build-your-mech-progress-review.md) for validation evidence and remaining human review.

## Development Checks

Run the Python regression suite:

```powershell
python -m unittest discover
```

Run the Godot headless milestone test directly:

```powershell
$env:GODOT_BIN = "C:\Path\To\Godot_v4.x-stable_win64_console.exe"
& $env:GODOT_BIN --headless --path . -s res://tests/godot/battle_milestone_test.gd
```

Run the GDScript function coverage gate:

```powershell
python tools/gdscript_function_coverage.py --fail-under 80
```

Set `GODOT_BIN` or pass `--godot` if Godot is not available on `PATH`.

GitHub Actions runs these checks for pushes and pull requests targeting `prototype/combat-v01`.
