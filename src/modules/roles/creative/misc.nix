# creativity tools
{ pkgs, ... }:
{
  services.flatpak.packages = [
  ];
  environment.systemPackages = with pkgs; [
    rnote
    obsidian
    lorem
  ];
}
