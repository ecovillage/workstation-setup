#!/bin/bash

set -e

cd $HOME

echo "Verschiebe von Desktop/* nach Schreibtisch…"
if [ -d ./Desktop ]
then
	mv Desktop/* Schreibtisch/
  rm -fr Desktop
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
echo "Verschiebe von Documents/* nach Dokumente…"
if [ -d ./Documents ]
then
	mv Documents/* Dokumente/
  rm -fr Documents
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
echo "Verschiebe von Music/* nach Musik…"
if [ -d ./Music ]
then
	mv Music/* Musik/
  rm -fr Music
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
echo "Verschiebe von Pictures/* nach Bilder…"
if [ -d ./Pictures ]
then
	mv Pictures/* Bilder/
  rm -fr Pictures
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
