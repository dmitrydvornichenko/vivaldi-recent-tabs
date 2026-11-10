#!/bin/sh
# macOS / Linux installer for recent-tabs.js.
#   ./install.sh       install (or update) the mod
#   ./install.sh -u    uninstall
# Re-run after every Vivaldi update: updates overwrite window.html.
# Changes take effect after Vivaldi restart.
#
# Set VIVALDI_UI_DIR to point at a specific resources/vivaldi folder instead of auto-detection.
# Re-runs itself with sudo when the Vivaldi folder is not writable (e.g. /opt on Linux).

set -eu

MOD=recent-tabs.js
TAG="<script src=\"$MOD\"></script>"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

UNINSTALL=0
case "${1:-}" in
  -u|--uninstall) UNINSTALL=1 ;;
  "") ;;
  *) echo "usage: $0 [-u]" >&2; exit 2 ;;
esac

# Sort version-like paths by their last path component numerically and print the newest.
newest() {
  awk -F/ '{ print $NF "\t" $0 }' | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | tail -n 1 | cut -f2-
}

find_ui_dir() {
  if [ -n "${VIVALDI_UI_DIR:-}" ]; then
    echo "$VIVALDI_UI_DIR"; return
  fi
  case "$(uname -s)" in
    Darwin)
      for app in "/Applications/Vivaldi.app" "$HOME/Applications/Vivaldi.app" \
                 "/Applications/Vivaldi Snapshot.app" "$HOME/Applications/Vivaldi Snapshot.app"; do
        vdir="$app/Contents/Frameworks/Vivaldi Framework.framework/Versions"
        [ -d "$vdir" ] || continue
        latest=$(for d in "$vdir"/*/; do
                   d=${d%/}
                   [ -f "$d/Resources/vivaldi/window.html" ] && echo "$d"
                 done | newest)
        if [ -n "$latest" ]; then echo "$latest/Resources/vivaldi"; return; fi
      done
      ;;
    *)
      for d in /opt/vivaldi/resources/vivaldi /opt/vivaldi-snapshot/resources/vivaldi \
               /usr/share/vivaldi/resources/vivaldi /usr/lib/vivaldi/resources/vivaldi; do
        if [ -f "$d/window.html" ]; then echo "$d"; return; fi
      done
      ;;
  esac
}

UI_DIR=$(find_ui_dir)
if [ -z "$UI_DIR" ] || [ ! -f "$UI_DIR/window.html" ]; then
  echo "Vivaldi installation not found. Set VIVALDI_UI_DIR to its resources/vivaldi folder." >&2
  echo "(Flatpak and Snap installs are read-only and can't be modded this way.)" >&2
  exit 1
fi
HTML="$UI_DIR/window.html"

if [ ! -w "$UI_DIR" ] || [ ! -w "$HTML" ]; then
  if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    echo "No write access to $UI_DIR, re-running with sudo..."
    exec sudo VIVALDI_UI_DIR="$UI_DIR" sh "$0" "$@"
  fi
  echo "No write access to $UI_DIR." >&2
  exit 1
fi

echo "Vivaldi UI folder: $UI_DIR"

# Rewrite window.html in place (keeps owner and permissions).
rewrite() {
  tmp=$(mktemp)
  "$@" < "$HTML" > "$tmp"
  cat "$tmp" > "$HTML"
  rm -f "$tmp"
}

if [ "$UNINSTALL" -eq 1 ]; then
  if grep -qF "$TAG" "$HTML"; then
    rewrite grep -vF "$TAG"
    echo "  removed script tag from window.html"
  else
    echo "  window.html is not patched"
  fi
  if [ -f "$UI_DIR/$MOD" ]; then rm -f "$UI_DIR/$MOD"; echo "  deleted $MOD"; fi
  echo "Done. Restart Vivaldi."
  exit 0
fi

cp "$SCRIPT_DIR/$MOD" "$UI_DIR/$MOD"
echo "  copied $MOD"

if grep -qF "$TAG" "$HTML"; then
  echo "  window.html already patched"
else
  grep -q "</body>" "$HTML" || { echo "No </body> found in window.html - format changed, patch manually." >&2; exit 1; }
  if [ ! -f "$HTML.bak" ]; then cp -p "$HTML" "$HTML.bak"; echo "  backup: window.html.bak"; fi
  rewrite awk -v tag="$TAG" '!done && /<\/body>/ { print "  " tag; done = 1 } { print }'
  echo "  window.html patched"
fi

echo "Done. Restart Vivaldi."
