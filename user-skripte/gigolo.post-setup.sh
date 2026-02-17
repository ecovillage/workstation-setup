#!/bin/bash

if ! command -v gigolo &> /dev/null; then sudo apt update && sudo apt install -y gigolo; fi

REPO_DIR="$( cd -- "$(dirname "$0")"/.. >/dev/null 2>&1 ; pwd -P )"
# Verzeichnis, das die Dateien enthält
TEMPLATES_DIR="$REPO_DIR/installation_assets/gigolo_bookmarks"
# Zieldatei
GIGOLO_CONFIG_DIR="$HOME/.config/gigolo"
mkdir -p $GIGOLO_CONFIG_DIR
cp $REPO_DIR/installation_assets/gigolo_config $GIGOLO_CONFIG_DIR/config

cp ./installation_assets/gigolo.desktop $HOME/.config/autostart

# Überprüfen, ob das Verzeichnis existiert
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "Das Verzeichnis '$TEMPLATES_DIR' existiert nicht."
    exit 1
fi

# Alle Dateien im Verzeichnis auflisten und in alphabetischer Reihenfolge sortieren
files=($(ls "$TEMPLATES_DIR" | sort))

# Über die Dateien iterieren
echo "SMB-Laufwerke beim Start einzubinden:"
for file in "${files[@]}"; do
  echo $file
done

echo ""
echo "j oder n:"

for file in "${files[@]}"; do
    # Überprüfen, ob es sich um eine reguläre Datei handelt
    if [ -f "$TEMPLATES_DIR/$file" ]; then
        echo "$file"
        read -r response

        # Antwort prüfen
        if [[ "$response" =~ ^[Jj]$ ]]; then
            cat "$TEMPLATES_DIR/$file" >> "$GIGOLO_CONFIG_DIR/bookmarks"
            echo "v/"
        fi
    fi
done
