# Changelog

All notable changes to the images. Exact upstream versions are in each release's `VERSIONS.md`.

## [Unreleased]

## [v1.0.2] – 2026-10-20
First working public release.
- Linux 7.3 with rmuxnet 7.3 PS5 patches (`meower` @ 36f173f): VCN video decode/encode
- **Game Mode works**: `bpf` added to `CONFIG_LSM`, `CONFIG_DEBUG_INFO_BTF=y` (fixes `cardwired`), `lsm=…,bpf` also in `cmdline.txt`
- Wi-Fi: PS5 IW620 driver with kernel 7.2/RTNL patches + new kernel 7.3 compat patch, `ps_mode=0` (firmware is staged at boot from the loader by the builder's ps5-stage-firmware service, not shipped in the image)
- Builder: ps5-linux-image @ 52db0a4 + fixes (VCN firmware mount, Wi-Fi patch order)
- Known: Bluetooth not working (controller enumerates, never initializes)

## [v1.0.0] – 2026-10-20 (withdrawn)
Same image plus a first-boot service running external Wi-Fi/Bluetooth fix scripts; the Wi-Fi script reloads the driver and can hang the first boot. Do not use.

## [v0.1.0] – 2026-10-19 (not published)
- Kernel 7.2.3 (ps5-linux-patches `main` @ 753c793) build; first image with working Game Mode (cmdline `lsm=` fix only)
