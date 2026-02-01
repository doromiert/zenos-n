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
      kbLayout = [
        "pl"
        "ro"
        "ru"
      ];
    };

    zenfs = {
      # will be replaced by the installer ↓
      rootUUID = "f3fbcbcc-1063-426b-a0ab-0ddb7ff9dd76";
      bootUUID = "3296-E5E9";
    };

    desktops.gnome = {
      enable = true;
      tweaks = {
        firefoxTheming.enable = true;
        zenosExtensions.enable = true;
        zenosFonts.enable = true;
        zeroClock.enable = true;
      };
      extraPackages = true;
      excludeGnomeConsole = true;
    };

    modules = {
      gaming = [ "steam" ];
      dev = "*";
    };

    deviceConfigs = {
      tablet.enable = false;
      amd.gpu.rx6900xt.enable = true;
      amd.cpu.r9-9700.enable = true;
      ram.tier32.enable = true;
      hosts.dt2.tweaks.enable = true;
      tweaks.networking.enable = true;
      tweaks.storage = {
        enable = true;
        # options.nvme = false; # (Default)
        # options.sata = true;  # (Default)
      };
    };
  };

  system.stateVersion = "25.11";
}
