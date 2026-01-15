# @file: deviceConfigs/tablet.nix
# @brief: Tablet-specific configuration for ZenOS.
# @context: tablet configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.deviceConfigs.tablet or { };
in
{
  options.deviceConfigs.tablet = {
    enable = lib.mkEnableOption "Tablet specific configurations";
  };

  config = lib.mkIf cfg.enable {
    # Tablet specific settings
    services.xserver.wacom.enable = true;
    environment.variables.QT_QPA_PLATFORM = "wayland";

    # Auto-rotate script or similar
    environment.systemPackages = [ pkgs.iio-sensor-proxy ];
  };
}
