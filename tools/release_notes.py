#!/usr/bin/env python3
"""Render the GitHub release notes of v1.0.3 and newer in one common structure and update them.

  python3 tools/release_notes.py            # render to /tmp/release-notes/<tag>.md and update GitHub
  python3 tools/release_notes.py --dry-run  # render only

Per release it combines: the release's
"What's new" / "Known issues" (docs/release-notes/<tag>.md), its in-place update section
(docs/update-sections/<tag>.md), the common settings/install/known-issues blocks below, the release's
own VERSIONS.md (downloaded from the release) and its actual asset list.
"""
import json, os, re, subprocess, sys, tempfile

REPO = "VivaLaVent/ps5-bazzite-deck"
def _tags():
    d = os.path.join(SRC, "docs/release-notes")
    tags = [f[:-3] for f in os.listdir(d) if re.fullmatch(r"v\d+\.\d+\.\d+\.md", f)]
    return sorted(tags, key=lambda t: tuple(int(x) for x in t[1:].split(".")))

DISCORD = "https://discord.gg/qGcuTgBBYU"
KOFI = "https://ko-fi.com/vivalavent"
SRC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = "/tmp/release-notes"

SETTINGS = """## Before and after the first boot
- **PS5 settings, before running the loader:** `Enable HDMI Device Link` **off** (Settings → HDMI) and `Supply Power to USB Ports` **Always** (Settings → System → Power Saving → Features Available in Rest Mode).
- **In Bazzite, on first boot:** turn **HDR off** and set **RGB range** to **Full**, in both Gaming Mode and desktop mode.
- The default password is `ps5`.
"""
COMMON_ISSUES = ["First boot is slow; the screen can stay black for a few minutes.",
                 "Which firmware versions are supported depends on **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases): see its releases."]


def gh(*args, capture=True):
    r = subprocess.run(["gh", *args], capture_output=capture, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout


def section(text, name):
    m = re.search(rf"^## {re.escape(name)}\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    return m.group(1).strip() if m else ""


def files_section(tag, assets):
    base = f"ps5-bazzite-deck-{tag}"
    lines, used = [], set()
    vols = sorted(a for a in assets if re.fullmatch(rf"{re.escape(base)}\.img\.7z\.\d{{3}}", a))
    if vols:
        lines.append(f"- `{base}.img.7z.{'/.'.join(v.rsplit('.', 1)[1] for v in vols)}` – the image as a 7-Zip multi-volume archive (extract from `.001`)")
        used.update(vols)
    for name, desc in [(f"{base}.sha256", "checksums of the image volumes"),
                       (f"{base}-update.tar.xz", "in-place update bundle (see Updating)"),
                       (f"{base}-update.tar.xz.sha256", "its checksum"),
                       ("btusb.ko", "Bluetooth module for v1.0.2 users (see Updating)"),
                       ("VERSIONS.md", "exact upstream versions"),
                       ("local-changes.diff", "changes applied to the upstream image builder")]:
        if name in assets:
            lines.append(f"- `{name}` – {desc}")
            used.add(name)
    patches = sorted(a for a in assets if a.endswith(".patch"))
    if patches:
        lines.append(f"- `*.patch` ({len(patches)}) – kernel and driver patches used in this build")
        used.update(patches)
    lines += [f"- `{a}`" for a in assets if a not in used]
    return "## Files\n" + "\n".join(lines) + "\n"


def render(tag, tmp):
    info = json.loads(gh("release", "view", tag, "--repo", REPO, "--json", "body,assets"))
    assets = [a["name"] for a in info["assets"]]
    per = open(os.path.join(SRC, "docs/release-notes", f"{tag}.md"), encoding="utf-8").read()
    upd = open(os.path.join(SRC, "docs/update-sections", f"{tag}.md"), encoding="utf-8").read().strip()
    versions = ""
    if "VERSIONS.md" in assets:
        gh("release", "download", tag, "--repo", REPO, "-p", "VERSIONS.md", "-D", tmp, "--clobber")
        v = open(os.path.join(tmp, "VERSIONS.md"), encoding="utf-8").read().split("\n")
        versions = "## Versions\n" + "\n".join(l for l in v if l.startswith("|")) + "\n"
    issues = [l[2:] for l in section(per, "Known issues").splitlines() if l.startswith("- ")]
    install = f"""## Install (new)
1. Download all `.7z.00*` files into one folder.
2. Open `ps5-bazzite-deck-{tag}.img.7z.001` with 7-Zip (Windows) / Keka (macOS) / `7z x` (Linux) → you get `ps5-bazzite-deck.img`.
3. Flash it to a 32 GB+ USB drive or SSD with Rufus (or `dd` on Linux) and boot with the loader.
"""
    parts = ["## What's new\n" + section(per, "What's new") + "\n", upd + "\n", SETTINGS, install,
             "## Known issues\n" + "\n".join(f"- {i}" for i in COMMON_ISSUES + issues) + "\n",
             versions, files_section(tag, assets), f"---\nQuestions, bug reports, test results: **Discord {DISCORD}**\nLike the project? Support it on **Ko-fi {KOFI}**\n"]
    return "\n".join(p for p in parts if p)


def main():
    dry = "--dry-run" in sys.argv
    os.makedirs(OUT, exist_ok=True)
    for tag in _tags():
        try:
            with tempfile.TemporaryDirectory() as tmp:
                notes = render(tag, tmp)
        except RuntimeError as e:
            print(f"skip {tag}: {e}")
            continue
        path = os.path.join(OUT, f"{tag}.md")
        open(path, "w", encoding="utf-8").write(notes)
        if dry:
            print(f"rendered {tag} -> {path}")
        else:
            gh("release", "edit", tag, "--repo", REPO, "--notes-file", path)
            print(f"updated {tag}")


if __name__ == "__main__":
    main()
