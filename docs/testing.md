# Running Tests

This project uses [GUT](https://github.com/bitwes/Gut) for unit testing.

Prerequisites: Godot 4.x installed and on your PATH.

The preferred way to run GUT tests locally is via the convenience wrapper:

```bash
bash scripts/run_gut_tests.sh
```

To use a specific Godot binary, set the `GODOT` environment variable:

```bash
GODOT=/path/to/godot bash scripts/run_gut_tests.sh
```

Under the hood, the script calls:

```bash
godot --headless -s addons/gut/addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -gprefix=test_ \
  -gsuffix=.gd \
  -gexit
```

Tests can also be run from inside the Godot editor via the GUT panel
(Scene > GUT > Run All).

The `.github/workflows/pr_gate.yml` workflow runs gdlint and the absolute-path
guard automatically on every pull request. **The GUT test job is commented
out in CI** (both `pr_gate.yml` and `release.yml`) because the full headless
suite runs too long. Contributors **must** run the GUT test suite locally
(see above) and confirm it passes before raising a PR. See
[CI / Release Pipeline](ci-cd.md) for the full picture, including releases.
