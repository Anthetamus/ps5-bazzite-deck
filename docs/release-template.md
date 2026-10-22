<!-- Release title:  v1.0.5 – boot fix (random missing Wi-Fi / desktop), MediaTek Wi-Fi confirmed -->

**Tested:** PS5 fat (CFI-10xx) · FW 13.60 · soniciso1 loader v13.60 · LG C4 4K60 · Game Mode, Wi-Fi, Bluetooth (DualSense), VCN, 4K60 · MediaTek: Wi-Fi confirmed by a Slim tester, Bluetooth unconfirmed

## What's new
- **Fix: services randomly missing after the first reboot** (no Wi-Fi/Ethernet, Switch to Desktop dropping back to Game Mode). A boot service was ordered in a loop; systemd broke the loop by skipping a different service each boot. Affected v1.0.3 and v1.0.4 on all models. On v1.0.4? See below, no reflash needed
- MediaTek Wi-Fi (PS5 Slim) confirmed working by a tester; MediaTek Bluetooth still unconfirmed

### Already on v1.0.4? No need to reflash
v1.0.5 is v1.0.4 plus this one fix. Open a terminal (desktop → Konsole, or Ctrl+Alt+F2 if your TV keeps the picture), run this and it reboots:
```
sudo mkdir -p /etc/systemd/system/ps5-stage-firmware.service.d && printf '[Unit]\nDefaultDependencies=no\nConflicts=shutdown.target\nBefore=shutdown.target\n' | sudo tee /etc/systemd/system/ps5-stage-firmware.service.d/10-no-default-deps.conf >/dev/null && sudo systemctl daemon-reload && sudo reboot
```
After the reboot, `journalctl -b --no-pager | grep -c "ordering cycle"` should print `0`. The default password is `ps5`.

**From v1.0.4:**
- Rebuilt on current Bazzite Deck stable and rmux's latest 7.3 PS5 patches (`meower` HEAD): fan autoservo fix, boot fan target set by the kernel
- HDMI audio stability fix for FLAVA3 HDMI chips (upstream ps5-linux-patches #42, ported to 7.3)
- Wi-Fi (NXP IW620): driver rebuilt with the upstream HE capability + TX fixes; built with objtool metadata (removes the kernel warning at boot)
- Wi-Fi: NetworkManager keeps the permanent MAC during scans (fixes GUI Wi-Fi joins)
- MediaTek MT7921 (PS5 Slim / newer): Wi-Fi driver, WizGery's Bluetooth patches (btusb bulk-OUT fix ported to 7.3, L2CAP defer-security) and udev/modprobe rules. One image for all models; drivers bind by hardware ID
- Boot: dropped the ignored `video=DP-1:1920x1080@60` from `cmdline.txt`

Still included from v1.0.3: Game Mode fix (`bpf` LSM + BTF), kernel 7.3 Wi-Fi compat patch, Bluetooth `btusb` quirks-table fix.

## Known issues
- First boot is slow; the screen can stay black for a while.
- On first boot, adjust the display settings in Game Mode (Settings → Display): disable HDR and set a higher resolution.
- HEVC encode is I-frame only.
- Not booted via ostree: `dnf5 install` works, `rpm-ostree`/`ujust update` don't; a full `dnf5 upgrade` is untested.

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
| Extra kernel patches | ps5-btusb-quirks-fix, ps5-hdmi-audio-flava3, ps5-mt7921-btusb-bulk-out, ps5-mt7921-l2cap-defer-security (patches/) |
| Image config | NetworkManager stable MAC (IW620), MediaTek BT udev + modprobe, ps5-stage-firmware boot-cycle drop-in (files/) |
| cmdline.txt | root=LABEL=bazzite-deck rw rootwait console=ttyTitania0 console=tty0 mitigations=off idle=halt preempt=full lsm=landlock,lockdown,yama,integrity,apparmor,bpf |

## Install
1. Download all `.7z.00*` files into one folder.
2. Open `ps5-bazzite-deck-v1.0.5.img.7z.001` with 7-Zip (Windows) / Keka (macOS) / `7z x` (Linux) → you get `ps5-bazzite-deck.img`.
3. Flash it to a 32 GB+ USB/SSD with Rufus (or `dd` on Linux) and boot with the loader. First boot is slow; the screen can stay black for a while.

**Verify it's working** (Switch to Desktop → Konsole):
- `uname -r` → `7.3.0`
- `systemctl status cardwired` → `active (running)` = Game Mode works
- `vainfo` → H264 / HEVC / VP9 profiles = hardware video decode works
- `nmcli device` → Wi-Fi `connected`
- `bluetoothctl list` → a controller = Bluetooth works
- `journalctl -b | grep -c "ordering cycle"` → `0` = boot fix active
- Slim / MediaTek only: `lsmod | grep mt7921e`, `dmesg | grep -i mt7921`

## Files
- `ps5-bazzite-deck-v1.0.5.img.7z.001/.002/.003` – the image as a 7-Zip multi-volume archive (extract from `.001`)
- `ps5-bazzite-deck-v1.0.5.sha256` – checksums
- `VERSIONS.md` – exact upstream pins
- `local-changes.diff` – changes applied to the upstream image builder
- `*.patch` – kernel and driver patches used in this build

---
Questions, bug reports, test results: **Discord https://discord.gg/f8QARgNkf5**
