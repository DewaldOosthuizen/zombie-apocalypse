# Contributing to Zombie Apocalypse

Thank you for contributing. This guide covers the full workflow for making
clean, reviewable contributions to this repository.

---

## Table of Contents

1. [Code of Conduct](#1-code-of-conduct)
2. [Getting Started](#2-getting-started)
3. [Picking Up an Issue](#3-picking-up-an-issue)
4. [Branch Naming](#4-branch-naming)
5. [Development Setup](#5-development-setup)
6. [Running Checks Locally](#6-running-checks-locally)
7. [Commit Message Style](#7-commit-message-style)
8. [Pull Request Process](#8-pull-request-process)
9. [Coding Standards](#9-coding-standards)

---

## 1. Code of Conduct

Be respectful, constructive, and collaborative. Contributions that are
disrespectful, dismissive, or harmful will not be accepted.

---

## 2. Getting Started

1. Fork the repository.
2. Clone your fork locally.
3. Follow the [Development Setup](#5-development-setup) section below.

---

## 3. Picking Up an Issue

**Before you write a single line of code:**

1. Browse the [GitHub Issues](../../issues) tab and find an issue you want to work on.
2. **Assign the issue to yourself** before starting any work.
   Go to the issue page → Assignees (right sidebar) → assign yourself.
   This signals to all other contributors that the issue is claimed.
3. Leave a comment on the issue stating you are picking it up and your
   intended approach — especially for larger changes.
4. Only then create your branch and begin work.

> Why this matters: two contributors working on the same issue in parallel
> wastes effort and creates painful merge conflicts. A self-assignment takes
> five seconds and saves hours.

If you were assigned an issue but can no longer work on it, unassign yourself
and leave a comment so someone else can pick it up.

---

## 4. Branch Naming

| Prefix     | Pattern                         | When to use                                |
|------------|---------------------------------|--------------------------------------------|
| `feature/` | `feature/<issue-id>-<topic>`    | New character, mechanic, or scene          |
| `fix/`     | `fix/<issue-id>-<topic>`        | Bug fix                                    |
| `chore/`   | `chore/<topic>`                 | Tooling, CI, scripts, config updates       |
| `docs/`    | `docs/<topic>`                  | Documentation only                         |

Examples:
- `feature/42-add-dino-stomp-attack`
- `fix/17-fix-ninja-animation-glitch`
- `docs/update-contributing-guide`

Always branch from `main`.

---

## 5. Development Setup

Requires **Godot 4.x** and **Python 3.x** with `gdtoolkit`.

Install the GDScript linter:

```bash
pip install gdtoolkit
```

Download Godot (if not on PATH):

```bash
bash scripts/download_gut.sh
```

This places the binary at `./bin/godot`.

Open the project in Godot:

```bash
godot project.godot
```

---

## 6. Running Checks Locally

Use `scripts/verify.sh` as the single entry point — it mirrors the full CI pipeline.

```bash
bash scripts/verify.sh
```

This runs in sequence:
1. **gdlint** — GDScript style and syntax checks.
2. **Absolute-path guard** — ensures no hard-coded home-directory paths exist in source files.
3. **GUT headless tests** — full unit-test suite via Godot headless mode.

To run only lint and path checks (skip the Godot test run):

```bash
SKIP_TESTS=1 bash scripts/verify.sh
```

All checks must pass before opening a PR.

---

## 7. Commit Message Style

- Use the **imperative mood** in the subject line: "Add", "Fix", "Remove".
- Limit the subject line to **72 characters**.
- Leave one blank line between the subject and body when a body is needed.
- Reference the related issue in the footer with `Closes #<n>`.

Example:

```
Add stomp mechanic for Dino character

Closes #42
```

---

## 8. Pull Request Process

1. Ensure all local checks pass (see [Section 6](#6-running-checks-locally)).
2. Open the PR against `main`.
3. Use a scoped, descriptive title: `fix: resolve #17 - ninja slide animation out of sync`.
4. In the PR body:
   - Link the issue: `Closes #<n>`
   - Describe the player-visible change.
   - Include screenshots or GIFs for visual changes.
5. Request a review. Do not merge your own PR without a review.
6. Address review feedback with follow-up commits — do not force-push a reviewed branch unless asked.

---

## 9. Coding Standards

### GDScript

- Follow standard Godot 4 GDScript conventions and `gdlint` rules.
- Use `snake_case` for variables and functions; `PascalCase` for class names.
- Keep each script focused on a single behaviour — do not create monolithic node scripts.
- Use generic behaviour scripts (shared across characters) wherever possible — see ADD-002.

### Characters

The game has a fixed six-character roster:
- Female Ninja, Male Ninja
- Male Robot
- Female Ranger, Male Ranger
- Dino

Character-specific rules:
- **Dino**: stomp mechanic, double-jump, no gender prefix in animations,
  no shoot/melee/slide actions.
- Animation names must match the established naming convention for each character.
  Do not introduce new action types without an ADD covering the decision.

### Testing

- Write GUT tests for all new mechanics and behaviours.
- Do not use hard-coded absolute paths anywhere in source or test files.
- Run `bash scripts/verify.sh` before every push.
