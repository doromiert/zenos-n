{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.ram.tier32 or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # ZRAM: Use it, but less aggressively since we have plenty of physical RAM.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50; # 16GB ZRAM is plenty
    };

    boot.kernel.sysctl = {
      # 1. Swappiness: 10
      # We have 32GB. Only swap if absolutely necessary to avoid disk I/O.
      "vm.swappiness" = 10;

      # 2. VFS Cache Pressure: 50 (Default 100)
      # Keep directory/inode objects in memory longer. Improves file browsing/indexing speed.
      "vm.vfs_cache_pressure" = 50;

      # 3. Max Map Count: 2147483642
      # CRITICAL for Steam Play / Proton and games like Star Citizen or Hogwarts Legacy
      # which crash with the default low limit (65530).
      "vm.max_map_count" = 2147483642;

      # 4. Dirty Ratio (Write Caching)
      # Allow more data to be cached in RAM before writing to disk (smoother burst performance)
      # But don't let it get too huge to avoid massive stutter when it finally syncs.
      "vm.dirty_ratio" = 10; # Max 10% of RAM for dirty pages (3.2GB)
      "vm.dirty_background_ratio" = 5; # Start writing at 5% (1.6GB)
    };
  };
}
