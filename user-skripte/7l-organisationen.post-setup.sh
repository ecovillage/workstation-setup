#!/bin/bash

set -e

REPO_DIR="$( cd -- "$(dirname "$0")"/.. >/dev/null 2>&1 ; pwd -P )"

echo "Konfiguriere Firefox vor…"
if sudo [ -d $HOME/.config/mozilla ]
then
  echo "…es besteht schon eine Konfig. Lassen wir mal lieber so."
else
  wget -O /tmp/firefox-profil.zip http://192.168.1.127/firefox-profil.zip
  unzip -q -d $HOME/.config /tmp/firefox-profil.zip
  echo "…fertig."
fi
