#!/bin/bash

set -e

if [ $# -ne 0 ]
  then
    echo "Syntax: $0"

    exit 1
fi

REPO_DIR="$( cd -- "$(dirname "$0")"/.. >/dev/null 2>&1 ; pwd -P )"

sudo pwd

echo "Installiere Bing-Hintergründe…" # … während das Skript sich auf die nächste Interaktion mit dir vorbereitet
if [ -d $HOME/.local/share/cinnamon/applets/bing-wallpaper@starcross.dev ]
then
  echo "… nicht mehr nötig."
else
  wget https://cinnamon-spices.linuxmint.com/files/applets/bing-wallpaper@starcross.dev.zip -O /tmp/bing.zip && \
    unzip -q -d $HOME/.local/share/cinnamon/applets /tmp/bing.zip && \
    cinnamon-settings applets & # Per Hand einschalten
fi
echo "…fertig."

echo "Ersetze Standard-Quellen-Repos mit europäischen…"
sudo sed -i 's|http://packages.linuxmint.com|https://ftp.fau.de/mint/packages|g' /etc/apt/sources.list.d/official-package-repositories.list
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://ftp.hosteurope.de/mirror/archive.ubuntu.com|g' /etc/apt/sources.list.d/official-package-repositories.list
echo "…fertig."

echo "GRUB-Customizer-Repo hinzufügen…"
if ! grep -q "^deb .*danielrichter2007/grub-customizer.*" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
    echo "…fertig."
else
    echo "…nicht nötig: Repo existiert bereits."
fi

echo "Lese neue Repos ein…"
sudo apt update
echo "…fertig."

# Snap in Linux Mint erlauben
[ -f /etc/apt/preferences.d/nosnap.pref ] && sudo rm /etc/apt/preferences.d/nosnap.pref

echo "Software-Installationen mit Interaktion auf Kommandozeile zuerst abfrühstücken…"

packages_with_cmd_line_interactive_install=(
  gigolo # schon mal die Konfig vorbereiten, während anderes installiert…
  ttf-mscorefonts-installer
)
sudo apt --yes install  "${packages_with_cmd_line_interactive_install[@]}" || \
  { echo 'Software install failed!'; exit 1; }
  echo "…fertig."

echo "Software-Installationen mit Interaktion über Fokus-nehmende Fenster abfrühstücken…"
# Snap-Installation braucht eine Weile, aber man kann trotzdem schon mal was anderes machen,
# denn sobald acrordrdc gestartet wird, springt einem das Acrobat-Installations-Fenster
# ins Gesicht und man kann dort die nötigen Klicks zum Fortführen machen.
sudo apt --yes install snapd || { echo 'Software install failed!'; exit 1; }
sudo snap install acrordrdc
# Make sure Acroread can access SMB shares and USB drives
sudo snap connect acrordrdc:removable-media
# … and print, if you are lucky:
sudo snap connect acrordrdc:cups-control

acrordrdc & # Das installiert sich mit interaktiver GUI, während der Rest installiert
echo "…fertig."

packages=(
  chromium
  copyq
  firefox
  grub-customizer
  keepassxc
  mint-upgrade-info
  mintupdate
  neovim
  net-tools
  nextcloud-desktop
  openssh-server
  pdfarranger
  printer-driver-cups-pdf
  thunderbird
  thunderbird-locale-de
  tree
  ttf-mscorefonts-installer
  ubuntu-restricted-extras gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good gstreamer1.0-libav
  vlc
)

echo 'Installiere Schriftart Titillium Web…'
if fc-list | grep -iq "Titillium Web"; then
  echo "…nicht mehr nötig."
else
  fonts_file=installation_assets/titillium-web.zip
  [ -f $REPO_DIR/$fonts_file ] || { echo "ERROR: ./$fonts_file nicht gefunden. Schluss."; exit 1; }

  cd /usr/local/share/fonts && {
    sudo unzip -o $REPO_DIR/$fonts_file;
    sudo rm OFL.txt;
  } || { echo 'Schriftart Titillium Web konnte nicht installiert werden'; exit 1; }
  echo "…fertig."

  echo "Schriftarten-Cache neu aufbauen…"
  sudo fc-cache -f
  echo "…fertig."
fi

echo "Compose-Taste auf »Einfügen« legen…"
dconf write /org/cinnamon/desktop/input-sources/xkb-options  "['terminate:ctrl_alt_bksp', 'compose:ins']"
echo "…fertig"
# (Weitere Compose-Tasten-Codes können mit
# grep -E "compose:" /usr/share/X11/xkb/rules/base.lst
# abgefragt werden.)

echo "Restliche Software installieren…"
sudo apt --yes install "${packages[@]}" || { echo 'Software install failed!'; exit 1; }
echo "…fertig."

echo "Speichere PDF-Drucke in Verzeichnis ~/PDF-Drucke…"
sudo sed -i 's|Out ${HOME}/PDF$|Out ${HOME}/PDF-Drucke|' /etc/cups/cups-pdf.conf
echo "…fertig."
echo "CUPS neu starten, damit Änderungen des Druckverzeichnisses wirksam werden…"
sudo service cups restart
echo "…fertig."

# Automatische Kernel-Updates haben Theater gemacht mit plötzlich nicht
# mehr funktionierendem WLAN und Scannern. Brauchen wir nicht mehr.
echo "Sperre Aktualisierungen des laufenden Kernels bei künftigen Auto-Updates…"
sudo apt-mark hold linux-image-$(uname -r)
echo "…fertig."
