#!/bin/bash

set -e

REPO_DIR="$(
  cd -- "$(dirname "$0")"/.. >/dev/null 2>&1
  pwd -P
)"

echo "Stopping snapd…"
sudo systemctl stop snapd
echo "…fertig."
echo "Deinstalliere snapd…"
sudo apt purge snapd
echo "…fertig."

echo "Entferne snap-Verzeichnis in Homeverzeichnissen"
sudo rm -fr /home/*/snap

# Snap in Linux Mint wieder verbieten, falls mal erlaubt war
[ -f /etc/apt/preferences.d/nosnap.pref ] || sudo cp "$REPO_DIR/installation_assets/nosnap.pref" /etc/apt/preferences.d
