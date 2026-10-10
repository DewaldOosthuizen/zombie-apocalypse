# Zombie Apocalypse
Zombie Apocalypse is created with Godot 4. A 2D game where the player can play with multiple characters to try and stop a zombie apocalypse 
from spreading.

[![PR Gate](https://github.com/DewaldOosthuizen/zombie_apocalypse/actions/workflows/pr_gate.yml/badge.svg)](https://github.com/DewaldOosthuizen/zombie_apocalypse/actions/workflows/pr_gate.yml)

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/DewaldOosthuizen1)

## Requirements
- Godot 4.x or later

## Documentation

Architecture Decision Documents (ADDs) capture significant design and technical decisions:

- [docs/add/README.md](docs/add/README.md) — ADD index
- [CHANGELOG.md](CHANGELOG.md) — release history and unreleased changes
- [ADD-001: Godot 4 Migration](docs/add/add-001-godot4-migration.md)
- [ADD-002: Generic Behaviour Scripts](docs/add/add-002-generic-behaviour-scripts.md)
- [ADD-003: Multi-Character World Scene Design](docs/add/add-003-multi-character-design.md)
- [ADD-004: GUT Testing Approach](docs/add/add-004-gut-testing-approach.md)
- [ADD-005: Dino Character Design](docs/add/add-005-dino-character-design.md)

## Migration to Godot 4
This project has been updated from Godot 3 to Godot 4, including:
- Updated node types (CharacterBody2D, AnimatedSprite2D, Sprite2D)
- Modernized GDScript syntax (@export, @onready, Callable)
- Updated signal connections and scene instantiation
- DisplayServer API for fullscreen handling
- Updated Tween API

## CONTROLS
  * ESC: Exit fullscreen, if not in full screen then exit game
  * R: Respawn character at level starting position


### ROBOT CONTROLS
* MOVEMENTS
  * A, LEFT ARROW        - move left
  * D, RIGHT ARROW:      - move right
  * W, SPACE, UP ARROW:  - jump 
* ATTACKS
  * CTRL:    - slide
  * Z:       - shoot
  * X:       - melee

### MALE NINJA CONTROLS
* MOVEMENTS
  * A, LEFT ARROW                                 - move left
  * D, RIGHT ARROW:                               - move right
  * W, SPACE, UP ARROW:                           - jump 
  * (W, SPACE, UP ARROW) + (W, SPACE, UP ARROW):  - GLIDE 
* ATTACKS
  * CTRL:    - slide
  * Z:       - shoot
  * X:       - melee

### RANGER CONTROLS

* MOVEMENTS
  * A, LEFT ARROW        - move left
  * D, RIGHT ARROW       - move right
  * W, SPACE, UP ARROW   - jump
* ATTACKS
  * CTRL   - slide
  * Z      - shoot (female only; male falls back to female animation)
  * X      - melee (female only; male falls back to female animation)

## Characters

| Character      | Scene file present | Animations available                          | Status     |
|----------------|--------------------|-----------------------------------------------|------------|
| Robot          | Yes                | Full set                                      | Playable   |
| Female Ninja   | Yes                | Full set                                      | Playable   |
| Male Ninja     | Yes                | Full set                                      | Playable   |
| Female Ranger  | Yes                | Dead, Idle, Jump, Melee, Run, Shoot, Slide    | Playable   |
| Male Ranger    | Yes                | Dead, Idle, Jump, Run, Slide                  | Playable (Melee/Shoot falls back to female animations) |
| Dino           | Yes                | Dead, Idle, Jump, Run, Walk, tail_swipe       | Playable (no shoot/slide; stomp + tail-swipe melee via ADD-005) |

![image](https://github.com/user-attachments/assets/d4f90d48-03f8-4e04-872e-633b077a57d1)


## Known Gaps / Roadmap

This is still a work in progress and is meant as a learning project.
There are still a lot of features outstanding, as well as some gaps after the Godot 4 migration that
affected existing functionality.

- levels are no longer cycling as they should
- Some particle scenes are no longer behaving as they should
- Pits are no longer triggering character deaths
- Needs a main menu where the game can be started from, character selection, and general settings
- More levels
- etc

## Running Tests

This project uses [GUT](https://github.com/bitwes/Gut) for unit testing.

Prerequisites: Godot 4.x installed and on your PATH.

The preferred way to run GUT tests locally is via the convenience wrapper:

	bash scripts/run_gut_tests.sh

To use a specific Godot binary, set the `GODOT` environment variable:

	GODOT=/path/to/godot bash scripts/run_gut_tests.sh

Under the hood, the script calls:

	godot --headless -s addons/gut/addons/gut/gut_cmdln.gd \
	  -gdir=res://tests \
	  -gprefix=test_ \
	  -gsuffix=.gd \
	  -gexit

Tests can also be run from inside the Godot editor via the GUT panel
(Scene > GUT > Run All).

The `.github/workflows/pr_gate.yml` workflow runs gdlint and the absolute-path
guard automatically on every pull request. **The GUT test job is commented
out in CI** (both `pr_gate.yml` and `release.yml`) because the full headless
suite runs too long. Contributors **must** run the GUT test suite locally
(see above) and confirm it passes before raising a PR. See
[CI / Release Pipeline](#ci--release-pipeline) below for the full picture,
including releases.

## Local Verification

`scripts/verify.sh` is the single entry point for replicating the full CI
pipeline locally. It runs gdlint, the absolute-path guard, and the GUT test
suite in sequence — the GUT step is required locally even though it is
commented out of `pr_gate.yml` in CI (see below).

## Building Locally

CI no longer builds or uploads Godot export binaries (the exported
Linux/X11 + Windows Desktop artifacts were large and unnecessary to ship
via GitHub Actions). To produce a local build:

1. Install Godot 4.6-stable (matching the `config/features` pin in
   `project.godot`) and the matching export templates for that version.
2. Import project assets once so the editor caches are populated:

	godot --headless --editor --quit

3. Export the platform build(s) you need:

	mkdir -p build/linux build/windows
	godot --headless --export-release "Linux/X11" build/linux/zombie-apocalypse.x86_64
	godot --headless --export-release "Windows Desktop" build/windows/zombie-apocalypse.exe

   Export preset names come from `export_presets.cfg` in the repo root.
   Cross-exporting to Windows from Linux requires the Windows export
   templates to be installed even though you are running on Linux.

## CI / Release Pipeline

- **`.github/workflows/pr_gate.yml`** — runs on every pull request:
  `gdlint` and `path-guard` run in parallel, then `pr-gate-summary` fans in
  both and is the required status check. **GUT tests are commented out**
  (they ran too long for the PR gate); contributors must run them locally
  before raising a PR (see [Running Tests](#running-tests)).
- **`.github/workflows/release.yml`** — runs on push to `main` (and
  `workflow_dispatch`): re-validates the exact commit being released
  (`gdlint` only — GUT tests are commented out here too, same reasoning),
  then builds Linux/X11 and Windows Desktop exports via
  `barichello/godot-ci:4.6`, computes the next [CalVer](https://calver.org/)
  tag (`YYYY.MM.DD[.N]`), bumps `config/version` in `project.godot`,
  commits + tags + pushes, and publishes a GitHub Release. **Build
  artifacts are not uploaded to the workflow run or attached to the
  Release** — see [Building Locally](#building-locally) to produce your
  own binaries. If `HEAD` is already tagged, the release step is skipped
  (no duplicate releases on a no-op push).
- Godot version is pinned to **4.6-stable** across both workflows; bump the
  pin in both files together with `project.godot`'s `config/features` entry.

### Prerequisites

- Python 3.x with gdtoolkit: `pip install gdtoolkit`
- Godot 4.x on your PATH, **or** let `scripts/download_gut.sh` auto-download
  it (the script places the binary at `./bin/godot`).

### Usage

Run the full CI-equivalent pipeline:

	bash scripts/verify.sh

To run only the lint and path checks (skip the Godot test run):

	SKIP_TESTS=1 bash scripts/verify.sh

### What each step does

1. **gdlint** (`scripts/` and `tests/`) — checks GDScript style and syntax,
   mirroring the `gdlint` job in `.github/workflows/pr_gate.yml`.
2. **Absolute-path guard** — scans source files for hard-coded home-directory
   paths, mirroring the `path-guard` job in `.github/workflows/pr_gate.yml`.
3. **GUT headless tests** (via `scripts/run_gut_tests.sh`) — runs the full
   unit-test suite headlessly. This step is **not** run in CI (commented
   out of `pr_gate.yml`/`release.yml` — it runs too long); running it here
   locally before every PR is the required substitute.


## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for
the full workflow, including how to pick up an issue, branch naming conventions,
local validation steps, and the pull request process.
