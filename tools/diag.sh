#!/bin/bash
# PS5 Bazzite Deck diagnostics: collects what we need for display / HDMI reports into one file.
# Run on the PS5 (terminal or SSH):
#   curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/diag.sh | bash
# Then send the file it names (or its output) in Discord.
OUT=~/ps5-diag-$(date +%Y%m%d-%H%M%S).txt
echo "PS5 Bazzite Deck diagnostics (asks for your password, default ps5, for the display details)"
sudo -v || { echo "sudo failed"; exit 1; }
{
  echo "=== system"
  echo "version: $(cat /etc/ps5-bazzite-deck-version 2>/dev/null || echo unknown)"
  echo "kernel:  $(uname -r) $(uname -v)"
  echo "cmdline: $(cat /proc/cmdline)"
  echo "session: ${XDG_CURRENT_DESKTOP:-none} / $(pgrep -x gamescope >/dev/null && echo 'gamescope running' || echo 'no gamescope') / $(pgrep -x kwin_wayland >/dev/null && echo 'kwin running' || echo 'no kwin')"
  echo
  echo "=== display chip and GPU"
  dmesg | grep -E "HDMI IC Type|active_cu_number"
  echo
  echo "=== HDMI events (last 40)"
  dmesg | grep -i -E "got real edid|re-arm|different display|picture up|syncs moved|added 2560|1440p60|link training|enabling link|scrambl" | tail -40
  echo
  echo "=== active mode and output"
  sudo sh -c 'cat /sys/kernel/debug/dri/*/state' 2>/dev/null | grep -E 'mode: "|max_requested_bpc|colorspace' | head -10
  sudo sh -c 'cat /sys/kernel/debug/dri/*/DP-1/output_bpc' 2>/dev/null
  echo
  echo "=== modes offered by the driver"
  cat /sys/class/drm/card0-DP-1/modes 2>/dev/null | sort | uniq -c
  echo
  echo "=== EDID (base64)"
  base64 -w0 /sys/class/drm/card0-DP-1/edid 2>/dev/null; echo
} > "$OUT" 2>&1
cat "$OUT"
echo
echo "Saved as $OUT - send this file (or the text above) in Discord."
