#!/bin/bash

cd $HOME

find . -name desktop.ini -exec rm {} \;
find . -name *.lnk -exec rm {} \;
find Downloads/ -name *.msi -exec rm {} \;
find Downloads/ -name *.exe -exec rm {} \;
rm -r Dokumente/Eigene\ Bilder
rm -r Dokumente/Eigene\ Musik
rm -r Dokumente/Eigene\ Videos
