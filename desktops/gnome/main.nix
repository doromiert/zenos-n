{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.zenos.desktop.gnome;
in
{
  # 1. Define Options Dynamically
  options.zenos.desktop.gnome = {
    enable = mkEnableOption "GNOME Desktop Environment";

    config = {
      zenosTheming = mkOption {
        type = types.bool;
        default = true;
        description = "Apply custom ZenOS GTK themes and icons";
      };
      zeroClock = mkOption {
        type = types.bool;
        default = true;
        description = "Show the custom Zero Clock widget (if applicable)";
      };
    };
  };

  # 2. Implement Logic
  config = mkIf cfg.enable {

    # Base GNOME Setup
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      epiphany
    ];

    # Handle Custom Styling (conditionally)
    imports = lib.optional cfg.config.zenosTheming ./zenos-styling.nix;

    # Handle ZeroClock logic
    environment.systemPackages = lib.mkIf cfg.config.zeroClock [
      # pkgs.gnomeExtensions.zero-clock
    ];

    # Fix for GDM in some setups
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;
  };
}
