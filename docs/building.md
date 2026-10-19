# Building Locally

CI no longer builds or uploads Godot export binaries (the exported
Linux/X11 + Windows Desktop artifacts were large and unnecessary to ship
via GitHub Actions). To produce a local build:

1. Install Godot 4.6-stable (matching the `config/features` pin in
   `project.godot`) and the matching export templates for that version.
2. Import project assets once so the editor caches are populated:

```bash
godot --headless --editor --quit
```

3. Export the platform build(s) you need:

```bash
mkdir -p build/linux build/windows
godot --headless --export-release "Linux/X11" build/linux/zombie-apocalypse.x86_64
godot --headless --export-release "Windows Desktop" build/windows/zombie-apocalypse.exe
```

Export preset names come from `export_presets.cfg` in the repo root.
Cross-exporting to Windows from Linux requires the Windows export
templates to be installed even though you are running on Linux.
