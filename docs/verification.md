# Local Verification

`scripts/verify.sh` is the single entry point for replicating the full CI
pipeline locally. It runs gdlint, the absolute-path guard, and the GUT test
suite in sequence — the GUT step is required locally even though it is
commented out of `pr_gate.yml` in CI (see below).

## Prerequisites

- Python 3.x with gdtoolkit: `pip install gdtoolkit`
- Godot 4.x on your PATH, **or** let `scripts/download_gut.sh` auto-download
  it (the script places the binary at `./bin/godot`).

## Usage

Run the full CI-equivalent pipeline:

```bash
bash scripts/verify.sh
```

To run only the lint and path checks (skip the Godot test run):

```bash
SKIP_TESTS=1 bash scripts/verify.sh
```

## What each step does

1. **gdlint** (`scripts/` and `tests/`) — checks GDScript style and syntax,
   mirroring the `gdlint` job in `.github/workflows/pr_gate.yml`.
2. **Absolute-path guard** — scans source files for hard-coded home-directory
   paths, mirroring the `path-guard` job in `.github/workflows/pr_gate.yml`.
3. **GUT headless tests** (via `scripts/run_gut_tests.sh`) — runs the full
   unit-test suite headlessly. This step is **not** run in CI (commented
   out of `pr_gate.yml`/`release.yml` — it runs too long); running it here
   locally before every PR is the required substitute.
