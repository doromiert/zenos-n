{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.ram.tier4 or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Survival ZRAM
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      # Overcommit ZRAM to emulate having more space (compression ratio dependent)
      memoryPercent = 150;
    };

    # Early Out-Of-Memory Killer
    # On 4GB, the kernel OOM killer is too slow (system freezes).
    # earlyoom kills the largest browser tab when RAM < 5% free.
    services.earlyoom = {
      enable = true;
      enableNotifications = true;
      freeMemThreshold = 5; # Kill when < 5% RAM free
      freeSwapThreshold = 5;
    };

    boot.kernel.sysctl = {
      # Swappiness: 100
      # Treat ZRAM as main memory. Everything that can be compressed, should be.
      "vm.swappiness" = 100;

      # ZRAM Optimization
      "vm.page-cluster" = 0;
    };
  };
}
