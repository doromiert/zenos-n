{ pkgs, ... }:
{
  services.flatpak.packages = [
    # --- Audio & Music ---
    "io.github.revisto.drum-machine" # Drum machine
    "org.ardour.Ardour" # DAW
    "org.audacityteam.Audacity" # Audio editor
  ];
  environment.systemPackages = with pkgs; [
    eartag
    gapless
  ];
}
