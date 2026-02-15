#!/bin/bash

set -e

working_dir=$(pwd)
enduser=$1

echo "Erstelle Nutzer $enduser…"
if [ -d /home/$enduser ]
then
  echo "…nicht mehr nötig."
else
  sudo adduser --encrypt-home $enduser
  echo "…fertig."
  echo "Kopiere gigolo.post-setup.sh in $enduser's Verzeichnis…"
  sudo cp $working_dir/gigolo.post-setup.sh /home/$enduser/
  sudo chown $enduser:$enduser /home/$enduser/gigolo.post-setup.sh
  sudo chmod u+x /home/$enduser/gigolo.post-setup.sh
  echo "…fertig. Das musst später noch ausführen und dann löschen!"
fi

echo "Gebe $enduser ähnliche Gruppen wie $USER…"
sudo usermod -a -G $(id -G | tr ' ' '\n' | grep -v "^$(id -g)$" | tr '\n' ','| sed 's/,$//') $enduser
echo "…fertig."

echo "Install Rustdesk-Client…"
chmod u+x $working_dir/installation_assets/rustdesklinuxclientinstall.sh
sudo $working_dir/installation_assets/rustdesklinuxclientinstall.sh
echo "…fertig."

echo "Konfiguriere Firefox vor…"
if sudo [ -d /home/$enduser/.mozilla ]
then
  echo "…es besteht schon eine Konfig. Lassen wir mal lieber so."
else
  # Firefox muss sich erst mal ein Profilverzeichnis anlegen mit dem von dieser
  # Installation individuell benannten (Hash-) Verzeichnisnamen.
  firefox &
  sleep 2
  killall firefox-bin
  # In diesem individuell benannten Verzeichnis ersetzen wir nun die Dateien
  rm -fr /home/$enduser/.mozilla/firefox/*.*-*/*
  sudo unzip -q -d /home/$enduser/.mozilla/firefox/*.*-*/ $working_dir/installation_assets/firefox-profile-files.zip
  sudo chown -R $enduser:$enduser /home/$enduser/.mozilla
  echo "…fertig."
fi
