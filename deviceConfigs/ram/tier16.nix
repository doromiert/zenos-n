{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.ram.tier16 or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Standard ZRAM setup
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100; # 1:1 Swap to RAM ratio is safe here
    };

    boot.kernel.sysctl = {
      # Balanced swappiness (Default is 60)
      # Slightly prefer physical RAM, but don't fear swap.
      "vm.swappiness" = 60;

      # Standard map count (still boosted for compatibility, just in case)
      "vm.max_map_count" = 1048576;

      # ZRAM Optimization: Disable page-cluster
      # ZRAM is CPU-bound, not disk-bound. Read 1 page at a time, not clusters.
      "vm.page-cluster" = 0;
    };
  };
}
