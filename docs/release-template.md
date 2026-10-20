<!-- Release title:  v1.0.2 – Linux 7.3, Game Mode, Wi-Fi + Bluetooth -->

**Tested:** PS5 fat (CFI-10xx) · FW 13.60 · soniciso1 loader v13.60 · LG C4 4K60 · Game Mode, Wi-Fi, Bluetooth

## What's new
- Linux 7.3 with rmuxnet 7.3 PS5 patches (`meower` @ 36f173f): VCN video decode/encode, Bluetooth re-enabled
- **Game Mode works**: `bpf` added to `CONFIG_LSM`, `CONFIG_DEBUG_INFO_BTF=y` (fixes `cardwired`), `lsm=…,bpf` also in `cmdline.txt`
- Wi-Fi: PS5 IW620 driver with kernel 7.2/RTNL patches + new kernel 7.3 compat patch, `ps_mode=0` (firmware is staged at boot from the loader by the builder's ps5-stage-firmware service, not shipped in the image)
- Builder: ps5-linux-image @ 52db0a4 + fixes (VCN firmware mount, Wi-Fi patch order)

## Versions
| Component | Version / commit |
|---|---|
| Bazzite Deck | `ghcr.io/ublue-os/bazzite-deck:stable` as of 2026-10-20, digest `sha256:96301a1520b5bb63db95640896300c10ae3b1fcf8bf10681af154514395e1634` |
| Linux kernel | `v7.3` (kernel.org stable) |
| PS5 kernel patches | rmuxnet/ps5-linux-patches-1 `meower` @ `36f173f` |
| Image builder | ps5-linux/ps5-linux-image @ `52db0a4` + local-changes.diff |
| IW620 Wi-Fi patches | ps5-linux/ps5-linux-mwifiex `main` @ `4bce848` + ps5-iw620-kernel73-compat.patch |
| NXP mwifiex base driver | `lf-6.18.2_1.0.0` |
| IW620 firmware | not in the image (Sony/NXP blob); provided by the loader on the boot partition and staged at boot by ps5-stage-firmware.service |
| Kernel config changes | CONFIG_LSM="landlock,lockdown,yama,integrity,apparmor,bpf" CONFIG_DEBUG_INFO_BTF=y  |
| cmdline.txt | root=LABEL=bazzite-deck rw rootwait console=ttyTitania0 console=tty0 video=DP-1:1920x1080@60 mitigations=off idle=halt preempt=full lsm=landlock,lockdown,yama,integrity,apparmor,bpf |
| Loader used | soniciso1/ps5-linux-loader v13.60 |


## Install
1. Verify: `sha256sum -c ps5-bazzite-deck-v1.0.2.img.xz.sha256`
2. Rejoin: `cat ps5-bazzite-deck-v1.0.2.img.xz.part-* > ps5-bazzite-deck-v1.0.2.img.xz`
3. `xz -d` it, flash to a 32 GB+ USB/SSD, boot with the loader.

Check on the PS5: `uname -r`, `systemctl status cardwired` (active = Game Mode works), `vainfo`, `nmcli device`.

## Known issues
- none so far

## Files
- `ps5-bazzite-deck-v1.0.2.img.xz.part-aa/ab/ac` – image (rejoin, see above)
- `ps5-bazzite-deck-v1.0.2.img.xz.sha256` – checksums of the parts and the joined file
- `VERSIONS.md` – exact upstream pins
- `local-changes.diff` – changes applied to the upstream image builder
- `ps5-iw620-kernel73-compat.patch` – Wi-Fi driver patch for kernel 7.3
