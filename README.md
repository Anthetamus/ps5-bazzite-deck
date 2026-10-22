# PS5 Bazzite Deck

Turn your PS5 into a Steam console: this is [Bazzite](https://bazzite.gg) in Steam Deck mode, adapted for the
PlayStation 5. It boots straight into **Steam Gaming Mode** (the Steam Deck interface), and a full KDE
desktop is one click away.

It runs from a USB drive, through the [ps5-linux](https://github.com/ps5-linux/ps5-linux-loader) loader.
Your PS5 itself is not modified: unplug the drive and it's a normal PS5 again.

**Download:** [Releases](../../releases) · **Help & testing:** [Discord](https://discord.gg/f8QARgNkf5)

## What works

- Steam Gaming Mode, with Switch to Desktop / Return to Gaming Mode
- 4K60 over HDMI, with audio
- Hardware video decoding
- Wi-Fi, Ethernet and Bluetooth (DualSense works over Bluetooth)
- PS5 Slim / models with MediaTek Wi-Fi: Wi-Fi works

## What you need

- A PS5 (fat or Slim) on a firmware supported by the PS5 Linux loader. Tested on **13.60** with
  [soniciso1's loader](https://github.com/soniciso1/ps5-linux-loader); see the
  [ps5-linux loader](https://github.com/ps5-linux/ps5-linux-loader) for the official list.
- A USB drive of **32 GB or more**, ideally an external SSD (much faster than a stick).
- A PC to download and flash the image.
- Optional but handy for the first setup: a USB keyboard.

## PS5 settings (do this first)

In the normal PS5 menu:

- **Very important:** `Settings` → `System` → `Power Saving` → `Features Available in Rest Mode` →
  set `Supply Power to USB Ports` to `Always`.
- **Very important:** `Settings` → `HDMI` → turn **off** `Enable HDMI Device Link`.
  (If it's on, you'll typically get a black screen.)

If you reset the PS5 settings, set these again.

## Install

1. **Download** all `ps5-bazzite-deck-vX.Y.Z.img.7z.00*` files from the latest [release](../../releases)
   into one folder.
2. **Extract** the `.001` file with [7-Zip](https://7-zip.org) (Windows), Keka (macOS) or `7z x` (Linux).
   You get `ps5-bazzite-deck.img`.
3. **Flash** it to the USB drive with [Rufus](https://rufus.ie): select the drive, select the `.img`, click Start.
   This erases the drive.
4. **Plug** the drive into the PS5: a rear Type-A port or the front Type-C port (not the front Type-A, it's slow).
5. **Run the jailbreak and the loader** as described in the loader's instructions. The PS5 goes into rest mode;
   wait until the orange light stops blinking, then press the power button. A **white light** means Linux is booting.
6. **First boot is slow.** The screen can stay black for a few minutes. Let it be.

## First boot

- The default password is **`ps5`** (asked for anything that needs admin rights).
- In Game Mode, go to `Settings` → `Display`: turn **HDR off** and pick your resolution.
- Connect to Wi-Fi in the setup or in `Settings` → `Internet`. If Wi-Fi or the desktop doesn't work, **reboot once**.
- To get to the desktop: Steam button → `Power` → `Switch to Desktop`. The desktop has a "Return to Gaming Mode" icon.

## Updating

From v1.0.3 or newer you can update **without reflashing**: one update bundle brings you to the
latest version and keeps your games and settings. See [docs/updating.md](docs/updating.md).
Reflashing always works too (back up anything you want to keep from the drive first).

## Installing to the PS5's internal M.2 (advanced)

The USB drive stays required: the PS5 loader always starts the kernel from its small FAT32
partition. The M.2 holds the system. Install the **same version** on the M.2 as on the USB.
This section is new; if a step doesn't work for you, tell us in [Discord](https://discord.gg/f8QARgNkf5).

1. **Prepare the M.2** with `m2_init` from [ps5-linux-tools](https://github.com/ps5-linux/ps5-linux-tools)
   (follow their README; this wipes the M.2). On Bazzite, build the tools inside a distrobox:
   ```
   distrobox create -n build -i fedora:latest && distrobox enter build -- bash -c 'sudo dnf install -y gcc make git zlib-devel && git clone https://github.com/ps5-linux/ps5-linux-tools ~/ps5-linux-tools && make -C ~/ps5-linux-tools'
   ```

2. **Install** (booted from the USB, Konsole). `m2_install.sh` expects the boot partition at
   `/boot/efi`; Bazzite has it at `/efi`, so mount it there too first:
   ```
   sudo mkdir -p /boot/efi && sudo mount LABEL=boot /boot/efi
   cd ~/ps5-linux-tools
   sudo ./m2_install.sh --install /path/to/ps5-bazzite-deck.img
   ```
   Use the extracted `.img`, not the `.7z` files.

3. **Fix the M.2's fstab.** The script writes a boot-partition line for `/boot/efi` (on some
   versions with an empty UUID, which makes the M.2 hang in emergency mode). Replace it:
   ```
   sudo mkdir -p /mnt/m2 && sudo mount LABEL=bazzite-deck-m2 /mnt/m2
   sudo sed -i '/ vfat /d' /mnt/m2/etc/fstab
   echo "LABEL=boot /efi vfat defaults,nofail 0 2" | sudo tee -a /mnt/m2/etc/fstab
   cat /mnt/m2/etc/fstab && sudo umount /mnt/m2
   ```
   `cat` must show two lines: `LABEL=bazzite-deck-m2 / ext4 …` and `LABEL=boot /efi vfat …`.

4. **Start the M.2 system from the USB:** point `cmdline.txt` at the M.2, then reboot and run the loader:
   ```
   sudo sed -i 's/root=LABEL=bazzite-deck /root=LABEL=bazzite-deck-m2 /' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
   ```
   To go back to the USB system, change `bazzite-deck-m2` back to `bazzite-deck`.

Notes:
- Updating: run the in-place update while booted from the M.2. The USB's own system then stays on
  the old version; that's fine as long as `cmdline.txt` points to the M.2.
- `m2_exec.sh` (kexec) isn't needed with step 4. If you want it anyway: `sudo dnf install -y kexec-tools`.
- Hangs or emergency mode at boot: check the fstab from step 3.

## Troubleshooting

**White light but black screen**
- Check HDMI Device Link is off (see PS5 settings).
- Wait a few minutes on the first boot.
- Try another TV/monitor or HDMI port, and try HDCP on and off in the PS5 settings.
- Last resort: on the USB drive's small FAT32 partition, open `cmdline.txt` and add `amdgpu.force_1080p=1`
  at the end of the line.

**Boots back into the PS5 menu**: you pressed the power button too early, or the USB power setting isn't
set to `Always`.

**Wi-Fi gone or "Switch to Desktop" doesn't work after a reboot (v1.0.4 and older)**: open a terminal
(desktop → Konsole, or Ctrl+Alt+F2 if your TV keeps the picture) and run, then reboot:
```
sudo mkdir -p /etc/systemd/system/ps5-stage-firmware.service.d && printf '[Unit]\nDefaultDependencies=no\nConflicts=shutdown.target\nBefore=shutdown.target\n' | sudo tee /etc/systemd/system/ps5-stage-firmware.service.d/10-no-default-deps.conf >/dev/null && sudo systemctl daemon-reload && sudo reboot
```

**Sending logs** (we can't help without them): in a terminal run
`journalctl -b --no-pager > /tmp/log.txt; sudo cp /tmp/log.txt /efi/`, shut down, plug the drive into your PC
and send `log.txt` from the small FAT32 partition in [Discord](https://discord.gg/f8QARgNkf5).

## FAQ

- **Does this touch my PS5's games or system?** No. Everything is on the USB drive.
- **Can I dual-boot?** No. You run the jailbreak + loader each time you want Linux.
- **120 Hz / 144 Hz?** Not yet, 60 Hz for now.
- **HDR?** Not working yet. Keep it off.
- **"Your PS5 wasn't turned off properly" after using Linux?** Normal and harmless.
- **Can I install apps?** Yes: use the Discover store / Flatpak. `dnf5 install` works for system packages;
  `rpm-ostree` and `ujust update` don't (this image isn't an ostree install).

## Credits

- **[ps5-linux](https://github.com/ps5-linux)** (theflow, c0w, resulknad, rmuxnet and contributors) – the PS5 Linux
  loader, kernel patches and image builder this is built on.
- **[rmuxnet](https://github.com/rmuxnet)** – 7.3 PS5 kernel patches, video decoding, the
  [PS5 Linux Guide](https://rmuxnet.gitlab.io/ps5-linux-guide/).
- **[soniciso1](https://github.com/soniciso1)** – loader with firmware 13.60 support.
- **[ps5-linux-mwifiex](https://github.com/ps5-linux/ps5-linux-mwifiex)** contributors – PS5 Wi-Fi driver patches.
- **[WizGery](https://github.com/WizGery/ps5-mediatek-fixes)** – MediaTek Bluetooth patches.
- **[etawen](https://repo.etawen.dev/)** – PS5 package repo and documentation.
- **[Universal Blue / Bazzite](https://github.com/ublue-os/bazzite)** – Bazzite itself.
- **Gilles ([@VivaLaVent](https://github.com/VivaLaVent))** – made Game Mode work on the PS5, the Wi-Fi, Bluetooth and
  boot fixes, and this build.

Not affiliated with Sony, Valve or Universal Blue. Use at your own risk. Scripts and docs: MIT; patches: GPL-2.0.
