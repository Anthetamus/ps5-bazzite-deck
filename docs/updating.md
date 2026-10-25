# Updating without reflashing

From v1.0.3 on, every release can be installed in place: the update replaces the kernel, its drivers
and a few settings files. Your games, files and settings stay. Reflashing always works too.

## Update to the latest version

On the PS5 (in a terminal or over SSH, password `ps5`), with a network connection:
```
bash <(curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/update-latest.sh)
```
It looks up the latest release, shows your installed and the new version, downloads the update bundle,
checks it, and installs it. Then reboot (`sudo reboot`) and run the loader as usual.

- **Check your version:** `cat /etc/ps5-bazzite-deck-version`
- **A specific version** instead of the latest: put it at the end of the command, e.g. `… update-latest.sh) v1.2.0`.
  Each release's notes also have their own update command.
- **After updating,** read the release notes of the new version: they list anything to do afterwards.

## What the update does

1. checks that it runs on a PS5 Bazzite Deck install with kernel 7.3.0, and that the download is complete
2. finds the USB drive's boot partition by itself (`/efi`; on an M.2 install often `/boot/efi`, or it mounts it)
3. backs up the current kernel files, `cmdline.txt` and the kernel modules to `/var/lib/ps5-update-backup/<date>`
4. installs the new kernel and its modules
5. installs the image's settings files (Wi-Fi, Bluetooth, boot order)
6. adjusts `cmdline.txt` only where a release needs it; your own entries stay

It prints an undo command at the end; note it down. If the PS5 doesn't boot after an update, use that undo
command over SSH, or put the USB drive in your PC and reflash.

## Things to know

- **M.2 installs:** run the update from the M.2 system, with the USB drive plugged in.
- **v1.0.2 or older:** reflash; the in-place update needs v1.0.3 or newer.
- One-off fixes from older releases (the v1.0.2 Bluetooth module, the v1.0.4 boot fix) are in those releases'
  notes; updating to the latest version includes them.

Problems: [Discord](https://discord.gg/qGcuTgBBYU) · Support the project: [Ko-fi](https://ko-fi.com/vivalavent)
