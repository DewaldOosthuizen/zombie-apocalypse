# Changelog — Zombie Apocalypse

All notable changes to **Zombie Apocalypse** are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and release headings follow Semantic Versioning with an `Unreleased` section for
work in progress.
For the full commit history see the repository log.

## Unreleased

- Replaced Adventure Girl character with Ranger (female and male variants)
  - Female Ranger: full animation set (Dead, Idle, Jump, Melee, Run, Shoot, Slide)
  - Male Ranger: Dead, Idle, Jump, Run, Slide (Melee/Shoot fall back to female assets)
  - Renamed scene directory: `scenes/characters/adventure_girl/` -> `scenes/characters/ranger/`
  - Renamed script: `scripts/adventure_girl.gd` -> `scripts/ranger.gd`
  - Removed old `resources/characters/adventure_girl/` assets
- Fixed player never spawning: `Level_1_Scene.tscn` inline `_ready(): pass` suppressed
  `level_entered` signal; changed to `super._ready()`
- Fixed death animation looping: replaced `AnimatedSprite2D.stop()` with `pause()` to hold
  last frame on death
- Fixed blood particles: corrected scale (4.5 -> 0.5) and spawn position offset
- Fixed brick particles: corrected scale (4.5 -> 0.5)
- Fixed Tab key not switching characters: corrected keycode from 4194305 (ESC) to 4194306 (TAB)
- Fixed Robot unable to take or deal melee damage: wired `_area_checks()` into `_physics_process`
- Fixed `Array.empty()` -> `Array.is_empty()` in Ammo_Scene (Godot 4 API)
- Fixed pit falls not killing characters: added Y-threshold check (`PIT_DEATH_THRESHOLD = 900`)
- Fixed Ranger (ex Adventure Girl) walk invisible: base class resolved `"walk"` but assets use
  `"run"`; override in `ranger.gd` maps the animation name correctly
- Fixed Ranger slide never stopping: set `loop = false` on slide animations
- Added `scripts/verify.sh` for full local CI replication (gdlint + path guard + GUT tests)
- Fixed `export_presets.cfg` using the Godot 3 container name `PoolStringArray` for both export
  presets' `patch_list` (Linux/X11 and Windows Desktop); replaced with the Godot 4 spelling
  `PackedStringArray()`. Config-only change; no runtime behaviour changed.
- Fixed `tests/test_tween_script.gd` calling `_on_tween_completed()` with two Godot 3 signal
  arguments; the callback is connected to `tween.finished` and takes none. Also corrected the
  expected `movement_position` to account for the direction reversal the callback performs.

## 0.2

- Migrated project from Godot 3 to Godot 4 (see [ADD-001](docs/add/add-001-godot4-migration.md))
- Updated node types: CharacterBody2D, AnimatedSprite2D, Sprite2D
- Modernised GDScript syntax (@export, @onready, Callable)
- Updated signal connections and scene instantiation
- DisplayServer API for fullscreen handling
- Updated Tween API

## 0.1

- Initial project: Robot and Male Ninja playable characters
- Basic zombie enemy AI
- 2D side-scrolling world scene
