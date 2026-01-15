{
  config,
  lib,
  modulesPath,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.qemu-guest or { };
in
{
  options.zenos.deviceConfigs.qemu-guest = {
    enable = lib.mkEnableOption "QEMU Guest Agent & Drivers";
  };

  config = lib.mkIf cfg.enable {
    # Import the standard QEMU guest profile from nixpkgs
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true; # Essential for copy/paste between host and VM
  };
}
