<!-- Release title:  v1.0.3 – Linux 7.3, Game Mode, Wi-Fi + Bluetooth -->

**Tested:** PS5 fat (CFI-10xx) · FW 13.60 · soniciso1 loader v13.60 · LG C4 4K60 · Game Mode, Wi-Fi, Bluetooth (DualSense paired), VCN, 4K60

## What's new
- **Bluetooth works**: the 7.3 PS5 patch registered the IW620 Bluetooth device (`1286:2059`) in the wrong `btusb` table, so its quirks never applied (two `hci` devices, `Opcode 0x2031 failed`). `patches/ps5-btusb-quirks-fix.patch` moves the entry to `quirks_table` and the interface-0 check after the quirks lookup. Only `btusb.ko` changed; a hotfix module for v1.0.2 is attached to the release.

## Versions
| Component | Version / commit |
|---|---|
| Bazzite Deck | `ghcr.io/ublue-os/bazzite-deck:stable` as of 2026-10-20, digest `sha256:96301a1520b5bb63db95640896300c10ae3b1fcf8bf10681af154514395e1634` |
| Linux kernel | `v7.3` (kernel.org stable) |
| PS5 kernel patches | rmuxnet/ps5-linux-patches-1 `meower` @ `36f173f` + ps5-btusb-quirks-fix.patch |
| Image builder | ps5-linux/ps5-linux-image @ `52db0a4` + local-changes.diff |
| IW620 Wi-Fi patches | ps5-linux/ps5-linux-mwifiex `main` @ `4bce848` + ps5-iw620-kernel73-compat.patch |
| NXP mwifiex base driver | `lf-6.18.2_1.0.0` |
| IW620 firmware | not in the image (Sony/NXP blob); provided by the loader on the boot partition and staged at boot by ps5-stage-firmware.service |
| Kernel config changes | CONFIG_LSM="landlock,lockdown,yama,integrity,apparmor,bpf" CONFIG_DEBUG_INFO_BTF=y  |
| cmdline.txt | root=LABEL=bazzite-deck rw rootwait console=ttyTitania0 console=tty0 video=DP-1:1920x1080@60 mitigations=off idle=halt preempt=full lsm=landlock,lockdown,yama,integrity,apparmor,bpf |
| Loader used | soniciso1/ps5-linux-loader v13.60 |


## Install
1. Download all `.7z.00*` files into one folder.
2. Open `ps5-bazzite-deck-v1.0.3.img.7z.001` with 7-Zip (Windows) / Keka (macOS) / `7z x` (Linux) → you get `ps5-bazzite-deck.img`.
3. Flash it to a 32 GB+ USB/SSD (Etcher, Rufus DD mode, or `dd`) and boot with the loader. First boot is slow; the screen can stay black for a while.

Check on the PS5: `uname -r`, `systemctl status cardwired` (active = Game Mode works), `vainfo`, `nmcli device`.

## Hotfix for v1.0.2 users
Bluetooth only needs the new driver module. Copy `btusb.ko` from this release onto the PS5 (USB stick), then:
```
sudo cp /path/to/btusb.ko /usr/lib/modules/$(uname -r)/kernel/drivers/bluetooth/btusb.ko && sudo depmod -a && sudo systemctl reboot
```

## Known issues
- none so far

## Files
- `ps5-bazzite-deck-v1.0.3.img.7z.001/.002/.003` – the image as a 7-Zip multi-volume archive (extract from `.001`)
- `ps5-bazzite-deck-v1.0.3.sha256` – checksums
- `VERSIONS.md` – exact upstream pins
- `local-changes.diff` – changes applied to the upstream image builder
- `ps5-iw620-kernel73-compat.patch` – Wi-Fi driver patch for kernel 7.3
- `ps5-btusb-quirks-fix.patch` – Bluetooth fix (kernel patch)
- `btusb.ko` – hotfix module for v1.0.2 (same kernel 7.3.0 build)
