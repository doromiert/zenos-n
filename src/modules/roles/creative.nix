# creativity tools
{ pkgs, ... }:
{
  services.flatpak.packages = [
    # --- Audio & Music ---
    "io.github.revisto.drum-machine" # Drum machine
    "org.ardour.Ardour" # DAW
    "org.audacityteam.Audacity" # Audio editor

    # --- Graphics & Design ---
    "fr.natron.Natron" # VFX/Compositing
    "io.github.nate_xyz.Paleta" # Color palette tool
    "io.github.nokse22.asciidraw" # ASCII art editor
    "org.gnome.design.AppIconPreview"
    "org.gnome.design.IconLibrary"
    "org.gnome.design.Palette"
    "re.sonny.OhMySVG" # SVG optimizer

    # --- Video ---
    "com.obsproject.Studio" # OBS
    "io.github.dzheremi2.lrcmake-gtk" # Lyrics editor (Chronograph)
    "org.gnome.Showtime" # Video player
    "org.kde.kdenlive" # Video editor
  ];
  environment.systemPackages = with pkgs; [
    rnote
    obsidian
    lorem
    eartag
    gaphor
    gapless
  ];
}
