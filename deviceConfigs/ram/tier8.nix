{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.ram.tier8-ddr4 or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Aggressive ZRAM
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100; # Give us effectively ~12-14GB usable space
      priority = 100;
    };

    boot.kernel.sysctl = {
      # Swappiness: 80
      # Aggressively swap inactive pages to ZRAM to keep the active app in Physical RAM.
      "vm.swappiness" = 80;

      # Watermark Scale
      # Increase granularity of memory reclamation to prevent heavy stutters
      "vm.watermark_scale_factor" = 125;

      # ZRAM Optimization
      "vm.page-cluster" = 0;
    };

    # Enable Multi-Gen LRU (MGLRU) if kernel supports it (Standard in 6.1+)
    # Greatly improves performance under memory pressure on low-RAM devices.
    # (Checking if the file exists prevents errors on older kernels)
    systemd.tmpfiles.rules = [
      "w /sys/kernel/mm/lru_gen/enabled - - - - y"
    ];
  };
}
