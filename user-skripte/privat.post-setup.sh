packages=(
  spotify-client
  flatpak
  ubuntu-restricted-extras gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good gstreamer1.0-libav
)

# Add repo for Spotify
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

echo "Software installieren…"
sudo apt --yes install "${packages[@]}" || { echo 'Software install failed!'; exit 1; }
echo "… auch mit Flatpak …"
flatpak install -y \
  org.telegram.desktop \
  com.ktechpit.whatsie \
  org.signal.Signal \
  de.mediathekview.MediathekView
echo "…fertig."
