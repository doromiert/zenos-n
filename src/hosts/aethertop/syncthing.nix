# doromi-tul-2-specific syncthing settings
{
  config,
  lib,
  ...
}:
let
  # 1. Grab the list of devices that actually exist in the final config
  #    (This automatically excludes the ones we filtered out in the previous file)
  enabledDevices = builtins.attrNames config.services.syncthing.settings.devices;

  # 2. Define a helper: Only keep devices that are in both lists
  active = list: lib.intersectLists list enabledDevices;
in

{
  services.syncthing = {
    enable = true;
    user = config.mainUser; # Dynamically use the mainUser defined in flake.nix
    group = "users";

    # Using config.users.users.${config.mainUser}.home is safe here as long as config is in scope
    dataDir = "${config.users.users.${config.mainUser}.home}/.local/share/syncthing";
    configDir = "${config.users.users.${config.mainUser}.home}/.config/syncthing";

    settings.folders = {

    };
  };
}
