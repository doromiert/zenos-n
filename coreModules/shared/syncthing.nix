{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.zenos.services.syncthing;

  # --- Path Logic ---
  # Path relative to this module file.
  # Adjust the "../.." depth if you move this module deeper into your directory structure.
  devicesPath = ../../syncthingDevices;

  # --- Device Loading Logic ---
  # 1. Check if directory exists
  deviceFiles = if builtins.pathExists devicesPath then builtins.readDir devicesPath else { };

  # 2. Filter for .nix files
  deviceNixFiles = filterAttrs (name: type: type == "regular" && hasSuffix ".nix" name) deviceFiles;

  # 3. Import each file (expects each file to return an attribute set of devices)
  #    e.g. { "device_id" = { ... }; }
  loadedDevices = mapAttrsToList (name: _: import (devicesPath + "/${name}")) deviceNixFiles;

  # 4. Merge all loaded devices into one set
  allDevices = foldl' (acc: set: acc // set) { } loadedDevices;

  # 5. Filter out placeholders (preserved from your snippet)
  finalDevices = filterAttrs (n: v: v.id != "placeholder") allDevices;
in
{
  meta = {
    description = "Configures Syncthing and dynamically loads device definitions";
    longDescription = ''
      This module enables Syncthing and sets standard ZenOS defaults (overriding GUI controls).

      It automatically scans the `syncthingDevices` directory (in the root of the ZenOS config)
      for `.nix` files. Each file in that directory should return an attribute set of 
      Syncthing device definitions.

      These are merged into `services.syncthing.settings.devices` and filtered to remove
      any devices with `id = "placeholder"`.
    '';
    maintainers = with lib.maintainers; [ doromiert ];
    license = lib.licenses.napl;
    platforms = lib.platforms.zenos;
  };

  options.zenos.services.syncthing = {
    enable = mkEnableOption "ZenOS Syncthing Configuration";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      # Force Nix configuration over GUI
      overrideDevices = true;
      overrideFolders = true;

      openDefaultPorts = true;

      settings = {
        devices = finalDevices;
      };
    };
  };
}
