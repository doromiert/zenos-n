# @file: hosts/doromi-tul-2/main.nix
# @brief: Host configuration for doromi tul 2.
# @context: host configuration
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # ./hardware-configuration.nix
    ./placeholder.nix
  ];

  zenos = {
    deviceIcon = "desktop";
    prettyName = "doromi tul 2";

    users = [
      "doromiert"
      "hubi"
    ];
    admin = "doromiert";

    locale = {
      timeZone = "Europe/Warsaw";
      language = "en_US.UTF-8";
      defaultLocale = "pl_PL.UTF-8";
      kbLayout = "pl";
    };

    zenfs = {
      # will be replaced by the installer ↓
      rootUUID = "f3fbcbcc-1063-426b-a0ab-0ddb7ff9dd76";
      bootUUID = "3296-E5E9";
    };

    desktop = {
      gnome = {
        enable = true;
        config = {
          zenosTheming = true;
          zeroClock = true;
        };
      };
    };

    modules = {
      gaming = [ "steam" ];
      dev = "*";
      # Note: 'desktops' is removed from here
    };

    deviceConfigs = {
      tablet.enable = false;
      # graphics.amd.enable = true;
    };
  };

  system.stateVersion = "25.11";
}
