#!/bin/bash

echo "Verschiebe von Desktop/* nach Schreibtisch…"
if [ -d ./Desktop ]
then
	mv Desktop/* Schreibtisch/
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
echo "Verschiebe von Documents/* nach Dokumente…"
if [ -d ./Documents ]
then
	mv Documents/* Dokumente/
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
echo "Verschiebe von Music/* nach Musik…"
if [ -d ./Music ]
then
	mv Music/* Musik/
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
echo "Verschiebe von Pictures/* nach Bilder…"
if [ -d ./Pictures ]
then
	mv Pictures/* Bilder/
	echo "… fertig."
else
	echo "…nicht gefunden."
fi
# echo "Entferne Desktop, Documents, Music und Pictures…"
# rm -fr Desktop/ Documents/ Music Pictures
# echo "…fertig."
