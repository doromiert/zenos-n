{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.amd.cpu.r9-7900 or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Import generic AMD CPU settings
    zenos.deviceConfigs.amd.cpu.generic.enable = true;

    # Zen 4 specific optimizations
    # Enable AMD P-State EPP driver for better power/performance scaling on Zen 3/4
    boot.kernelParams = [ "amd_pstate=active" ];

    # Ensure high-resolution timers are optimal
    boot.kernelModules = [ "msr" ];
  };
}
