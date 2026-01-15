# creativity tools
{ ... }:
{
  services.flatpak.packages = [
    # --- Video ---
    "com.obsproject.Studio" # OBS
    "io.github.dzheremi2.lrcmake-gtk" # Lyrics editor (Chronograph)
    "org.gnome.Showtime" # Video player
    "org.kde.kdenlive" # Video editor
  ];
}
