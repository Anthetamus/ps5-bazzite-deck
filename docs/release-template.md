<!-- Release title:  v1.0.7 – black screen at boot fix, 1440p fix (FLAVA3), SSH on -->

**Tested:** `<what you verified>`

## What's new
- **Fix: black screen at boot on some TVs** (PS5 consoles with the FLAVA3 HDMI chip). Was "v1.0.6 hotfix 1".
- **Fix: 1440p picture shifted** to the right (1440p60) or down (1440p120) on FLAVA3 consoles. 1440p is now centred.
- **SSH on by default:** `ssh ps5@<your PS5's IP>`, password `ps5`. **Change it with `passwd`**, since anyone on your network can try the default.

## Known issues
- First boot is slow; the screen can stay black for a while.
- In the PS5 settings, before booting Linux: `HDMI Device Link` **off** (Settings → HDMI).
- On first boot, in Bazzite's display settings: **HDR off** and **RGB range Full**.
- 1440p120 is still opt-in: add ` hdmi.allow_1440p120=1` to the line in `cmdline.txt`.
- HEVC encode is I-frame only.

## Versions
<paste the table from VERSIONS.md>

## Install (new)
1. Download all `.7z.00*` files into one folder.
2. Open `ps5-bazzite-deck-v1.0.7.img.7z.001` with 7-Zip (Windows) / Keka (macOS) / `7z x` (Linux) → you get `ps5-bazzite-deck.img`.
3. Flash it to a 32 GB+ USB/SSD with Rufus (or `dd` on Linux) and boot with the loader. The default password is `ps5`.

## Files
- `ps5-bazzite-deck-v1.0.7.img.7z.001/.002/.003` – the image as a 7-Zip multi-volume archive (extract from `.001`)
- `ps5-bazzite-deck-v1.0.7.sha256` – checksums
- `ps5-bazzite-deck-v1.0.7-update.tar.xz` (+ `.sha256`) – in-place update from v1.0.3–v1.0.6
- `VERSIONS.md` – exact upstream pins
- `local-changes.diff` – changes applied to the upstream image builder
- `*.patch` – kernel and driver patches used in this build

---
Questions, bug reports, test results: **Discord https://discord.gg/f8QARgNkf5**
