#!/usr/bin/env bash
# ps5-build-all.sh
#
# One-step kernel build for your CachyOS PS5: runs rmuxnet's ps5-linux-patches-1 build.sh
# with the kernel-side fixes from VivaLaVent/ps5-bazzite-deck folded in. No image rebuild.
#
# Usage (run from your ps5-linux-patches-1 checkout, the one that contains build.sh):
#   bash ps5-build-all.sh              # prepare everything, verify config, build, install, deploy
#   bash ps5-build-all.sh --check      # prepare + verify the kernel config only, no compile
#   bash ps5-build-all.sh --no-cmdline # do not touch cmdline.txt on the boot partition
#   bash ps5-build-all.sh --userspace-only  # ONLY the non-patch files (udev, modprobe, NetworkManager,
#                                      # systemd units, BlueZ options); no kernel work at all
#   bash ps5-build-all.sh --no-userspace    # kernel only, skip those files
#   Extra flags: --dry-run (list what userspace would install), --yes (no confirmation),
#                --with-warm-reboot (opt-in: restarts go straight back into Linux via kexec; also
#                enables CONFIG_KEXEC/KEXEC_FILE in the kernel; switch on later with: ps5-warm-reboot on)
#
# Optional environment variables:
#   REPO=...           your ps5-linux-patches-1 checkout          (default: current directory)
#   CFG=...            your build.cfg                              (default: $REPO/build.cfg)
#   PS_MODE=0          Wi-Fi moal ps_mode (upstream uses 2; VivaLaVent uses 0 for stability)
#   KTAG=v7.3          kernel tag the patches are written for
#   EXTRA_PATCHES="/path/a.patch /path/b.patch"   more kernel patches, applied last
#   SKIP_PATCHES="ps5-hdmi-debug-log"             patches from VivaLaVent's list to leave out
#   WITH_MT7921=1      also build CONFIG_MT7921E=m (MediaTek Wi-Fi, PS5 Slim) like VivaLaVent's image
#
# What it does:
#   1. clones/updates VivaLaVent/ps5-bazzite-deck
#   2. makes a private copy of your patches dir and folds into its linux.patch every kernel patch
#        listed in VivaLaVent's own build.sh (Bluetooth, HDMI, GPU, CEC ... in his order)
#   3. tries the kernel 7.3 compat patch on the IW620 Wi-Fi driver (skipped if not needed)
#   4. writes a derived config that sets CONFIG_LSM += bpf, DEBUG_INFO_BTF=y,
#      MODULE_ALLOW_BTF_MISMATCH=y (and STRIP=n, because BTF needs debug info)
#   5. does a config-only pass and verifies the options really stuck before compiling
#   6. runs a copy of build.sh with ps_mode=$PS_MODE, builds and deploys as usual
#   7. removes video=DP-1:1920x1080@60 and adds lsm=...,bpf in cmdline.txt (backup kept)
#   8. non-patch changes: installs the files/ listed in the FILES manifest of VivaLaVent's
#        tools/make-update-bundle.sh (udev, modprobe, NetworkManager, BT services, BlueZ options),
#        skipping Bazzite/image-specific ones, after showing you the list
#
# Your own build.cfg and the original build.sh are never modified.

set -euo pipefail

log()  { echo "==> $*"; }
warn() { echo "==> WARNING: $*" >&2; }
die()  { echo "==> ERROR: $*" >&2; exit 1; }

REPO="${REPO:-$PWD}"
CFG="${CFG:-$REPO/build.cfg}"
HV_URL="https://github.com/VivaLaVent/ps5-bazzite-deck"
HV_DIR="${HV_DIR:-$HOME/ps5-bazzite-deck}"
LOCAL="${LOCAL:-$HOME/ps5-patches-local}"
KCACHE="${KCACHE:-$HOME/.cache/ps5-linux-kernel-tree}"
KERNEL_GIT="${KERNEL_GIT:-https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git}"
KTAG="${KTAG:-v7.3}"
PS_MODE="${PS_MODE:-0}"
EXTRA_PATCHES="${EXTRA_PATCHES:-}"

SKIP_PATCHES="${SKIP_PATCHES:-ps5-hdmi-debug-log}"
WITH_MT7921="${WITH_MT7921:-0}"
CHECK_ONLY=0
EDIT_CMDLINE=1
DO_USERSPACE=1
USERSPACE_ONLY=0
DRY_RUN=0
YES=0
WITH_WARM=0
for a in "$@"; do
  case "$a" in
    --check)          CHECK_ONLY=1 ;;
    --no-cmdline)     EDIT_CMDLINE=0 ;;
    --no-userspace)   DO_USERSPACE=0 ;;
    --userspace-only) USERSPACE_ONLY=1 ;;
    --dry-run)        DRY_RUN=1 ;;
    --yes|-y)         YES=1 ;;
    --with-warm-reboot|--with-kexec) WITH_WARM=1 ;;
    -h|--help)        sed -n '2,45p' "$0"; exit 0 ;;
    *)            die "unknown option: $a" ;;
  esac
done


# ---------------------------------------------------- VivaLaVent's repo
FETCHED=0
fetch_hv() {
  if [ "$FETCHED" = 1 ]; then return 0; fi
  command -v git >/dev/null || die "missing tool: git"
  log "fetching $HV_URL"
  if [ -d "$HV_DIR/.git" ]; then
    git -C "$HV_DIR" pull -q --ff-only || warn "could not update $HV_DIR, using the local copy"
  else
    git clone -q "$HV_URL" "$HV_DIR"
  fi
  log "   ps5-bazzite-deck @ $(git -C "$HV_DIR" rev-parse --short HEAD)"
  FETCHED=1
}

# ------------------------------------------------ non-patch modifications
# Source of truth is his tools/make-update-bundle.sh: the FILES heredoc there is the list
# "<file in files/> <destination> [mode]" that his own in-place updater installs. Nothing is
# installed without showing you the list first; replaced files are backed up.
install_userspace() {
  log "U. non-patch modifications (files/ + tools/ of the repo)"
  fetch_hv
  local MK="$HV_DIR/tools/make-update-bundle.sh" F="$HV_DIR/files" manifest
  [ -f "$MK" ] && [ -d "$F" ] || die "tools/make-update-bundle.sh or files/ not found in $HV_DIR"
  manifest="$(tr -d '\r' < "$MK" | sed -n "/<< 'L'/,/^L\$/p" | sed '1d;$d')"
  [ -n "$manifest" ] || die "could not read the FILES manifest from $MK"

  local -a S=() D=() M=()
  local src dst mode why
  while read -r src dst mode <&3; do
    [ -n "${src:-}" ] || continue
    why=""
    case "$dst" in
      /etc/modprobe.d/ps5-iw620.conf)
        why="Wi-Fi module options come from the kernel build (PS_MODE), his copy is the Bazzite image's" ;;
      /usr/local/sbin/ps5-kexec|/usr/local/sbin/ps5-warm-reboot|/usr/local/sbin/ps5-reboot-to-ps5|\
/etc/systemd/system/ps5-kexec-prepare.service|/etc/systemd/system/ps5-reboot.service|/etc/systemd/system/reboot.target)
        if [ "$WITH_WARM" != 1 ]; then why="warm-reboot group (overrides systemd's reboot.target), opt-in: --with-warm-reboot"; fi ;;
      /etc/systemd/system/ps5-stage-firmware.service.d/*)
        systemctl cat ps5-stage-firmware.service >/dev/null 2>&1 || why="this system has no ps5-stage-firmware.service" ;;
    esac
    if [ -z "$why" ] && [ ! -f "$F/$src" ]; then why="$src is not in files/"; fi
    if [ -n "$why" ]; then
      printf '    skip     %-58s (%s)\n' "$dst" "$why"
    else
      printf '    install  %s\n' "$dst"
      S+=("$src"); D+=("$dst"); M+=("${mode:-644}")
    fi
  done 3<<< "$manifest"
  if [ -d /etc/bluetooth ] && [ -f "$HV_DIR/tools/bt-mainconf.sh" ]; then
    echo "    edit     /etc/bluetooth/main.conf: JustWorksRepairing=always, PairableTimeout=0 (DualSense pairing)"
  fi
  for t in btmgmt python3; do
    command -v "$t" >/dev/null || warn "$t not found: ps5-bt-addr / ps5-bt-connectable need it (sudo pacman -S bluez bluez-utils python)"
  done
  echo "    not done: sshd enable and the default password (image-specific), the Bazzite version marker"

  if [ "${#D[@]}" -eq 0 ]; then log "   nothing to install"; return 0; fi
  if [ "$DRY_RUN" = 1 ]; then log "   --dry-run: nothing installed"; return 0; fi
  if [ "$YES" != 1 ]; then
    local ans=n
    read -r -p "==> install these ${#D[@]} files? [y/N] " ans </dev/tty || ans=n
    case "$ans" in y|Y) ;; *) log "   skipped"; return 0 ;; esac
  fi

  local BK i u tmp
  tmp="$(mktemp)"
  BK="/var/lib/ps5-userspace-backup/$(date +%Y%m%d-%H%M%S)"
  sudo mkdir -p "$BK"
  for i in "${!D[@]}"; do
    if sudo test -e "${D[$i]}"; then sudo cp -a --parents "${D[$i]}" "$BK/"; fi
    tr -d '\r' < "$F/${S[$i]}" > "$tmp"     # Windows line endings would break the shebangs
    sudo install -Dm"${M[$i]}" "$tmp" "${D[$i]}"
  done
  rm -f "$tmp"
  if [ -d /etc/bluetooth ] && [ -f "$HV_DIR/tools/bt-mainconf.sh" ]; then
    if [ -f /etc/bluetooth/main.conf ]; then sudo cp -a --parents /etc/bluetooth/main.conf "$BK/"; fi
    tr -d '\r' < "$HV_DIR/tools/bt-mainconf.sh" | sudo bash -s -- /etc/bluetooth/main.conf
  fi
  # same unit wiring as his image build: BT address/connectable with bluetooth.target, revive with multi-user
  for u in ps5-bt-addr ps5-bt-connectable; do
    if [ -f "/etc/systemd/system/$u.service" ]; then
      sudo mkdir -p /etc/systemd/system/bluetooth.target.wants
      sudo ln -sf "/etc/systemd/system/$u.service" "/etc/systemd/system/bluetooth.target.wants/$u.service"
    fi
  done
  if [ -f /etc/systemd/system/ps5-bt-revive.service ]; then
    sudo mkdir -p /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /etc/systemd/system/ps5-bt-revive.service /etc/systemd/system/multi-user.target.wants/ps5-bt-revive.service
  fi
  if [ "$WITH_WARM" = 1 ]; then
    if [ ! -e /usr/sbin/kexec ] && [ -f "$F/kexec-shim" ]; then
      tr -d '\r' < "$F/kexec-shim" > "$tmp"; sudo install -Dm755 "$tmp" /usr/sbin/kexec
    fi
    log "   warm-reboot group installed. It is off by default; switch on with: sudo ps5-warm-reboot on (experimental on CachyOS)"
  fi
  sudo systemctl daemon-reload
  sudo udevadm control --reload 2>/dev/null || true
  log "   installed ${#D[@]} files. Replaced files were backed up to $BK (restore: sudo cp -a $BK/. /)"
  log "   Bluetooth/udev/NetworkManager changes take effect after the next reboot"
}

if [ "$USERSPACE_ONLY" = 1 ]; then
  install_userspace
  exit 0
fi

# ---------------------------------------------------------------- 0. sanity
log "0. checking prerequisites"
REPO="$(cd "$REPO" && pwd)"
[ -f "$REPO/build.sh" ] && [ -f "$REPO/linux.patch" ] && [ -f "$REPO/.config" ] \
  || die "run this from your ps5-linux-patches-1 checkout (needs build.sh, linux.patch, .config) or set REPO=..."
[ -f "$CFG" ] || die "config not found: $CFG (copy build.cfg.example or set CFG=...)"
CFG="$(cd "$(dirname "$CFG")" && pwd)/$(basename "$CFG")"
for t in git make patch clang ld.lld pahole sudo sed grep; do
  command -v "$t" >/dev/null || die "missing tool: $t (pahole: sudo pacman -S pahole)"
done
head -n 5 "$REPO/.config" | grep -q "[ -]${KTAG#v}[. ]" \
  || die "$REPO/.config does not look like kernel $KTAG; the extra patches target $KTAG. Set KTAG=... if you know better."

# ------------------------------------------------- 1. VivaLaVent's repo
fetch_hv

# ------------------------------------------- 2. private patches directory
log "2. preparing private patches dir $LOCAL"
rm -rf "$LOCAL"
mkdir -p "$LOCAL"
cp -a "$REPO/linux.patch" "$REPO/.config" "$LOCAL/"
for d in oot firmware; do
  if [ -d "$REPO/$d" ]; then cp -a "$REPO/$d" "$LOCAL/"; fi
done

PD="$HV_DIR/patches"
# suspend-to-idle (ps5-linux-patches PR #4, Dasloh): a patch against the patches repo itself
# (.config + linux.patch), so it goes on the private copy before the kernel patches
S2="$PD/ps5-linux-patches-pr4-s2idle.patch"
case " $SKIP_PATCHES " in *" ps5-linux-patches-pr4-s2idle "*) S2="" ;; esac
if [ -n "$S2" ] && [ -f "$S2" ]; then
  if patch -p1 -N -s --dry-run -d "$LOCAL" < "$S2" >/dev/null 2>&1; then
    patch -p1 -N -s -d "$LOCAL" < "$S2" >/dev/null
    log "   applied  ps5-linux-patches-pr4-s2idle.patch (suspend-to-idle)"
  elif patch -p1 -R -s --dry-run -d "$LOCAL" < "$S2" >/dev/null 2>&1; then
    log "   skipped  ps5-linux-patches-pr4-s2idle.patch (already in your checkout)"
  else
    warn "s2idle PR #4 patch does not apply to your checkout (his build pins meower @ baee34d); suspend-to-idle skipped"
  fi
fi

# kernel tree (cached) at the exact tag
if ! git -C "$KCACHE" rev-parse -q --verify "refs/tags/$KTAG" >/dev/null 2>&1; then
  log "   cloning kernel $KTAG (one time, cached in $KCACHE)"
  rm -rf "$KCACHE"
  mkdir -p "$(dirname "$KCACHE")"
  git clone -q --depth 1 --branch "$KTAG" "$KERNEL_GIT" "$KCACHE"
fi
git -C "$KCACHE" checkout -q -f "$KTAG"
git -C "$KCACHE" clean -qfdx

git -C "$KCACHE" apply --exclude=Makefile "$LOCAL/linux.patch" \
  || die "upstream linux.patch does not apply on $KTAG"

apply_extra() {
  local p="$1" n
  n="$(basename "$p")"
  if git -C "$KCACHE" apply --check "$p" 2>/dev/null; then
    git -C "$KCACHE" apply "$p"
    log "   applied  $n"
  elif git -C "$KCACHE" apply --check -R "$p" 2>/dev/null; then
    log "   skipped  $n (already contained in upstream linux.patch)"
  else
    die "$n does not apply on top of upstream linux.patch. Upstream has probably moved; pin your checkout to the commit his latest release was built on (see VERSIONS.md of the release; v1.4.0: meower @ baee34d) and retry."
  fi
}

PD="$HV_DIR/patches"
# Patch list and order come from VivaLaVent's own build.sh, so this follows the repo as it grows.
# Fallback (if his build.sh changes format) = the list shipped in release v1.4.0.
mapfile -t PLIST < <(grep -oP 'work/linux73 apply "\$SRC/patches/\K[^"]+\.patch' "$HV_DIR/build.sh" 2>/dev/null | sed 's/\.patch$//')
if [ "${#PLIST[@]}" -eq 0 ]; then
  warn "could not read the patch list from $HV_DIR/build.sh, using the v1.4.0 list"
  PLIST=(ps5-bluetooth ps5-hdmi-upstream ps5-hdmi-rearm-pr46 ps5-hdmi-output-fixes ps5-hdmi-modes
         ps5-hdmi-debug-log ps5-hdmi-link-lock ps5-gpu-overlay ps5-hdmi-cec-upstream53
         ps5-hdmi-sleep-mute ps5-hdmi-scdc-source-version)
fi
log "   kernel patches (in order): ${PLIST[*]}"
for c in "${PLIST[@]}"; do
  case " $SKIP_PATCHES " in *" $c "*) log "   skipped  $c.patch (SKIP_PATCHES)"; continue ;; esac
  if [ -f "$PD/$c.patch" ]; then apply_extra "$PD/$c.patch"; else warn "$c.patch is listed but not in $PD, skipped"; fi
done
for p in $EXTRA_PATCHES; do apply_extra "$(readlink -f "$p")"; done

git -C "$KCACHE" add -A
git -C "$KCACHE" -c core.abbrev=12 diff --cached > "$LOCAL/linux.patch.new"
mv "$LOCAL/linux.patch.new" "$LOCAL/linux.patch"
log "   merged linux.patch written ($(wc -l < "$LOCAL/linux.patch") lines)"

# ------------------------------------------ 3. Wi-Fi driver 7.3 compat
W="$LOCAL/oot/mwifiex"
WP="$PD/ps5-iw620-kernel73-compat.patch"
if [ -d "$W" ] && [ -f "$WP" ]; then
  if patch -p1 -N -s --dry-run -d "$W" < "$WP" >/dev/null 2>&1; then
    patch -p1 -N -s -d "$W" < "$WP" >/dev/null
    log "3. applied ps5-iw620-kernel73-compat.patch to the Wi-Fi driver"
  elif patch -p1 -R -s --dry-run -d "$W" < "$WP" >/dev/null 2>&1; then
    log "3. Wi-Fi compat patch already present, skipped"
  else
    warn "Wi-Fi 7.3 compat patch does not apply to oot/mwifiex; fine if the driver already builds on $KTAG"
  fi
else
  log "3. no oot/mwifiex or no Wi-Fi compat patch, skipped"
fi

# ------------------------------------------------- 4. derived configs
log "4. writing derived build configs"
LSM="$(grep -m1 '^CONFIG_LSM=' "$LOCAL/.config" | cut -d'"' -f2 || true)"
[ -n "$LSM" ] || LSM="landlock,lockdown,yama,integrity,apparmor"
case ",$LSM," in *,bpf,*) ;; *) LSM="$LSM,bpf" ;; esac

write_cfg() {  # $1 = file, rest = extra lines
  local f="$1"; shift
  {
    echo "source \"$CFG\""
    echo "PATCHES_DIR=\"$LOCAL\""
    echo "STRIP=n   # BTF needs debug info; STRIP=y forces DEBUG_INFO_NONE and would silently drop it"
    echo "CONFIG_OPS+=("
    echo "  \"--set-str LSM $LSM\""
    echo "  \"--enable DEBUG_INFO_BTF\""
    echo "  \"--enable MODULE_ALLOW_BTF_MISMATCH\""
    if [ "$WITH_MT7921" = 1 ]; then echo "  \"--module MT7921E\""; fi
    if [ "$WITH_WARM" = 1 ]; then echo "  \"--enable KEXEC\""; echo "  \"--enable KEXEC_FILE\""; fi
    echo ")"
    for l in "$@"; do echo "$l"; done
  } > "$f"
}
CFG_CHECK="$LOCAL/build-check.cfg"
CFG_BUILD="$LOCAL/build-final.cfg"
write_cfg "$CFG_CHECK" "CONFIG_ONLY=y" "DEPLOY_EFI=n"
write_cfg "$CFG_BUILD"

# copy of build.sh with the Wi-Fi power-save option changed
BUILD="$REPO/.build-ps5-all.sh"
trap 'rm -f "$BUILD"' EXIT
sed "s/ps_mode=2/ps_mode=$PS_MODE/" "$REPO/build.sh" > "$BUILD"
chmod +x "$BUILD"
grep -q "ps_mode=$PS_MODE" "$BUILD" || warn "ps_mode not found in build.sh, left unchanged"

read_cfg_var() {  # value of a variable after sourcing the final config
  (cd "$REPO" && bash -c 'source "$1" >/dev/null 2>&1; eval "printf %s \"\${$2:-}\""' _ "$CFG_BUILD" "$1")
}
SRC_DIR="$(read_cfg_var SRC_DIR)"
[ -n "$SRC_DIR" ] || die "SRC_DIR is not set in $CFG"
case "$SRC_DIR" in /*) ;; *) SRC_DIR="$REPO/$SRC_DIR" ;; esac

verify_config() {
  local c="$SRC_DIR/.config" bad=0 w
  [ -f "$c" ] || die "$c not found after the config pass"
  local extra=""
  if [ "$WITH_WARM" = 1 ]; then extra="CONFIG_KEXEC=y CONFIG_KEXEC_FILE=y"; fi   # ps5-kexec uses kexec_file_load
  for w in CONFIG_DEBUG_INFO_BTF=y CONFIG_BPF_LSM=y $extra; do
    if grep -qx "$w" "$c"; then echo "    ok    $w"; else echo "    FAIL  $w"; bad=1; fi
  done
  if grep -q '^CONFIG_LSM=.*bpf' "$c"; then echo "    ok    CONFIG_LSM contains bpf"; else echo "    FAIL  CONFIG_LSM lacks bpf"; bad=1; fi
  [ "$bad" = 0 ] || die "required options did not stick (pahole installed? DEBUG_INFO_BTF needs DEBUG_INFO and BPF_SYSCALL). Nothing was compiled."
}

# ----------------------------------------------- 5. config-only verify
log "5. config pass (no compile) and verification"
bash "$BUILD" "$CFG_CHECK"
verify_config

if [ "$CHECK_ONLY" = 1 ]; then
  log "--check given: stopping before the build. Config is good."
  exit 0
fi

# ------------------------------------------------------- 6. real build
log "6. building (this takes a while)"
bash "$BUILD" "$CFG_BUILD"

# --------------------------------------------------- 7. cmdline.txt
if [ "$EDIT_CMDLINE" = 1 ]; then
  log "7. cmdline.txt"
  EFI=""
  CFG_EFI="$(read_cfg_var EFI_DIR)"
  if [ -n "$CFG_EFI" ] && [ "$CFG_EFI" != auto ] && sudo test -f "$CFG_EFI/cmdline.txt"; then
    EFI="$CFG_EFI"
  else
    mapfile -t cands < <(
      while read -r src mnt _; do
        [[ "$src" == /dev/* ]] || continue
        mnt="$(printf '%b' "$mnt")"
        if sudo test -f "$mnt/bzImage" && sudo test -f "$mnt/cmdline.txt"; then echo "$mnt"; fi
      done < /proc/mounts | sort -u
    )
    if [ "${#cands[@]}" -eq 1 ]; then EFI="${cands[0]}"; fi
  fi
  if [ -z "$EFI" ]; then
    warn "boot partition not found automatically; edit cmdline.txt by hand: remove video=DP-1:1920x1080@60, add lsm=$LSM"
  else
    BAK="$HOME/cmdline.txt.bak-$(date +%Y%m%d-%H%M%S)"
    sudo cat "$EFI/cmdline.txt" > "$BAK"
    sudo sed -i 's/[[:space:]]*video=DP-1:1920x1080@60//' "$EFI/cmdline.txt"
    if ! sudo grep -q 'lsm=' "$EFI/cmdline.txt"; then
      sudo sed -i "s/[[:space:]]*\$/ lsm=$LSM/" "$EFI/cmdline.txt"
    fi
    sync
    log "   $EFI/cmdline.txt (backup: $BAK):"
    sudo cat "$EFI/cmdline.txt"
  fi
fi

# ------------------------------------------- 8. non-patch modifications
if [ "$DO_USERSPACE" = 1 ]; then install_userspace; fi

# --------------------------------------------------------------- done
cat <<EOF

==> DONE. Cold boot the PS5 with the loader, then check:
      uname -r
      ls /sys/kernel/btf/vmlinux
      journalctl -b -k | grep -i 'LSM support for eBPF'
      nmcli device ; bluetoothctl list
    Rollback: copy the saved bzImage/initrd.img from your EFI_BACKUP_DIR back to the boot partition.
EOF
