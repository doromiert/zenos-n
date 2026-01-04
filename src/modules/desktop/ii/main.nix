{ pkgs, ... }: 

{
  # --- Part 1: General Desktop Config ---
  
  # Enable Hyprland
  programs.hyprland.enable = true;

  # Required services
  services.geoclue2.enable = true;  # For QtPositioning
  services.networkmanager.enable = true;  # For network management

  # System fonts
  # We use 'with pkgs;' so we don't have to type pkgs.rubik, pkgs.nerd-fonts, etc.
  fonts.packages = with pkgs; [
    rubik
    nerd-fonts.ubuntu
    nerd-fonts.jetbrains-mono
  ];

  # --- Part 2: Illogical Impulse Config ---
  
  programs.illogical-impulse = {
    enable = true;

    # Customize shell tools
    dotfiles = {
      fish.enable = true;     # Fish shell with custom config
      kitty.enable = true;    # Kitty terminal emulator
      starship.enable = true; # Starship prompt
    };
  };
}