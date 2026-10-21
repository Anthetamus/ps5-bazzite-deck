# ps5-bazzite-deck

Bazzite Deck (Steam Gaming Mode) images for the PlayStation 5, built on top of the
[ps5-linux](https://github.com/ps5-linux) project, with the fixes needed to make Game Mode
actually work on the PS5.

> This repo holds the build script, patches and documentation. **Images are published under
> [Releases](../../releases)**; every release lists the exact upstream versions it was built from.

Questions, test reports, help: **[Discord](https://discord.gg/f8QARgNkf5)**

## What works

| | |
|---|---|
| Boots into Steam Gaming Mode | yes, Switch to Desktop / Return to Gaming Mode work out of the box |
| Display | 4K60 and HDR on an LG C4; the mode is negotiated at boot and can't be changed afterwards |
| Hardware video decode/encode (VCN) | H.264, HEVC, VP9, VC-1, MPEG-2 decode; H.264 encode (HEVC encode I-frame only) |
| Wi-Fi (NXP IW620) | driver included, firmware staged at boot from the loader; `ps_mode=0` set for stability |
| Bluetooth | re-enabled by the 7.3 kernel patches |
| Kernel | Linux 7.3 (see [Releases](../../releases) for the exact version per image) |

Tested on: PS5 fat (CFI-10xx) · firmware 13.60 · [soniciso1 loader](https://github.com/soniciso1/ps5-linux-loader) v13.60 · LG C4 @ 4K60.
MediaTek (PS5 Slim / newer) support is included from v1.0.4 but has not been tested on hardware; reports welcome.

## Install

1. Download all `ps5-bazzite-deck-vX.Y.Z.img.7z.00*` files from the latest release into one folder
   (and the `.sha256` file if you want to verify them).
2. Extract: open the `.7z.001` file with [7-Zip](https://7-zip.org) on Windows, Keka on macOS, or
   `7z x ps5-bazzite-deck-vX.Y.Z.img.7z.001` on Linux. You get `ps5-bazzite-deck.img`.
3. Flash the `.img` to a USB drive or SSD of 32 GB or more (Balena Etcher, Rufus in DD mode, or `dd`).
4. Boot with the PS5 Linux loader as usual. The first boot is slow and the screen can stay black for a while.

Check on the PS5: `uname -r` (kernel), `systemctl status cardwired` (must be *active* for Game Mode),
`vainfo` (video decode), `nmcli device` (Wi-Fi).

## Why Bazzite Deck never worked on the PS5

It was never the display or gamescope. Bazzite's Game Mode session launches Steam through the
`cardwired` service, which loads an eBPF program and therefore needs two kernel features that the
PS5 kernel configs don't enable:

1. **The BPF LSM.** `CONFIG_BPF_LSM=y` is set, but `bpf` is missing from `CONFIG_LSM`, so it never
   activates. (`lsm=landlock,lockdown,yama,integrity,apparmor,bpf` on the kernel command line also works.)
2. **Kernel BTF.** The 7.3 patch set has `CONFIG_DEBUG_INFO_BTF` off, so `/sys/kernel/btf/vmlinux`
   doesn't exist.

Without them `cardwired` crash-loops (`CardwireEbpfError(LSMNotEnabled)` / `error parsing
/sys/kernel/btf/vmlinux`), the session script kills gamescope one second after it starts, and after
five attempts Bazzite drops you to the desktop. Both are one-line config changes, applied in `build.sh`.
Full write-up: [docs/game-mode-fix.md](docs/game-mode-fix.md).

## What's in this repo

```
build.sh                               one-shot build: clone builder, apply fixes, build, post-build, compress
patches/ps5-iw620-kernel73-compat.patch kernel 7.3 compatibility for the PS5 IW620 Wi-Fi driver (cfg80211 API changes)
patches/ps5-btusb-quirks-fix.patch     Bluetooth: PS5 IW620 btusb quirks moved to quirks_table (fixes init failure)
patches/ps5-hdmi-audio-flava3.patch     HDMI audio stability for FLAVA3 HDMI chips (upstream #42, 7.3 port)
patches/ps5-mt7921-*.patch              MediaTek Bluetooth (WizGery 0003 ported to 7.3, 0004)
files/                                  config files baked into the image (NetworkManager stable MAC, MediaTek BT udev/modprobe)
docs/game-mode-fix.md                  how the Game Mode problem was found and fixed
docs/release-template.md               release notes template
CHANGELOG.md
```

`build.sh` changes the upstream image builder in three places (all recorded in `local-changes.diff`
in each release): mounts the patches directory into the kernel build so the VCN firmware is found,
applies the kernel 7.2/7.3 and RTNL patches to the Wi-Fi driver, and adds `lsm=…,bpf` to `cmdline.txt`.
It then builds Linux 7.3 with rmuxnet's 7.3 PS5 patches, the two config fixes above, bakes the Wi-Fi
driver option (`ps_mode=0`) into the image, and produces the release files.

### Building it yourself

Linux or WSL with Docker and ~60 GB free:
```
git clone https://github.com/VivaLaVent/ps5-bazzite-deck && cd ps5-bazzite-deck
bash build.sh
```
Takes a couple of hours (kernel compile + Bazzite download). Output lands in `~/ps5-build-7.3/output/`.

## Versioning

Releases are tagged `vMAJOR.MINOR.PATCH`:

- **MAJOR** – a different base (new Bazzite major, new kernel series such as 7.4)
- **MINOR** – new features or fixes that change what works (Wi-Fi, Bluetooth, Game Mode, …)
- **PATCH** – rebuilds with newer upstream patches/firmware and no functional change

Every release ships a `VERSIONS.md` with the exact pins: Bazzite image digest, kernel tag, patch repo
commits, builder commit, Wi-Fi driver/firmware hashes and the kernel config changes. The release
notes repeat the important ones. `CHANGELOG.md` tracks changes between releases.

## Known limitations

- Not booted via ostree: `rpm-ostree` and `ujust update` don't work; `dnf5 install` does
  (the root is a plain ext4 filesystem). Treat Bazzite updates as unsupported.
- The display runs at the mode negotiated at boot and can't be changed afterwards. Switching to a text
  console (Ctrl+Alt+F3) drops the signal.
- The Game Mode menu renders at 1080p and is upscaled (same as on any Bazzite HTPC); games run at the
  resolution set in Steam → Settings → Display.
- HEVC encode is I-frame only; use H.264 for streaming/recording.

## Credits

- **[ps5-linux](https://github.com/ps5-linux)** (TheOfficialFloW, resulknad, rmuxnet and contributors) –
  the PS5 Linux loader, kernel patches, image builder, VCN support and the whole foundation this builds on.
- **[rmuxnet](https://github.com/rmuxnet)** – 7.3 PS5 kernel patches (`meower` branch), VCN, the
  [PS5 Linux Guide](https://rmuxnet.gitlab.io/ps5-linux-guide/).
- **[soniciso1](https://github.com/soniciso1)** – loader with firmware 13.60 support.
- **[ps5-linux-mwifiex](https://github.com/ps5-linux/ps5-linux-mwifiex)** contributors (masterzorag,
  dmemarko and others) – PS5 IW620 Wi-Fi driver patches.
- **[etawen](https://repo.etawen.dev/)** – PS5 package repo and documentation.
- **[Universal Blue / Bazzite](https://github.com/ublue-os/bazzite)** – Bazzite itself.
- **Gilles ([@VivaLaVent](https://github.com/VivaLaVent))** – diagnosed why Bazzite Deck's Game Mode fails on the PS5
  (`cardwired`, BPF LSM + BTF), the config and cmdline fixes, the kernel 7.3 Wi-Fi driver compatibility
  patch, the Bluetooth `btusb` quirks fix, and this build.

## License

Scripts and documentation in this repo: MIT. `patches/*.patch` modify GPL-2.0 code and are GPL-2.0.
Images contain software under many licenses (Linux, Bazzite/Fedora packages, Steam). Not affiliated
with Sony, Valve or Universal Blue. Use at your own risk.

## Community / support

Discord: https://discord.gg/f8QARgNkf5 — test reports, questions, and the hotfix testing threads live there.
