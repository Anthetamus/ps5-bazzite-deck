# Updating without reflashing

All releases from v1.0.3 on use the same Bazzite base and the same kernel version (7.3.0). Updating
in place means replacing the kernel, its drivers and a few settings files; your games, files and
settings stay. Reflashing always works too.

## Which way?

| You have | Update to | How |
|---|---|---|
| v1.0.3, v1.0.4 or v1.0.5 | **v1.0.6** | the update bundle (below) |
| the v1.0.6 pre-release | v1.0.6 | the update bundle, or replace `bzImage` |
| v1.0.4 and only want v1.0.5 | v1.0.5 | the one-line boot fix (v1.0.5 release notes) |
| v1.0.2 | v1.0.3 | `btusb.ko` (v1.0.3 release notes) |
| older, or not sure | latest | reflash |

`uname -r` must print `7.3.0`; the update script checks this and stops otherwise.

## The update bundle (to v1.0.6)

On the PS5 (desktop → Konsole, password `ps5`), with a network connection:
```
cd ~ && curl -LO https://github.com/VivaLaVent/ps5-bazzite-deck/releases/download/v1.0.6/ps5-bazzite-deck-v1.0.6-update.tar.xz && curl -LO https://github.com/VivaLaVent/ps5-bazzite-deck/releases/download/v1.0.6/ps5-bazzite-deck-v1.0.6-update.tar.xz.sha256 && sha256sum -c ps5-bazzite-deck-v1.0.6-update.tar.xz.sha256 && tar xJf ps5-bazzite-deck-v1.0.6-update.tar.xz && bash ps5-bazzite-deck-v1.0.6-update/update.sh
```
Then reboot and run the loader as usual.

What `update.sh` does, in order:
1. checks that it runs on a PS5 Bazzite Deck install with kernel 7.3.0, and that the download is complete
2. backs up the current kernel files from `/efi`, `cmdline.txt` and `/usr/lib/modules/7.3.0` to `/var/lib/ps5-update-backup/<date>`
3. installs the new kernel (`bzImage`, initrd) to `/efi` and the new modules to `/usr/lib/modules/7.3.0`
4. installs the settings files: Wi-Fi stable-MAC config, Wi-Fi driver option, MediaTek Bluetooth rules, the boot-order fix
5. removes the old `video=DP-1:1920x1080@60` entry from `cmdline.txt` (keeps your other entries)

It prints an undo command at the end. If the PS5 doesn't boot after the update: put the USB drive in your PC
and reflash, or boot the previous kernel by copying `bzImage` back (the backup is on the Linux partition).

## From the v1.0.6 pre-release: kernel only

The final v1.0.6 only changed the kernel image. On the USB drive's FAT32 partition (from your PC):
rename `bzImage` to `bzImage.old`, copy the new `bzImage` there. Optional: add ` hdmi.allow_1440p120=1`
to the line in `cmdline.txt` for 1440p120.

## From v1.0.4 to v1.0.5 only
```
sudo mkdir -p /etc/systemd/system/ps5-stage-firmware.service.d && printf '[Unit]\nDefaultDependencies=no\nConflicts=shutdown.target\nBefore=shutdown.target\n' | sudo tee /etc/systemd/system/ps5-stage-firmware.service.d/10-no-default-deps.conf >/dev/null && sudo systemctl daemon-reload && sudo reboot
```

## From v1.0.2 to v1.0.3 only
```
cd ~ && curl -LO https://github.com/VivaLaVent/ps5-bazzite-deck/releases/download/v1.0.3/btusb.ko && sudo cp btusb.ko /usr/lib/modules/$(uname -r)/kernel/drivers/bluetooth/btusb.ko && sudo depmod -a && sudo reboot
```

Problems: [Discord](https://discord.gg/f8QARgNkf5)
