<!-- Release title:  v1.0.7 – black screen at boot fix, 1440p fix (FLAVA3), SSH on -->

**Tested:** PS5 fat (CFI-10xx), FW 13.60, LG C4 (FLAVA3): boot, 1440p60 + 1440p120 centred (ruler test), in-place update; boot fix tested on a FLAVA3 tester console

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
| Component | Version / commit |
|---|---|
| Bazzite Deck | `ghcr.io/ublue-os/bazzite-deck:stable` @ `sha256:96301a1520b5bb63db95640896300c10ae3b1fcf8bf10681af154514395e1634` |
| Linux kernel | `v7.3` (kernel.org stable) |
| PS5 kernel patches | rmuxnet/ps5-linux-patches-1 `meower` @ `c104b34` + patches/ps5-btusb-quirks-fix.patch |
| Image builder | ps5-linux/ps5-linux-image @ `52db0a4` + local-changes.diff |
| IW620 Wi-Fi patches | ps5-linux/ps5-linux-mwifiex `main` @ `4bce848` + patches/ps5-iw620-kernel73-compat.patch |
| NXP mwifiex base driver | `lf-6.18.2_1.0.0` |
| IW620 firmware | not in the image; pcieuartiw620_combo_v1.bin is staged at boot from the loader's boot partition (ps5-stage-firmware) |
| Kernel config changes | CONFIG_LSM += bpf, CONFIG_DEBUG_INFO_BTF=y, CONFIG_MT7921E=m, CONFIG_MODULE_ALLOW_BTF_MISMATCH=y |
| Extra kernel patches | ps5-btusb-quirks-fix, ps5-hdmi-audio-flava3, ps5-mt7921-btusb-bulk-out, ps5-mt7921-l2cap-defer-security, ps5-hdmi-hotplug-pr43, ps5-hdmi-rearm-pr46, ps5-hdmi-flava3-scrambling-off, ps5-hdmi-1440p120-experimental, ps5-hdmi-flava3-no-event-sequences, ps5-hdmi-flava3-1440p-timing (patches/) |
| Image config | NetworkManager stable MAC (IW620), MediaTek BT udev + modprobe, ps5-stage-firmware boot-cycle drop-in (files/), SSH enabled |
| cmdline.txt | root=LABEL=bazzite-deck rw rootwait console=ttyTitania0 console=tty0 mitigations=off idle=halt preempt=full lsm=landlock,lockdown,yama,integrity,apparmor,bpf |

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
