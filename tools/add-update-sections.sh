#!/bin/bash
# Adds/refreshes the "Updating from ..." section in the GitHub release notes of v1.0.3-v1.0.6.
#   bash tools/add-update-sections.sh
set -euo pipefail
R=VivaLaVent/ps5-bazzite-deck; SRC=$(cd "$(dirname "$0")/.." && pwd)
for T in v1.0.3 v1.0.4 v1.0.5 v1.0.6; do
  S="$SRC/docs/update-sections/$T.md"; [ -f "$S" ] || continue
  gh release view "$T" --repo "$R" --json body -q .body > /tmp/body-$T.md || { echo "skip $T (no release)"; continue; }
  awk -v sec="$S" '
    BEGIN { while ((getline l < sec) > 0) s = s l "\n"; s = "<!-- update-section -->\n" s "<!-- /update-section -->\n\n" }
    /^<!-- update-section -->/ { skip=1; next }
    /^<!-- \/update-section -->/ { skip=0; next }
    skip { next }
    /^## Hotfix for v1.0.2 users/ { drop=1; next }
    /^### Already on v1.0.4\? No need to reflash/ { drop=1; next }
    drop && (/^## / || /^\*\*From/) { drop=0 }
    drop { next }
    /^Coming from v1.0.5 or older: this needs a reflash/ { next }
    /^Already on v1.0.5 or v1.0.4\? This one needs a reflash/ { next }
    !done && (/^## Known issues/ || /^## Versions/) { printf "%s", s; done=1 }
    { print }
    END { if (!done) printf "\n%s", s }
  ' /tmp/body-$T.md > /tmp/new-$T.md
  gh release edit "$T" --repo "$R" --notes-file /tmp/new-$T.md && echo "updated $T"
done
