#!/usr/bin/env bash
# Provisioniert Firefox-Einstellungen per policies.json (Linux Mint / apt-Firefox).
# Optional: --snap oder --flatpak fuer andere Installationsarten.
set -euo pipefail

usage() {
    cat <<EOF
Aufruf: sudo $0 [--snap | --flatpak] [--lock] [--dry-run]

  (ohne)      Firefox aus Paketquelle (apt/deb, ESR oder Tarball unter /opt)
  --snap      Firefox als Snap
  --flatpak   Firefox als Flatpak (org.mozilla.firefox)
  --lock      Einstellungen sperren (in der Firefox-Oberflaeche nicht aenderbar)
  --dry-run   Nichts schreiben, nur Zielpfad und Ergebnis anzeigen
EOF
}

MODE=deb
LOCK=0
DRY=0
for arg in "$@"; do
    case "$arg" in
        --snap)    MODE=snap ;;
        --flatpak) MODE=flatpak ;;
        --lock)    LOCK=1 ;;
        --dry-run) DRY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unbekannte Option: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

# Einstellungen, die nicht per Policy gesetzt werden koennen, kommen in user.js
# (Format 'schluessel|wert', Wert als JS-Literal). Aktuell nicht noetig, daher leer;
# user.js wird nur geschrieben, wenn hier etwas steht.
USERJS_PREFS=()

if [ "$DRY" -eq 0 ] && [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

TARGET_USER=${SUDO_USER:-$(id -un)}
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

NO_FIREFOX_HINT="Firefox wurde nicht gefunden.
Fuer andere Installationsarten: $0 --snap (Snap) oder $0 --flatpak (Flatpak)."

POLICIES_FILE=
PROFILE_BASE=
CHOWN_TO=

# Neuere Firefox-Versionen legen Profile unter ~/.config/mozilla/firefox an, aeltere
# unter ~/.mozilla/firefox. Gibt es nur ein Verzeichnis mit profiles.ini, gilt dieses;
# bei beiden gewinnt das mit der zuletzt geaenderten prefs.js (= zuletzt benutzt).
pick_profile_base() {
    local best= best_ts=-1 base ts f
    for base in "$@"; do
        [ -f "$base/profiles.ini" ] || continue
        ts=0
        for f in "$base"/*/prefs.js; do
            [ -f "$f" ] || continue
            t=$(stat -c %Y "$f")
            [ "$t" -gt "$ts" ] && ts=$t
        done
        if [ "$ts" -gt "$best_ts" ]; then best=$base; best_ts=$ts; fi
    done
    echo "${best:-$1}"
}

case "$MODE" in
    deb)
        found=
        for d in /usr/lib/firefox /usr/lib/firefox-esr /opt/firefox; do
            if [ -x "$d/firefox" ] || [ -x "$d/firefox-esr" ]; then found=$d; break; fi
        done
        if [ -z "$found" ]; then
            echo "Fehler: $NO_FIREFOX_HINT" >&2
            exit 1
        fi
        POLICIES_FILE=/etc/firefox/policies/policies.json
        PROFILE_BASE=$(pick_profile_base "$TARGET_HOME/.mozilla/firefox" "$TARGET_HOME/.config/mozilla/firefox")
        ;;
    snap)
        if [ ! -d /snap/firefox ] && [ ! -d /var/snap/firefox ]; then
            echo "Fehler: Kein Firefox-Snap gefunden." >&2
            exit 1
        fi
        POLICIES_FILE=/etc/firefox/policies/policies.json
        PROFILE_BASE=$TARGET_HOME/snap/firefox/common/.mozilla/firefox
        ;;
    flatpak)
        if ! command -v flatpak >/dev/null; then
            echo "Fehler: flatpak ist nicht installiert." >&2
            exit 1
        fi
        arch=$(flatpak --default-arch)
        ext=org.mozilla.firefox.systemconfig/$arch/stable/policies/policies.json
        if flatpak info --system org.mozilla.firefox >/dev/null 2>&1; then
            POLICIES_FILE=/var/lib/flatpak/extension/$ext
        elif sudo -u "$TARGET_USER" flatpak info --user org.mozilla.firefox >/dev/null 2>&1; then
            POLICIES_FILE=$TARGET_HOME/.local/share/flatpak/extension/$ext
            CHOWN_TO=$TARGET_USER
        else
            echo "Fehler: Flatpak org.mozilla.firefox ist nicht installiert." >&2
            exit 1
        fi
        PROFILE_BASE=$TARGET_HOME/.var/app/org.mozilla.firefox/.mozilla/firefox
        ;;
esac

# Vorhandene policies.json einlesen, unsere Eintraege einmischen, fremde behalten.
merged=$(python3 -I - "$POLICIES_FILE" "$LOCK" <<'EOF'
import json, os, sys

path, lock = sys.argv[1], sys.argv[2] == "1"
status = "locked" if lock else "default"

managed = {
    # "Inhalte mit DRM-Kopierschutz wiedergeben" (media.eme.enabled)
    "EncryptedMediaExtensions": {"Enabled": True, "Locked": lock},
    "Preferences": {
        "browser.tabs.unloadOnLowMemory": {"Value": True, "Status": status},
        # "Empfohlene Leistungseinstellungen verwenden": Firefox setzt dabei auch
        # dom.ipc.processCount und layers.acceleration.disabled auf den Standard
        # zurueck, ohne das zeigt die GUI das Haekchen nicht an. "clear" setzt
        # beide bei jedem Start zurueck (Value wird dabei ignoriert). Auch der Schalter
        # selbst wird geleert, sonst ueberstimmt ein von Hand gesetztes false (steht
        # dann als Nutzerwert in prefs.js) den Policy-Standard; mit --lock gesperrt.
        "browser.preferences.defaultPerformanceSettings.enabled": {"Value": True, "Status": "locked" if lock else "clear"},
        "dom.ipc.processCount": {"Value": 8, "Status": "clear"},
        "layers.acceleration.disabled": {"Value": False, "Status": "clear"},
    },
}

doc = {"policies": {}}
if os.path.exists(path):
    with open(path) as f:
        doc = json.load(f)
policies = doc.setdefault("policies", {})
prefs = policies.setdefault("Preferences", {})
prefs.update(managed.pop("Preferences"))
policies.update(managed)
print(json.dumps(doc, indent=2))
EOF
)

echo "Zieldatei: $POLICIES_FILE"
if [ "$DRY" -eq 1 ]; then
    echo "$merged"
    echo "(--dry-run: nichts geschrieben)"
    exit 0
fi

mkdir -p "$(dirname "$POLICIES_FILE")"
if [ -f "$POLICIES_FILE" ] && [ ! -f "$POLICIES_FILE.bak" ]; then
    cp -p "$POLICIES_FILE" "$POLICIES_FILE.bak"
fi
printf '%s\n' "$merged" > "$POLICIES_FILE"
chmod 644 "$POLICIES_FILE"
[ -n "$CHOWN_TO" ] && chown -R "$CHOWN_TO": "$(dirname "$POLICIES_FILE")"
echo "Geschrieben."

# user.js nur, wenn Einstellungen nicht per Policy gehen
if [ "${#USERJS_PREFS[@]}" -gt 0 ]; then
    echo "Profilverzeichnis: $PROFILE_BASE"
    for prefs in "$PROFILE_BASE"/*/prefs.js; do
        [ -f "$prefs" ] || continue
        userjs=$(dirname "$prefs")/user.js
        for entry in "${USERJS_PREFS[@]}"; do
            key=${entry%%|*}
            val=${entry#*|}
            touch "$userjs"
            sed -i "/user_pref(\"$key\"/d" "$userjs"
            echo "user_pref(\"$key\", $val);" >> "$userjs"
        done
        chown "$TARGET_USER": "$userjs"
        echo "user.js aktualisiert: $userjs"
    done
fi

echo "Fertig. Nach einem Firefox-Neustart unter about:policies pruefen."
