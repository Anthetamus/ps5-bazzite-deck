#!/bin/bash
# build.sh - one-shot build of the PS5 Bazzite Deck image (kernel 7.3 + VCN + Game Mode + Wi-Fi fixes).
# Run from the repo root, in WSL/Linux with Docker:   bash build.sh
# Output: output/ps5-bazzite-deck-<RELEASE>.img.7z.001/.002/.003 (+ .sha256, VERSIONS.md, local-changes.diff)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # this repo
RELEASE="${RELEASE:-$(git -C "$SRC" describe --tags --always 2>/dev/null || echo dev)}"

REPO="$HOME/ps5-build-7.3"            # fresh build directory
OLD="$HOME/ps5-linux-image"           # previous build dir, only used to reuse its download cache
BUILDER_COMMIT=52db0a4                 # ps5-linux/ps5-linux-image
PATCHES_BRANCH=meower                  # rmuxnet/ps5-linux-patches-1, 7.3 port (@ 36f173f when this was written)
KERNEL_TAG=v7.3

[ -d "$REPO" ] && { echo "$REPO already exists. Remove it (rm -rf $REPO) or change REPO at the top of this script."; exit 1; }
for t in git docker 7z sha256sum losetup; do command -v $t >/dev/null || { echo "missing tool: $t"; exit 1; }; done

echo "==> 1. builder ($BUILDER_COMMIT)"
git clone -q https://github.com/ps5-linux/ps5-linux-image "$REPO"
cd "$REPO"
git checkout -q "$BUILDER_COMMIT"
[ -d "$OLD/cache" ] && cp -r "$OLD/cache" cache && echo "    reusing download cache from $OLD/cache"

echo "==> 2. builder fixes"
# 2a. mount patches + extra patches into the kernel build container (both kernel docker runs)
sed -i 's#-v "$KERNEL_SRC":/src \\#-v "$KERNEL_SRC":/src -v "'"$REPO"'/work/ps5-linux-patches":/ps5-linux-patches:ro -v "'"$REPO"'/extra-patches":/extra-patches:ro \\#' build_image.sh
[ "$(grep -c 'extra-patches:ro' build_image.sh)" = 2 ] || { echo "mount edit failed"; exit 1; }
# 2b. Wi-Fi driver: apply kernel72, rtnl and kernel73 patches after the kernel71 one
B=docker/kernel-builder/build.sh
sed -i '/ps5-iw620-kernel71-compat.patch"$/a if [ -f /extra-patches/ps5-iw620-kernel73-compat.patch ]; then git -C "$NXP_MW" apply /extra-patches/ps5-iw620-kernel73-compat.patch; fi' "$B"
sed -i '/ps5-iw620-kernel71-compat.patch"$/a git -C "$NXP_MW" apply "$PS5_MW/ps5-iw620-rtnl-bounded-wait.patch"' "$B"
sed -i '/ps5-iw620-kernel71-compat.patch"$/a git -C "$NXP_MW" apply "$PS5_MW/ps5-iw620-kernel72-compat.patch"' "$B"
grep -q kernel73 "$B" || { echo "wifi patch edit failed"; exit 1; }
# 2c. Game Mode: bpf LSM on the kernel command line (belt and braces, config has it too)
sed -i 's/preempt=full$/preempt=full lsm=landlock,lockdown,yama,integrity,apparmor,bpf/' boot/cmdline.txt
# 2d. kernel 7.3 compat patch for the IW620 Wi-Fi driver (from this repo)
mkdir -p extra-patches
cp "$SRC/patches/ps5-iw620-kernel73-compat.patch" extra-patches/

echo "==> 3. kernel source: $KERNEL_TAG + $PATCHES_BRANCH patches"
mkdir -p work
git clone -q -b "$PATCHES_BRANCH" https://github.com/rmuxnet/ps5-linux-patches-1 work/ps5-linux-patches
sed -i 's/^CONFIG_LSM=.*/CONFIG_LSM="landlock,lockdown,yama,integrity,apparmor,bpf"/' work/ps5-linux-patches/.config
sed -i 's/^# CONFIG_DEBUG_INFO_BTF is not set/CONFIG_DEBUG_INFO_BTF=y/' work/ps5-linux-patches/.config
grep -q '^CONFIG_DEBUG_INFO_BTF=y' work/ps5-linux-patches/.config || echo 'CONFIG_DEBUG_INFO_BTF=y' >> work/ps5-linux-patches/.config
git clone -q --branch "$KERNEL_TAG" --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git work/linux73
git -C work/linux73 apply --exclude=Makefile ../ps5-linux-patches/linux.patch
git -C work/linux73 apply "$SRC/patches/ps5-btusb-quirks-fix.patch"   # Bluetooth: PS5 quirks must live in btusb quirks_table
cp work/ps5-linux-patches/.config work/linux73/.config
cp -r work/ps5-linux-patches work/linux73/ps5-linux-patches
grep -E '^CONFIG_LSM=|^CONFIG_DEBUG_INFO_BTF=' work/linux73/.config

echo "==> 4. build image (long)"
./build_image.sh --distro bazzite-deck --kernel "$PWD/work/linux73"
IMG=output/ps5-bazzite-deck.img
[ -f "$IMG" ] || { echo "build did not produce $IMG, see build.log"; exit 1; }

echo "==> 5. post-build: cmdline check + Wi-Fi driver option (needs sudo)"
LOOP=$(sudo losetup -fP --show "$IMG")
BOOT=/mnt/ps5boot; ROOT=/mnt/ps5root
sudo mkdir -p "$BOOT" "$ROOT"
cleanup() { sudo umount "$BOOT" "$ROOT" 2>/dev/null || true; sudo losetup -d "$LOOP"; }
trap cleanup EXIT
sudo mount "${LOOP}p2" "$BOOT"      # FAT32 boot
sudo mount "${LOOP}p1" "$ROOT"      # ext4 root
grep -q "lsm=" "$BOOT/cmdline.txt" || sudo sed -i 's/[[:space:]]*$/ lsm=landlock,lockdown,yama,integrity,apparmor,bpf/' "$BOOT/cmdline.txt"
echo "    cmdline: $(cat "$BOOT/cmdline.txt")"
echo "options moal ps_mode=0" | sudo tee "$ROOT/etc/modprobe.d/ps5-iw620.conf" >/dev/null
sync
cleanup; trap - EXIT

echo "==> 6. record exact versions"
BAZZITE_DIGEST="$(docker run --rm quay.io/skopeo/stable inspect docker://ghcr.io/ublue-os/bazzite-deck:stable 2>/dev/null | grep -m1 '"Digest"' | sed 's/.*"sha256:\([0-9a-f]*\)".*/sha256:\1/' || echo unknown)"
cat > output/VERSIONS.md << V
# Versions in release $RELEASE (built $(date -u +%Y-%m-%d))

| Component | Version / commit |
|---|---|
| Bazzite Deck | \`ghcr.io/ublue-os/bazzite-deck:stable\` @ \`$BAZZITE_DIGEST\` |
| Linux kernel | \`$KERNEL_TAG\` (kernel.org stable) |
| PS5 kernel patches | rmuxnet/ps5-linux-patches-1 \`$PATCHES_BRANCH\` @ \`$(git -C work/ps5-linux-patches rev-parse --short HEAD)\` + patches/ps5-btusb-quirks-fix.patch |
| Image builder | ps5-linux/ps5-linux-image @ \`$BUILDER_COMMIT\` + local-changes.diff |
| IW620 Wi-Fi patches | ps5-linux/ps5-linux-mwifiex \`main\` @ \`$(git ls-remote https://github.com/ps5-linux/ps5-linux-mwifiex.git main | cut -c1-7)\` + patches/ps5-iw620-kernel73-compat.patch |
| NXP mwifiex base driver | \`lf-6.18.2_1.0.0\` |
| IW620 firmware | not in the image; pcieuartiw620_combo_v1.bin is staged at boot from the loader's boot partition (ps5-stage-firmware) |
| Kernel config changes | CONFIG_LSM += bpf, CONFIG_DEBUG_INFO_BTF=y |
| cmdline.txt | $(sed 's/__DISTRO__/bazzite-deck/' boot/cmdline.txt) |
V
cat output/VERSIONS.md

echo "==> 7. package as 7-Zip volumes (GitHub caps assets at 2 GB)"
NAME="ps5-bazzite-deck-$RELEASE"
rm -f output/$NAME.img.7z.*
7z a -mx=5 -mmt=on -v1900m "output/$NAME.img.7z" "$IMG" >/dev/null
(cd output && sha256sum $NAME.img.7z.* > "$NAME.sha256")
git diff > output/local-changes.diff
cp "$SRC"/patches/*.patch output/

echo
echo "DONE. Release assets in $REPO/output:"
ls -lh output/$NAME.img.7z.* output/$NAME.sha256 output/VERSIONS.md output/local-changes.diff output/*.patch
echo "Flash output/ps5-bazzite-deck.img (raw) to test. On the PS5: uname -r, systemctl status cardwired, nmcli device"
