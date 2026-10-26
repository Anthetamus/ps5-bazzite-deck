# PS5 Bazzite Deck

Turn your PS5 into a Steam console: this is [Bazzite](https://bazzite.gg) in Steam Deck mode, adapted for the
PlayStation 5. It boots straight into **Steam Gaming Mode** (the Steam Deck interface), and a full KDE
desktop is one click away.

It runs from a USB drive, started by **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases).
Your PS5 itself is not modified: unplug the drive and it's a normal PS5 again.

**Download:** [Releases](../../releases) · **Help & testing:** [Discord](https://discord.gg/qGcuTgBBYU) · **Support the project:** [Ko-fi](https://ko-fi.com/vivalavent)

## What works

- Steam Gaming Mode, with Switch to Desktop / Return to Gaming Mode
- 4K60 over HDMI, with audio
- Hardware video decoding
- Wi-Fi, Ethernet and Bluetooth (DualSense works over Bluetooth)
- Consoles with MediaTek Wi-Fi: Wi-Fi works

## What you need

- A PS5 on a firmware **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases) supports (see its releases). Tested on firmware 13.60.
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
4. **Plug** the drive into a fast USB port. Every PS5 has fast ports (SuperSpeed, 10 Gbit/s) and one slow port
   (Hi-Speed, the older USB 2.0 speed of 480 Mbit/s). A slow port works, but booting, loading and installing
   games become much slower.
   - **Original PS5:** the two **rear** USB-A ports or the **front USB-C** port. The front USB-A port is the slow one.
   - **PS5 Slim:** the two **rear** USB-A ports. One of the two front USB-C ports is the slow one, so the rear
     ports are the safe choice.

   Use the slow port for a controller or keyboard.
5. **Run the jailbreak and the loader** as described in the loader's instructions. The PS5 goes into rest mode;
   wait until the orange light stops blinking, then press the power button. A **white light** means Linux is booting.
6. **First boot is slow.** The screen can stay black for a few minutes. Let it be.

## First boot

- The default password is **`ps5`** (asked for anything that needs admin rights). SSH is on from v1.0.7:
  `ssh ps5@<your PS5's IP>`. **Change the password** with `passwd`, since anyone on your network can try `ps5`.
- **Important:** set **RGB range** to **Full**, in both Gaming Mode and desktop mode.
- The first start is at **1080p60**. Pick your resolution in the display settings (Game Mode: Settings → Display); it's remembered.
- Connect to Wi-Fi during the setup. If Wi-Fi doesn't work after that, **reboot once**.

## Updating

From v1.0.3 or newer you can update **without reflashing**; your games and settings stay. On the PS5
(in a terminal or over SSH, password `ps5`):
```
bash <(curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/update-latest.sh)
```
Then reboot and run the loader. Details: [docs/updating.md](docs/updating.md). Reflashing always works too
(back up anything you want to keep from the drive first).

## Installing to the PS5's internal M.2 (advanced)

The USB drive stays required: the PS5 loader always starts the kernel from its small FAT32
partition. The M.2 holds the system. Install the **same version** on the M.2 as on the USB.
If a step doesn't work for you, tell us in [Discord](https://discord.gg/qGcuTgBBYU).

All steps run on the PS5, booted from the USB, in a terminal (password `ps5`).

1. **Get the tools** ([ps5-linux-tools](https://github.com/ps5-linux/ps5-linux-tools); Bazzite has everything needed to build them).
   If the M.2 isn't prepared for Linux yet, follow their README (`m2_init`) first.
   ```
   git clone https://github.com/ps5-linux/ps5-linux-tools ~/ps5-linux-tools && make -C ~/ps5-linux-tools
   ```

2. **Install.** `m2_install.sh` looks for the boot partition at `/boot/efi`; Bazzite has it at `/efi`, so mount it there too:
   ```
   sudo mkdir -p /boot/efi && (mountpoint -q /boot/efi || sudo mount LABEL=boot /boot/efi)
   cd ~/ps5-linux-tools && sudo ./m2_install.sh --install /path/to/ps5-bazzite-deck.img
   ```
   - Use the extracted `.img`, not the `.7z` files.
   - Keep the `.img` **on the USB system** (e.g. in `~/Downloads`), **not on the M.2**: the M.2 is wiped during the install.
   - Tip: type the command up to `--install ` (with the space), then drag the `.img` from the file manager into the
     terminal to insert its path.
   - **What you'll see:** `Formatting /dev/nvme0n1p1 …`, then `Copying files to M.2...`, and then **nothing for
     10–30 minutes** while it copies the system (there's no progress bar). Wait until it prints `Installation complete.`
   - **It asks for the password and then ends without printing anything:** `/boot/efi` isn't mounted, or it's mounted
     several times (from running a plain `mount` line more than once). Reset it to one mount, then run the install again:
     `while mountpoint -q /boot/efi; do sudo umount /boot/efi; done; sudo mount LABEL=boot /boot/efi`
   - `/dev/nvme0n1p1 not found`: the M.2 isn't prepared for Linux yet, see step 1 (`m2_init`).

3. **Boot from the M.2 from now on:** point `cmdline.txt` at the M.2:
   ```
   sudo sed -i 's/root=LABEL=bazzite-deck /root=LABEL=bazzite-deck-m2 /' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
   ```

4. **Start it:** reboot (`sudo reboot`) and run the loader as usual; it now starts the system on the M.2.
   (Optional: `cd ~/ps5-linux-tools && sudo ./m2_exec.sh` switches right away without a reboot. If it says `kexec`
   isn't found, just reboot instead.)

To go back to the USB system, change `bazzite-deck-m2` back to `bazzite-deck` in `cmdline.txt`.

Notes:
- The first start from the M.2 can show a grey or black screen: reboot once and run the loader again.
- **The USB drive afterwards:** keep its small FAT32 partition (label `boot`): the loader always starts Linux from
  there, and updates put the new kernel there. The big Linux partition on the USB is only a fallback now. You can
  reformat that one for storage (only that partition, not the whole drive), but then you can no longer switch back
  to the USB system via `cmdline.txt`.
- Updating: run the in-place update while booted from the M.2, with the USB drive plugged in. The update script
  finds the USB drive's boot partition by itself: on an M.2 install it is often mounted at `/boot/efi` instead of
  `/efi`, or not at all.
- Commands in this README that edit `/efi/cmdline.txt`: on an M.2 install use `/boot/efi/cmdline.txt` if that's
  where it is mounted, or edit `cmdline.txt` from your PC.
- Stuck in emergency mode when booting the M.2: its `/etc/fstab` may contain a boot-partition line with an empty
  `UUID=`. Replace that line with `LABEL=boot /efi vfat defaults,nofail 0 2` (mount the M.2 from the USB system
  with `sudo mount LABEL=bazzite-deck-m2 /mnt` to edit it).

## 40 GPU compute units (optional)

The PS5's GPU has 40 compute units (CUs); Sony ships it with 36 active. The other 4 were switched off at the
factory, partly because on some chips one of them is faulty. That's the **silicon lottery**: on many consoles all
40 work and you get more GPU power, on others the extra units cause green dots and other artifacts, a purple
tint, or crashes. Try it, and switch it back off if you see any of that.

**Switch on** (in a terminal or over SSH), then reboot and run the loader:
```
sudo sed -i -e 's/amdgpu\.ps5_cu_unlock=[0-9]*/amdgpu.ps5_cu_unlock=3/' -e '/ps5_cu_unlock/!s/[[:space:]]*$/ amdgpu.ps5_cu_unlock=3/' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
```
**Check:** `dmesg | grep active_cu_number` shows `40` (36 without it).

**Switch off** again:
```
sudo sed -i 's/ *amdgpu\.ps5_cu_unlock=[0-9]*//' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
```

Your setting stays as it is across in-place updates (from v1.1.1). On an M.2 install, use `/boot/efi/cmdline.txt`
instead of `/efi/cmdline.txt` if that's where the boot partition is mounted.

## Troubleshooting

If something doesn't work, go through these three first.

### 1. PS5 settings
Check the settings from [PS5 settings](#ps5-settings-do-this-first): **HDMI Device Link off** and
**Supply Power to USB Ports: Always**. A reset or a firmware update of the PS5 can change them back.

### 2. Linux loader
Use the latest version of **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases) for your firmware. An older version, or one for a
different firmware, typically ends up back in the PS5 menu or with no white light at all.

### 3. Boot options (`cmdline.txt`)
`cmdline.txt` is on the USB drive's small FAT32 partition and must stay **one single line**: add an option at the
end with a space in front of it, or delete it again to undo.

| Option | What it does | When to use it |
|---|---|---|
| `amdgpu.force_1080p=1` | Only allows 1080p60 | Black or garbled picture you can't get past, e.g. after picking a resolution your display can't show (Game Mode and the desktop remember it). Remove it again once you've set a working resolution |
| `hdmi.rearm=0` | Turns off the "picture comes back when the TV wakes up" fix | The picture flickers or goes black right after appearing, e.g. after re-plugging HDMI |
| `usbcore.autosuspend=-1` | USB devices never go to sleep | The USB drive/SSD disconnects, the system freezes, or there are I/O errors |
| `usb-storage.quirks=xxxx:yyyy:u` | Turns off UAS for one USB drive (replace `xxxx:yyyy` with its ID from `lsusb`) | Same, with USB-C SSDs or enclosures: many have buggy UAS (resets, I/O errors, freezes) |
| `amdgpu.ps5_cu_unlock=3` | Uses all 40 GPU compute units instead of 36. **Opt-in**, see [40 GPU compute units](#40-gpu-compute-units-optional) | You want more GPU power and your console's extra units work |

Leave the entries that are already in `cmdline.txt` as they are, especially `lsm=…` (Game Mode needs it).

**HDMI log for black-screen reports** (when asked for it): add ` dyndbg="file drivers/ps5/hdmi.c +p"` to
`cmdline.txt`; after a black boot, `sudo dmesg | grep -e notify -e setup` shows what the HDMI chip reported.

### Common problems

**White light but black screen**
- Check HDMI Device Link is off (see PS5 settings).
- Wait a few minutes on the first boot.
- Try another TV/monitor or HDMI port, and try HDCP on and off in the PS5 settings.
- Last resort: on the USB drive's small FAT32 partition, open `cmdline.txt` and add `amdgpu.force_1080p=1`
  at the end of the line.

**Black screen, but the PS5 is running** (sound works, or SSH works): with a USB keyboard press
<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F2</kbd>, wait 2–3 seconds, then <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F1</kbd>: that sets the
picture up again. Switching the TV input away and back can also help. Over SSH: `sudo chvt 2; sleep 3; sudo chvt 1`.

**Controller connects once, then doesn't reconnect by itself**: fixed in v1.4 (the Bluetooth adapter now accepts
incoming connections). On older versions: `sudo btmgmt connectable on` (until the next reboot).

**Games crash, freeze, or show green dots, artifacts or a purple tint**: if you switched on the 40-CU unlock,
switch it off again (see [40 GPU compute units](#40-gpu-compute-units-optional)) and reboot.

**Boots back into the PS5 menu**: you pressed the power button too early, or the USB power setting isn't
set to `Always`.

**Wi-Fi gone after a reboot (v1.0.4 and older)**: open a terminal (Konsole, SSH, or Ctrl+Alt+F2 if your TV
keeps the picture) and run, then reboot:
```
sudo mkdir -p /etc/systemd/system/ps5-stage-firmware.service.d && printf '[Unit]\nDefaultDependencies=no\nConflicts=shutdown.target\nBefore=shutdown.target\n' | sudo tee /etc/systemd/system/ps5-stage-firmware.service.d/10-no-default-deps.conf >/dev/null && sudo systemctl daemon-reload && sudo reboot
```

**Display or HDMI problems**: run this on the PS5 (terminal or SSH) while the problem is visible, and send the
file it names in [Discord](https://discord.gg/qGcuTgBBYU):
```
curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/diag.sh | bash
```

**Sending logs** (we can't help without them): in a terminal run
`journalctl -b --no-pager > /tmp/log.txt; sudo cp /tmp/log.txt /efi/`, shut down, plug the drive into your PC
and send `log.txt` from the small FAT32 partition in [Discord](https://discord.gg/qGcuTgBBYU).

## FAQ

- **One DualSense for the PS5 and Linux?** Yes, if the DualSense has pairing profiles (PS + a face button).
  Keep the PS5 pairing on one profile, and pair Linux on a different profile, for example PS + Square. You
  don't need a USB cable when you switch systems. From v1.4. See [docs/dualsense-profiles.md](docs/dualsense-profiles.md).
- **Pairing a DualSense:** in Bluetooth settings, start the search, then hold **PS + Create** until the light
  flashes quickly. A controller that's still connected can't enter pairing mode: switch it off first (hold PS for
  10 seconds). After pairing it may disconnect once after a second; that's normal, press PS and it reconnects.
  To reconnect later, just press PS: the controller connects to the PS5, not the other way round.
- **Bluetooth gone after a restart:** from v1.4 the system revives the adapter by itself after ~30 seconds. If it
  stays gone, power the PS5 off completely and run the loader again.
- **DualSense over Bluetooth:** the speaker and headphone jack only work over USB. Don't plug in the USB cable while
  it's connected over Bluetooth; disconnect Bluetooth first.
- **Video:** the PS5's GPU has no AV1 decoder. For YouTube in a browser, an extension like enhanced-h264ify gives
  hardware-decoded H.264 instead.

- **Does this touch my PS5's games or system?** No. Everything is on the USB drive.
- **Can I dual-boot?** No. You run the jailbreak + loader each time you want Linux.
- **Restart:** from v1.4, a restart (Steam's Restart, the desktop's Restart, `sudo reboot`) goes **straight back into
  Linux** in about 20 seconds, without the PS5 system and the loader. To get back to the PS5 system, run
  `ps5-reboot-to-ps5` (terminal or SSH) or just power off. If a warm restart ever ends on a black screen, hold the
  power button to turn the PS5 off and run the loader; `sudo systemctl mask ps5-kexec-prepare` turns warm restarts off
  (`unmask` turns them back on).
- **Sleep:** from v1.4, a short press of the power button (or Steam's Sleep) puts the PS5 to sleep: screen off,
  orange light, the game paused. A short press wakes it (one beep) and the game, network and Bluetooth continue.
  The GPU stays on, so it saves little power. Thanks to Dasloh (ps5-linux-patches PR #4).
- **VRR?** Not possible. The PS5's HDMI chip locks the frame timing itself, so a variable refresh rate from the GPU
  doesn't get through (tested in the v1.4 pre-releases: the picture shifts and blinks). It would need Sony's own chip
  setup, which isn't known.
- **Which resolutions?** 1080p60, 1080p120, 1440p60, 1440p120 and 4K60, whenever your TV/monitor can do them. Other resolutions and refresh rates aren't possible through the PS5's HDMI chip.
- **HDR?** Works on most consoles at 1080p60 and 4K60 (Game Mode → Settings → Display). If the picture looks wrong with HDR on, your console doesn't support it: switch it off.
- **"Your PS5 wasn't turned off properly" after using Linux?** Normal and harmless.
- **Can I install apps?** Yes: use the Discover store / Flatpak. `dnf5 install` works for system packages;
  `rpm-ostree` and `ujust update` don't (this image isn't an ostree install).

## Support the project

This is a hobby project, built and tested in my free time. If it's useful to you, you can support it on
[Ko-fi](https://ko-fi.com/vivalavent). Thank you!

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
