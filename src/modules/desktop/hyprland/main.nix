{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true; # Xwayland can be disabled.
  };
}
