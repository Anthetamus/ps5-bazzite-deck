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
| Display | 4K60 and HDR on an LG C4; adjust resolution/HDR once in Game Mode settings on first boot |
| Hardware video decode/encode (VCN) | H.264, HEVC, VP9, VC-1, MPEG-2 decode; H.264 encode (HEVC encode I-frame only) |
| Wi-Fi (NXP IW620, PS5 fat) | driver with upstream HE/TX fixes; firmware staged at boot from the loader; `ps_mode=0`; NetworkManager stable-MAC config |
| Bluetooth (NXP IW620) | yes, with `patches/ps5-btusb-quirks-fix.patch` (the 7.3 PS5 patch had the device quirks in the wrong `btusb` table) |
| Wi-Fi + Bluetooth (MediaTek MT7921, PS5 Slim / newer) | Wi-Fi confirmed by a Slim tester; Bluetooth: WizGery's patches and udev rules included, unconfirmed. Same image for all models |
| Kernel | Linux 7.3 (see [Releases](../../releases) for the exact version per image) |

Tested on: PS5 fat (CFI-10xx) · firmware 13.60 · [soniciso1 loader](https://github.com/soniciso1/ps5-linux-loader) v13.60 · LG C4 @ 4K60.
MediaTek (PS5 Slim / newer): Wi-Fi confirmed by a tester; Bluetooth unconfirmed, reports welcome.

## Install

1. Download all `ps5-bazzite-deck-vX.Y.Z.img.7z.00*` files from the latest release into one folder
   (and the `.sha256` file if you want to verify them).
2. Extract: open the `.7z.001` file with [7-Zip](https://7-zip.org) on Windows, Keka on macOS, or
   `7z x ps5-bazzite-deck-vX.Y.Z.img.7z.001` on Linux. You get `ps5-bazzite-deck.img`.
3. Flash the `.img` to a USB drive or SSD of 32 GB or more (Balena Etcher, Rufus in DD mode, or `dd`).
4. Boot with the PS5 Linux loader as usual. The first boot is slow and the screen can stay black for a while.

**Verify it's working** (Switch to Desktop → Konsole):
- `uname -r` → `7.3.0`
- `systemctl status cardwired` → `active (running)` = Game Mode works
- `vainfo` → H264 / HEVC / VP9 profiles = hardware video decode works
- `nmcli device` → Wi-Fi `connected`
- `bluetoothctl list` → a controller = Bluetooth works

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
patches/ps5-hdmi-audio-flava3.patch    HDMI audio stability for FLAVA3 HDMI chips (upstream #42, 7.3 port)
patches/ps5-mt7921-*.patch             MediaTek Bluetooth (WizGery 0003 ported to 7.3, 0004)
files/                                 files baked into the image: NetworkManager stable MAC, MediaTek BT udev/modprobe,
                                       boot ordering-cycle fix for ps5-stage-firmware.service
docs/game-mode-fix.md                  how the Game Mode problem was found and fixed
docs/release-template.md               release notes of the current release
CHANGELOG.md
```

`build.sh` changes the upstream image builder (all recorded in `local-changes.diff` in each release):
mounts the patches directory into the kernel build so the VCN firmware is found, applies the Wi-Fi driver
patches (kernel 7.2/7.3 compat, RTNL, HE/TX) with objtool enabled, and sets `lsm=…,bpf` in `cmdline.txt`.
It then builds Linux 7.3 with rmuxnet's 7.3 PS5 patches plus the patches above, `bpf` LSM + BTF +
`CONFIG_MT7921E=m`, bakes the files from `files/` into the image, and produces the release files.

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
- **PATCH** – fixes and rebuilds with newer upstream patches/firmware

Every release ships a `VERSIONS.md` with the exact pins: Bazzite image digest, kernel tag, patch repo
commits, builder commit and the kernel config changes. `CHANGELOG.md` tracks changes between releases.

## Known limitations

- Not booted via ostree: `rpm-ostree` and `ujust update` don't work; `dnf5 install` does
  (the root is a plain ext4 filesystem). A full `dnf5 upgrade` is untested; base updates come as new releases.
- On first boot, adjust the display settings in Game Mode (Settings → Display): disable HDR and set a
  higher resolution. Switching to a text console (Ctrl+Alt+F2/F3) drops the signal on some TVs.
- Black screen at boot on some TVs: disable HDMI Device Link in the PS5's HDMI settings.
- HEVC encode is I-frame only; use H.264 for streaming/recording.

## Credits

- **[ps5-linux](https://github.com/ps5-linux)** (TheOfficialFloW, resulknad, rmuxnet and contributors) –
  the PS5 Linux loader, kernel patches, image builder, VCN support and the whole foundation this builds on.
- **[rmuxnet](https://github.com/rmuxnet)** – 7.3 PS5 kernel patches (`meower` branch), VCN, the
  [PS5 Linux Guide](https://rmuxnet.gitlab.io/ps5-linux-guide/).
- **[soniciso1](https://github.com/soniciso1)** – loader with firmware 13.60 support.
- **[ps5-linux-mwifiex](https://github.com/ps5-linux/ps5-linux-mwifiex)** contributors (masterzorag,
  dmemarko and others) – PS5 IW620 Wi-Fi driver patches.
- **[WizGery](https://github.com/WizGery/ps5-mediatek-fixes)** – MediaTek Bluetooth patches.
- **[etawen](https://repo.etawen.dev/)** – PS5 package repo and documentation.
- **[Universal Blue / Bazzite](https://github.com/ublue-os/bazzite)** – Bazzite itself.
- **Gilles ([@VivaLaVent](https://github.com/VivaLaVent))** – diagnosed why Bazzite Deck's Game Mode fails on the PS5
  (`cardwired`, BPF LSM + BTF), the config and cmdline fixes, the kernel 7.3 Wi-Fi driver compatibility
  patch, the Bluetooth `btusb` quirks fix, the boot ordering-cycle fix, and this build.

## License

Scripts and documentation in this repo: MIT. `patches/*.patch` modify GPL-2.0 code and are GPL-2.0.
Images contain software under many licenses (Linux, Bazzite/Fedora packages, Steam). Not affiliated
with Sony, Valve or Universal Blue. Use at your own risk.

## Community / support

Discord: https://discord.gg/f8QARgNkf5 — test reports, questions, and the hotfix testing threads live there.
