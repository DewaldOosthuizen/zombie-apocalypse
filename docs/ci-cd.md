# CI / Release Pipeline

- **`.github/workflows/pr_gate.yml`** — runs on every pull request:
  `gdlint` and `path-guard` run in parallel, then `pr-gate-summary` fans in
  both and is the required status check. **GUT tests are commented out**
  (they ran too long for the PR gate); contributors must run them locally
  before raising a PR (see [Running Tests](testing.md)).
- **`.github/workflows/release.yml`** — runs on push to `main` (and
  `workflow_dispatch`): re-validates the exact commit being released
  (`gdlint` only — GUT tests are commented out here too, same reasoning),
  then builds Linux/X11 and Windows Desktop exports via
  `barichello/godot-ci:4.6`, computes the next [CalVer](https://calver.org/)
  tag (`YYYY.MM.DD[.N]`), bumps `config/version` in `project.godot`,
  commits + tags + pushes, and publishes a GitHub Release. **Build
  artifacts are not uploaded to the workflow run or attached to the
  Release** — see [Building Locally](building.md) to produce your
  own binaries. If `HEAD` is already tagged, the release step is skipped
  (no duplicate releases on a no-op push).
- Godot version is pinned to **4.6-stable** across both workflows; bump the
  pin in both files together with `project.godot`'s `config/features` entry.
