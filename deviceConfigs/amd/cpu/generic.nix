{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.amd.cpu.generic or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Enable KVM support by default for AMD CPUs
    boot.kernelModules = [ "kvm-amd" ];
  };
}
