<!-- Release title:  v1.0.6 – HDMI wake-up + hotplug, 1080p120, 1440p120 (experimental) -->

**Tested:** PS5 fat (CFI-10xx), FW 13.60, LG C4 (FLAVA3): boot, TV wake-up, HDMI re-plug, 4K60 to 1080p120 switch, 1440p120

## What's new
- **Picture comes back when your TV/monitor wakes up.** Fixes black screens when the display was already on while Linux booted, after standby, or after turning the display off and on. ([ps5-linux-patches #46](https://github.com/ps5-linux/ps5-linux-patches/pull/46) by rdmrocha)
- **Switching displays works.** Plugging in a different TV/monitor or re-plugging the HDMI cable is detected, and picture and sound are set up again. ([ps5-linux-patches #43](https://github.com/ps5-linux/ps5-linux-patches/pull/43))
- **No more "no signal" when switching down from 4K**, e.g. to 1080p or **1080p120**.
- **1440p120 (experimental, off by default).** If your TV/monitor offers it: on the USB drive's small FAT32 partition, add ` hdmi.allow_1440p120=1` at the end of the line in `cmdline.txt`, boot, and pick 2560×1440 @ 120 Hz in **desktop** System Settings → Display (it reverts by itself if the screen stays black). Tested on a FLAVA3 console; on Verde consoles it's untested, please report (`dmesg | grep "HDMI IC Type"` shows which one you have).

If the picture goes wrong with this version, the wake-up fix can be switched off: add ` hdmi.rearm=0` to `cmdline.txt`.

Coming from v1.0.5 or older: this needs a reflash (it's a kernel change).

## Known issues
- First boot is slow; the screen can stay black for a while. If it stays black, reboot once.
- On first boot, adjust the display settings in Game Mode (Settings → Display): disable HDR and set your resolution.
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
| Kernel config changes | CONFIG_LSM += bpf, CONFIG_DEBUG_INFO_BTF=y, CONFIG_MT7921E=m |
| Extra kernel patches | ps5-btusb-quirks-fix, ps5-hdmi-audio-flava3, ps5-mt7921-btusb-bulk-out, ps5-mt7921-l2cap-defer-security, ps5-hdmi-hotplug-pr43, ps5-hdmi-rearm-pr46, ps5-hdmi-flava3-scrambling-off, ps5-hdmi-1440p120-experimental (patches/) |
| Image config | NetworkManager stable MAC (IW620), MediaTek BT udev + modprobe, ps5-stage-firmware boot-cycle drop-in (files/) |
| cmdline.txt | root=LABEL=bazzite-deck rw rootwait console=ttyTitania0 console=tty0 mitigations=off idle=halt preempt=full lsm=landlock,lockdown,yama,integrity,apparmor,bpf |

## Install
1. Download all `.7z.00*` files into one folder.
2. Open `ps5-bazzite-deck-v1.0.6.img.7z.001` with 7-Zip (Windows) / Keka (macOS) / `7z x` (Linux) → you get `ps5-bazzite-deck.img`.
3. Flash it to a 32 GB+ USB/SSD with Rufus (or `dd` on Linux) and boot with the loader. The default password is `ps5`.

## Files
- `ps5-bazzite-deck-v1.0.6.img.7z.001/.002/.003` – the image as a 7-Zip multi-volume archive (extract from `.001`)
- `ps5-bazzite-deck-v1.0.6.sha256` – checksums
- `VERSIONS.md` – exact upstream pins
- `local-changes.diff` – changes applied to the upstream image builder
- `*.patch` – kernel and driver patches used in this build

---
Questions, bug reports, test results: **Discord https://discord.gg/f8QARgNkf5**
