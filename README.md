# RimWorld Archival Tool

the readme is written by claude, the script is not. known bugs: all preview.png files also get the dds processing, causing some in game issues (non game breaking). I'll fix that once I visit this script again.
dont expect updates often because this is a finished script, all that will be done are fixing bugs.

claude section starting from here onwards:

A Linux bash script that archives your entire RimWorld setup — game files, local mods, configs, and RimSort data — into a single compressed package. Also includes a standalone texture optimizer that converts mod textures to DDS format for reduced VRAM usage.

---

## What it does

**Archive mode** packages the following into a single `RimworldArchived.tar.zstd` file:
- The RimWorld game directory (excluding the Mods folder)
- Your local mods (`steamapps/common/RimWorld/Mods`)
- RimWorld's config/save data (`~/.config/unity3d/Ludeon Studios/...`)
- RimSort's config folder (`~/.local/share/RimSort`)

Each component is archived and then immediately verified with a diff pass before moving on, so you'll know right away if something went wrong.

**Texture optimizer** (also available standalone) recursively scans a mod directory and:
1. Converts any `jpeg`, `jpg`, `bmp`, `tiff`, `tif`, `tga`, or `webp` textures to PNG
2. Runs `todds` to compress everything to BC7 DDS format

This is useful for reducing VRAM usage in heavily modded playthroughs.

---

## Dependencies

Make sure these are installed and available on your `PATH` before running:

| Tool | Purpose |
|------|---------|
| `todds` | DDS texture compression |
| `rsync` | Copying game files |
| `tar` | Archiving |
| `zstd` | Compression |
| `magick` (ImageMagick 7.0+) | Texture format conversion |
| bash 4.0+ | `globstar` support |

The script will check for all of these at startup and exit early if anything is missing.

---

## Usage

```bash
chmod +x rimworld-archival-tool.sh
./rimworld-archival-tool.sh
```

The script is interactive — it will walk you through each step with prompts.

**Steam path:** The script attempts to auto-detect your `steamapps` directory from common locations (including Flatpak and Snap installs). If it guesses wrong, you'll be asked to enter the correct path manually.

**Texture tool only:** When prompted for archive vs. texture tool, type `texture` to run just the optimizer. You can point it at your steam mods, local mods, or a custom directory.

---

## Output

All output is written to `~/Documents/RimWorldArchivalTool/`. The final archive is:

```
~/Documents/RimWorldArchivalTool/RimworldArchived.tar.zstd
```

This is a zstd-compressed tar containing four inner `.tar.zstd` archives, one for each component. There is no automated restore — you'll need to extract them manually back to their original locations.

---

## Notes & Warnings

- **This script is CPU-intensive.** DDS compression especially — don't expect to game or do heavy tasks while it's running.
- You will be given the option to **delete your local mods folder** after archiving. This is irreversible — be sure the archive completed successfully before agreeing.
- It's recommended to use [RimSort's](https://github.com/RimSort/RimSort) *"Convert Steam mod to local"* feature to move your mods into the local mods folder before running this script.
- Do **not** use RimWorld, RimSort, or Steam while the script is running.

---

## License

Do whatever you want with it.
