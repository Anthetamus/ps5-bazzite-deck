<!-- Release title:  v1.0.4 – Wi-Fi fixes, MediaTek support (untested), fan + HDMI audio fixes -->

**Tested:** PS5 fat (CFI-10xx) · FW 13.60 · soniciso1 loader v13.60 · LG C4 4K60 · `<what you verified>` · MediaTek consoles: **not tested**

## What's new
- `<bullet list, copy from CHANGELOG.md>`

Still included from v1.0.3: Game Mode fix (`bpf` LSM + BTF), kernel 7.3 Wi-Fi compat patch, Bluetooth `btusb` quirks-table fix.

## Known issues
- First boot is slow; the screen can stay black for a while.
- Display mode is locked at boot; the Game Mode UI renders at 1080p (games follow Steam's resolution setting).
- HEVC encode is I-frame only.
- Not booted via ostree: `dnf5 install` works, `rpm-ostree`/`ujust update` don't; a full `dnf5 upgrade` is untested.

## Versions
`<paste the table from VERSIONS.md>`

## Install
1. Download all `.7z.00*` files into one folder.
2. Open `ps5-bazzite-deck-v1.0.4.img.7z.001` with 7-Zip (Windows) / Keka (macOS) / `7z x` (Linux) → you get `ps5-bazzite-deck.img`.
3. Flash it to a 32 GB+ USB/SSD (Etcher, Rufus DD mode, or `dd`) and boot with the loader. First boot is slow; the screen can stay black for a while.

**Verify it's working** (Switch to Desktop → Konsole):
- `uname -r` → `7.3.0`
- `systemctl status cardwired` → `active (running)` = Game Mode works
- `vainfo` → H264 / HEVC / VP9 profiles = hardware video decode works
- `nmcli device` → Wi-Fi `connected`
- `bluetoothctl list` → a controller = Bluetooth works
- Slim / MediaTek only: `lsmod | grep mt7921e`, `dmesg | grep -i mt7921`

## Files
- `ps5-bazzite-deck-v1.0.4.img.7z.001/.002/.003` – the image as a 7-Zip multi-volume archive (extract from `.001`)
- `ps5-bazzite-deck-v1.0.4.sha256` – checksums
- `VERSIONS.md` – exact upstream pins
- `local-changes.diff` – changes applied to the upstream image builder
- `patches/` – kernel and driver patches used in this build

---
Questions, bug reports, test results: **Discord https://discord.gg/f8QARgNkf5**
