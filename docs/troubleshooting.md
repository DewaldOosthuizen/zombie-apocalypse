# Troubleshooting Godot Imports and Asset Paths

If the editor reports missing `.uid` files, stale import data, or missing scene
resources:

1. Use Godot 4.6-stable, which matches this project's pinned configuration.
2. Close Godot, remove the local `.godot/` cache, and reopen the project so the
   editor can refresh its imports. The cache is ignored and should not be
   committed.
3. Check that every referenced scene and resource exists at its `res://` path.
   Renamed or moved assets must have their references updated.
4. Run the repository checks after imports finish:
   - `make lint` for GDScript style checks.
   - `make test` for the GUT headless test suite.
   - `make ci` for the full local CI-equivalent pipeline.
