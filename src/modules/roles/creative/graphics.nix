# creativity tools
{ pkgs, ... }:
{
  services.flatpak.packages = [

    # --- Graphics & Design ---
    "fr.natron.Natron" # VFX/Compositing
    "io.github.nate_xyz.Paleta" # Color palette tool
    "io.github.nokse22.asciidraw" # ASCII art editor
    "org.gnome.design.AppIconPreview"
    "org.gnome.design.IconLibrary"
    "org.gnome.design.Palette"
    "re.sonny.OhMySVG" # SVG optimizer

  ];
}
