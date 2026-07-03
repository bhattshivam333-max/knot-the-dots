# Dot Knot — Line & Color Puzzle

A mobile puzzle game built with Godot 4.6, inspired by *Dot Knot / Flow*-style
connect-the-dots puzzles.

**Goal:** connect every pair of same-colored dots with a line. Lines may never
cross — drawing over another line cuts it. The level is solved when **all pairs
are connected and every cell of the board is filled**.

## Features

- **240 levels** in 6 packs: Beginner 5×5, Classic 6×6, Advanced 7×7,
  Expert 8×8, Master 9×9, and **Bridges 7×7** (lines can cross at bridge
  cells — one horizontally, one vertically).
- **Daily puzzle** — a new date-seeded puzzle every day (Sundays have bridges).
- **Procedural generator** — every level is guaranteed solvable by
  construction and is identical for everyone (deterministic seeds).
- **Hints** (auto-draws one flow, caps the score at 1 star), move counting,
  1–3 star scoring, pipe-fill %, per-level progress saved on device.
- Pack unlocking (solve 5 levels of a pack to open the next), level unlocking.
- Touch-first UI, portrait, glowing line rendering, synthesized sound effects,
  optional **letter labels on dots** for color-blind players.
- Android back-button navigation.

## Run it

Open the folder in Godot 4.6+ (Project Manager → Import), or:

```sh
~/Downloads/Godot.app/Contents/MacOS/Godot --path ~/dot-knot
```

Mouse input is emulated as touch, so it is fully playable on desktop.

## Tests

```sh
# Validate all 240 levels + 30 daily puzzles (full coverage, no crossings):
Godot --headless --path . -s res://tests/test_gen.gd

# End-to-end gameplay simulation (drawing, cutting, hints, bridges, win):
Godot --headless --path . res://tests/test_play.tscn

# Regenerate the screenshots:
Godot --path . res://tests/screenshot.tscn -- outdir=/tmp
```

## Export to a phone

1. Editor → **Editor Settings → Export → Android**: set the paths to your
   Android SDK and a debug keystore (Godot docs: "Exporting for Android").
2. **Project → Export…** — an Android preset is already included
   (`export_presets.cfg`). Install export templates when prompted
   (Editor → Manage Export Templates).
3. Press **Export Project** (or "Deploy with remote debug" to run directly
   on a USB-connected phone).

For iOS use Project → Export → iOS (requires a Mac with Xcode and an Apple
Developer account).

## Project layout

| Path | What |
| --- | --- |
| `scripts/level_generator.gd` | Procedural puzzle generator (random snake partition of the grid; bridge tunnelling) |
| `scripts/board.gd` | Board rendering + touch input + all game rules |
| `scripts/levels.gd` | Pack definitions, palette, daily-puzzle seeding |
| `scripts/game_screen.gd` | HUD, hint button, win overlay |
| `scripts/menu_screen.gd`, `select_screen.gd` | Title + level select |
| `scripts/progress.gd` | Autoload: save file (`user://progress.cfg`) |
| `scripts/sfx.gd` | Autoload: pooled sound player |
| `assets/sfx/` | Synthesized WAVs |
| `tests/` | Generator validation + gameplay simulation |

## Tuning difficulty

In `scripts/levels.gd` edit `PACKS` (grid size, level count, seed). Changing a
seed regenerates that whole pack. In `level_generator.gd`, `MIN_LEN`, the
path-count bounds in `_attempt()`, and the `0.3` bridge probability control
how twisty and bridge-heavy levels are.
