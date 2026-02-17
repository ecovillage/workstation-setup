#!/bin/bash

set -e

if [[ $# -ne 1 && $# -ne 2 ]]
then
  echo "Syntax: $0 [--encrypt] ENDUSERNAME"

  exit 1
fi

if [ $# -eq 1 ]
then
  enduser=$1
  encrypt=0
else # zwei Argumente
  if [[ $1 != '--encrypt' ]]
  then
    echo 'Bei zwei Argumenten muss das erste --encrypt sein.'

    exit 1
  fi

  enduser=$2
  encrypt=1
fi

REPO_DIR="$( cd -- "$(dirname "$0")"/.. >/dev/null 2>&1 ; pwd -P )"

echo "Erstelle Nutzer $enduser…"
if [ -d /home/$enduser ]
then
  echo "…nicht mehr nötig."
else
  if [ $encrypt ]
  then
    sudo adduser --encrypt-home $enduser
  else
    sudo adduser $enduser
  fi
  echo "…fertig."
fi

echo "Gebe $enduser ähnliche Gruppen wie $USER…"
sudo usermod -a -G $(id -G | tr ' ' '\n' | grep -v "^$(id -g)$" | tr '\n' ','| sed 's/,$//') $enduser
echo "…fertig."

echo "Installiere Rustdesk-Client…"
chmod u+x $REPO_DIR/installation_assets/rustdesklinuxclientinstall.sh
# sudo $REPO_DIR/installation_assets/rustdesklinuxclientinstall.sh
sudo rm "$(pwd)"/rustdesk*.deb # liegt nach der Installation noch rum
echo "…fertig."

echo "Repo für nächsten Schritt nach /tmp kopieren…"
# denn dorthin geht es auch, wenn Heimatverzeichnis des Nutzers verschlüsselt ist
cp -ra $REPO_DIR /tmp
echo "…fertig."
