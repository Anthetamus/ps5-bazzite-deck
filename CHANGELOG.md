# Changelog

All notable changes to the images. Exact upstream versions are in each release's `VERSIONS.md`.

## [Unreleased]

## [v1.0.5] – 2026-10-22
- **Fix: services randomly missing after the first reboot** (no Wi-Fi/Ethernet because NetworkManager never started, Switch to Desktop dropping back to Game Mode). Cause: the image builder's `ps5-stage-firmware.service` creates a systemd ordering cycle (`Before=systemd-modules-load` with default dependencies, i.e. also after `basic.target`); systemd breaks it by deleting a different job each boot. Fixed with a drop-in setting `DefaultDependencies=no`. Affected v1.0.3 and v1.0.4 on all models
- MediaTek Wi-Fi (PS5 Slim) confirmed working by a tester; MediaTek Bluetooth still unconfirmed

## [v1.0.4] – 2026-10-21
- Rebuilt on current Bazzite Deck stable and rmux's latest 7.3 PS5 patches (`meower` HEAD): fan autoservo fix, boot fan target set by the kernel
- HDMI audio stability fix for FLAVA3 HDMI chips (upstream ps5-linux-patches #42, ported to 7.3)
- Wi-Fi (NXP IW620): driver rebuilt with the upstream HE capability + TX fixes; built with objtool metadata (removes the kernel warning at boot)
- Wi-Fi: NetworkManager keeps the permanent MAC during scans (fixes GUI Wi-Fi joins and the first-boot "connect to the internet" failure)
- **MediaTek MT7921 (PS5 Slim / newer) support, untested:** Wi-Fi driver enabled (`CONFIG_MT7921E=m`); Bluetooth: WizGery's btusb bulk-OUT fix (ported to 7.3) and L2CAP defer-security patch, plus udev/modprobe rules. One image for all models; drivers bind by hardware ID
- Boot: dropped the ignored `video=DP-1:1920x1080@60` from `cmdline.txt` (was logging "User-defined mode not supported" on every boot)

## [v1.0.3] – 2026-10-20
- **Bluetooth works**: the 7.3 PS5 patch registered the IW620 Bluetooth device (`1286:2059`) in the wrong `btusb` table, so its quirks never applied (two `hci` devices, `Opcode 0x2031 failed`). `patches/ps5-btusb-quirks-fix.patch` moves the entry to `quirks_table` and the interface-0 check after the quirks lookup. Only `btusb.ko` changed; a hotfix module for v1.0.2 is attached to the release.

## [v1.0.2] – 2026-10-20
First working public release.
- Linux 7.3 with rmuxnet 7.3 PS5 patches (`meower` @ 36f173f): VCN video decode/encode, Bluetooth re-enabled
- **Game Mode works**: `bpf` added to `CONFIG_LSM`, `CONFIG_DEBUG_INFO_BTF=y` (fixes `cardwired`), `lsm=…,bpf` also in `cmdline.txt`
- Wi-Fi: PS5 IW620 driver with kernel 7.2/RTNL patches + new kernel 7.3 compat patch, `ps_mode=0` (firmware is staged at boot from the loader by the builder's ps5-stage-firmware service, not shipped in the image)
- Builder: ps5-linux-image @ 52db0a4 + fixes (VCN firmware mount, Wi-Fi patch order)

## [v1.0.0] – 2026-10-20 (withdrawn)
Same image plus a first-boot service running external Wi-Fi/Bluetooth fix scripts; the Wi-Fi script reloads the driver and can hang the first boot. Do not use.

## [v0.1.0] – 2026-10-19 (not published)
- Kernel 7.2.3 (ps5-linux-patches `main` @ 753c793) build; first image with working Game Mode (cmdline `lsm=` fix only)
