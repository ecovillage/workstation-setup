# Aufsetzen eines neuen Arbeitsplatzes in Sieben Linden

Fang an mit einer Linux-Installation, während der du zunächst ein Konto `fk-admin` oder `sige-admin` anlegst. Nimm die Passwörter aus der KeepassXC. Nach der Installation logg dich mit dem Nutzer ein und mach

```
wget -O workstation-setup.zip https://github.com/ecovillage/workstation-setup/archive/master.zip && unzip workstation-setup.zip
```
um dieses Repo nach `~/workstation-setup-master` zu klonen. Jetzt kannst du die einzelnen Skripte ausführen, die zum Nutzungsprofil des Geräts passen:

1. Leg einen (oder mehrere) neue Nutzer an:
```
./admin-skripte/7l-organisationen.pre-setup.sh [--encrypt] nutzername
```
Der Nutzer wird mit den gleichen Rechten angelegt wie der ausführende Nutzer, also der Admin. Willst du das nicht, nimm ihm hinterher entsprechende Gruppen (insbesondere `sudo`) weg.

`--encrypt` ist optional, legt den Nutzer mit verschlüsseltem Heimatverzeichnis an und geht bei Linux Mint 22.3 noch, aber bei neueren (zugrundeliegenden) Ubuntu-Versionen nicht mehr. Dort muss man die Pakete nachinstallieren, mit denen man das Heimatverzeichnis verschlüsseln kann, oder Alternativen wählen.

Das Skript installiert außerdem die Fernwartungssoftware `Rustdesk`, die nur im Intranet (VPN geht) funktioniert. Außerdem wird das Repo nach `/tmp` kopiert, von wo du es dir im nächsten Schritt holen musst.

2. Logg dich im neuen Nutzer ein und mach folgendes:
```
cp -r /tmp/workstation-setup-master ~
cd ~/workstation-setup-master
./user-skripte/setup.sh
```

Dieses Skript macht folgendes:
- Umschalten der Paketquellen auf deutsche, um Übersee-Datenverkehr zu reduzieren und die eingestellten Standard-Server zu entlasten
- Installation der in den 7L-Organisationen üblicherweise verwendeten Programme, u.a.
  - KeepassXC
  - Chromium
  - Nextcloud-Client
  - PDF-Arranger
  - Microsoft-Schriftarten (Installation interaktiv) und die Schriftart Titillium, die in den Veröffentlichungen des FK verwendet wird
  - Acrobat Reader, weil manche, insbesondere Behörden-Dokumente nur damit les- bzw. ausfüllbar sind (Installation interaktiv, über Snap und Wine)
  - Cinnamon-Bing-Desklet für täglich wechselnde Schreibtischhintergründe (Installation interaktiv)
  - CopyQ (Macht eine Kopierspeicher-Historie verfügbar)
  - VLC
  - PDF-Drucker, der nach `~/PDF-Drucke` druckt
  - GRUB-Customizer
  - Déjà-Dup für das Einrichten von Backups
  - Neovim, tree, SSH-Server
  - Diverse Medien-Codices
- Legt die [Compose-Taste](https://de.wikipedia.org/wiki/Compose-Taste) auf `Einfügen`.

Es ist so angelegt, dass es die interaktiven Installationsschritte so früh wie möglich durchführt, sodass du dich während der automatisch ablaufenden Rest-Installation schon den Dingen widmen kannst, die in

```
./nacharbeit.readme
```

stehen. Dabei handelt es sich um Schritte, die sich nicht automatisieren lassen.

3. Entscheide, welche Netzlaufwerke der Nutzer bekommen soll:

```
./user-skripte/gigolo.post-setup.sh
```

4. Falls du einen Nutzer mit seinen Daten von Windows zu Linux umziehst, dann sind diese Skripte von Nutzen:

```
./user-skripte/rm-win-files.sh
./user-skripte/convert-windows-data-dirs.sh
```

5. Für Nutzung des Rechners in 7L-Organisationen gibt es ein Skript, dass ein Firefox-Profil mit Lesezeichen und Addons initialisiert (geht z.Z. nicht)

```
./user-skripte/7l-organisationen.post-setup.sh
```

6. Für private Nutzung des Rechners:

```
./user-skripte/privat.post-setup.sh
```
