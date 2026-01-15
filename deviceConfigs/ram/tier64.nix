{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.ram.tier64 or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # ZRAM: At 64GB, we rarely need compression to "expand" capacity.
    # We use it primarily to avoid locking up on rare OOMs.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25; # 16GB of ZRAM is more than enough failsafe.
    };

    boot.kernel.sysctl = {
      # 1. Swappiness: 1
      # Effectively disables swap for daily usage. Only swaps to avoid an OOM crash.
      "vm.swappiness" = 1;

      # 2. VFS Cache Pressure: 30
      # Aggressively cache filesystem metadata (inodes/dentries).
      # Makes file operations (git status, finding files) instant.
      "vm.vfs_cache_pressure" = 30;

      # 3. Max Map Count: 2147483642
      # Essential for compatibility with heavy games/software (Star Citizen, etc.)
      "vm.max_map_count" = 2147483642;

      # 4. Dirty Bytes (Write Caching) - TUNED FOR 64GB
      # Using ratios (percentage) on 64GB can be dangerous (10% = 6.4GB of unsaved data).
      # If that flushes all at once, the system stutters.
      # We switch to fixed byte limits for consistency.

      # Start writing to disk background when dirty data exceeds ~1GB
      "vm.dirty_background_bytes" = 1073741824;

      # Force-pause processes to write data when dirty data exceeds ~4GB
      # This provides a massive buffer for bursts (unzipping, game installs)
      # without risking 6GB+ of data loss or minute-long lockups.
      "vm.dirty_bytes" = 4294967296;
    };
  };
}
