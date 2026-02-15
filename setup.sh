#!/bin/bash

set -e

if [ $# -ne 1 ]
  then
    echo "Syntax: $0 ENDUSERNAME"

    exit 1
fi

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
  snapd
  thunderbird
  thunderbird-locale-de
  tree
  ttf-mscorefonts-installer
  vlc
)

working_dir=$(pwd)
enduser=$1

echo 'Installiere Schriftart Titillium Web…'
if fc-list | grep -iq "Titillium Web"; then
  fonts_file=installation_assets/titillium-web.zip
  [ -f $working_dir/$fonts_file ] || { echo "ERROR: ./$fonts_file nicht gefunden. Schluss."; exit 1; }

  cd /usr/local/share/fonts && {
    sudo unzip -o $working_dir/$fonts_file;
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

echo "Ersetze Standard-Quellen-Repos mit europäischen…"
sudo sed -i 's|http://packages.linuxmint.com|https://ftp.fau.de/mint/packages|g' /etc/apt/sources.list.d/official-package-repositories.list
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://ftp.hosteurope.de/mirror/archive.ubuntu.com|g' /etc/apt/sources.list.d/official-package-repositories.list
echo "…fertig."

# Snap in Linux Mint erlauben
[ -f /etc/apt/preferences.d/nosnap.pref ] && sudo rm /etc/apt/preferences.d/nosnap.pref

echo "GRUB-Customizer-Repo hinzufügen…"
sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
echo "…fertig."
echo "Software installieren…"
sudo apt update && apt --yes install "${packages[@]}" || { echo 'Software install failed!'; exit 1; }
echo "… auch mit Snap …"
sudo snap install acrordrdc
# Make sure Acroread can access SMB shares and USB drives
sudo snap connect acrordrdc:removable-media
# … and print, if you are lucky:
sudo snap connect acrordrdc:cups-control
echo "…fertig."

echo "Speichere PDF-Drucke in Verzeichnis ~/PDF-Drucke…"
sudo sed -i 's|Out ${HOME}/PDF$|Out ${HOME}/PDF-Drucke|' /etc/cups/cups-pdf.conf
echo "…fertig."
echo "CUPS neu starten, damit Änderungen des Druckverzeichnisses wirksam werden…"
sudo service cups restart
echo "…fertig."

echo "Installiere Bing-Hintergründe…"
if sudo [ -d /home/$enduser/.local/share/cinnamon/applets/bing-wallpaper@starcross.dev ]
then
  echo "… nicht mehr nötig."
else
  wget https://cinnamon-spices.linuxmint.com/files/applets/bing-wallpaper@starcross.dev.zip -O /tmp/bing.zip
  cd ~/.local/share/cinnamon/applets
  unzip /tmp/bing.zip
fi
echo "…fertig."

echo "Kopiere nacharbeit.readme in $enduser's Verzeichnis…"
sudo cp $working_dir/nacharbeit.readme /home/$enduser/
echo "…fertig."
