@echo off
setlocal
if not defined GODOT_BIN (
  for /f "delims=" %%G in ('where godot 2^>nul') do set "GODOT_BIN=%%G"
)
if not defined GODOT_BIN (
  for /r "%TEMP%\codex-godot-portable" %%G in (*console.exe) do set "GODOT_BIN=%%G"
)
if not defined GODOT_BIN (
  echo Set GODOT_BIN to your Godot 4 executable, or open scenes/fantasy_builder.tscn and press F6 in Godot.
  exit /b 1
)
"%GODOT_BIN%" --headless --path "%~dp0" --editor --import --quit
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --path "%~dp0" res://scenes/fantasy_builder.tscn
