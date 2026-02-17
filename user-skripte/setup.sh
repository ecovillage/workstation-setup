#!/bin/bash

set -e

if [ $# -ne 0 ]
  then
    echo "Syntax: $0"

    exit 1
fi

REPO_DIR="$( cd -- "$(dirname "$0")"/.. >/dev/null 2>&1 ; pwd -P )"

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

echo "Interaktive Software-Installationen zuerst anstoßen…"
sudo apt --yes install ttf-mscorefonts-installer snapd || { echo 'Software install failed!'; exit 1; }

echo "… auch mit Snap …"
sudo snap install acrordrdc
# Make sure Acroread can access SMB shares and USB drives
sudo snap connect acrordrdc:removable-media
# … and print, if you are lucky:
sudo snap connect acrordrdc:cups-control
echo "…fertig."

acrordrdc & # Das installiert sich mit interaktiver GUI, während der Rest installiert

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
  vlc
)

echo 'Installiere Schriftart Titillium Web…'
if fc-list | grep -iq "Titillium Web"; then
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
else
  echo "…nicht mehr nötig."
fi

echo "Compose-Taste auf »Einfügen« legen…"
dconf write /org/cinnamon/desktop/input-sources/xkb-options  "['terminate:ctrl_alt_bksp', 'compose:ins']"
echo "…fertig"
# (Weitere Compose-Tasten-Codes können mit
# grep -E "compose:" /usr/share/X11/xkb/rules/base.lst
# abgefragt werden.)

echo "Restliche Software installieren…"
apt --yes install "${packages[@]}" || { echo 'Software install failed!'; exit 1; }
echo "…fertig."

echo "Speichere PDF-Drucke in Verzeichnis ~/PDF-Drucke…"
sudo sed -i 's|Out ${HOME}/PDF$|Out ${HOME}/PDF-Drucke|' /etc/cups/cups-pdf.conf
echo "…fertig."
echo "CUPS neu starten, damit Änderungen des Druckverzeichnisses wirksam werden…"
sudo service cups restart
echo "…fertig."

echo "Installiere Bing-Hintergründe…"
if sudo [ -d $HOME/.local/share/cinnamon/applets/bing-wallpaper@starcross.dev ]
then
  echo "… nicht mehr nötig."
else
  wget https://cinnamon-spices.linuxmint.com/files/applets/bing-wallpaper@starcross.dev.zip -O /tmp/bing.zip && \
  unzip -q -d $HOME/.local/share/cinnamon/applets /tmp/bing.zip
fi
echo "…fertig."
