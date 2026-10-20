# Why Bazzite Deck's Game Mode fails on the PS5, and the fix

**Symptom:** Bazzite Deck boots, Game Mode tries to start, a few seconds of no signal, then the KDE desktop.
Same thing with the "Return to Gaming Mode" shortcut. Steam re-updates itself every time you reach the
desktop (Bazzite's recovery step resets Steam after five failed Game Mode starts).

**What it is not:** the display path. Gamescope initializes the GPU, opens the display at 4K60, starts
Xwayland, reads the EDID and renders its first frame without a single error. It runs fine in a window on
the desktop, and the kernel logs nothing at the moment of failure.

**What it is:** the session script (`/usr/share/gamescope-session-plus/gamescope-session-plus`) starts
gamescope, then launches the Steam client through `cardwire`:
```
if command -v /usr/bin/cardwire >/dev/null; then
  /usr/bin/cardwire launch $CLIENTCMD
```
`cardwired.service` (the daemon behind it) is crash-looping, so the launch fails instantly
(`Cannot communicate with cardwired … The name is not activatable`), the script records "steam failed",
tears the session down and kills a perfectly healthy gamescope. After five such attempts in 60 s Bazzite
switches to desktop mode.

`journalctl -u cardwired` shows why the daemon dies. Two different errors depending on the kernel:

| Kernel | Error | Cause |
|---|---|---|
| ps5-linux-patches 7.2.3 | `CardwireEbpfError(LSMNotEnabled)` | `CONFIG_BPF_LSM=y` but `CONFIG_LSM="landlock,lockdown,yama,integrity,apparmor"` – no `bpf` |
| rmuxnet 7.3 (`meower`) | `CardwireEbpfError(Aya("error parsing /sys/kernel/btf/vmlinux"))` | `CONFIG_DEBUG_INFO_BTF` not set – no BTF at all (plus the LSM issue above) |

**Fix (kernel config):**
```
CONFIG_LSM="landlock,lockdown,yama,integrity,apparmor,bpf"
CONFIG_DEBUG_INFO_BTF=y
```
The LSM half can also be applied without rebuilding, by appending
`lsm=landlock,lockdown,yama,integrity,apparmor,bpf` to `cmdline.txt` on the FAT32 boot partition.
The BTF half needs a kernel rebuild (BTF is generated at build time).

**How to check on any PS5 kernel:**
```
journalctl -b -k | grep -i lsm        # "LSM support for eBPF active"
ls /sys/kernel/btf/vmlinux            # must exist
systemctl status cardwired            # active (running)
```
If all three are good, Bazzite Deck boots into Game Mode.

Found by Gilles with a lot of `journalctl`, one gdb wrapper around gamescope, and process of elimination
(HDR, colour management, display modes and Deep Colour were all ruled out first).
