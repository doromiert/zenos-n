# @file: modules/gaming/steam.nix
# @brief: Steam gaming configuration for ZenOS.
# @context: gaming configuration
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  # Check if this module is enabled in the config
  cfg = config.zenos.modules.gaming or [ ];
  enabled = (cfg == "*") || (lib.elem "steam" cfg);
in
{
  config = lib.mkIf enabled {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    environment.systemPackages = [ pkgs.steam-tui ];
  };
}
