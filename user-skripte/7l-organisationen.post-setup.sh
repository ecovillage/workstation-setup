#!/bin/bash

set -e

REPO_DIR="$( cd -- "$(dirname "$0")"/.. >/dev/null 2>&1 ; pwd -P )"

echo "Konfiguriere Firefox vor…"
if sudo [ -d $HOME/.config/mozilla ]
then
  echo "…es besteht schon eine Konfig. Lassen wir mal lieber so."
else
  unzip -q -d $HOME/.config $REPO_DIR/installation_assets/firefox-profil.zip
  echo "…fertig."
fi
