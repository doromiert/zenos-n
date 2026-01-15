{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.tweaks.storage or { enable = false; };
  # Define sub-options for granularity
  opt =
    cfg.options or {
      nvme = false;
      sata = true; # Defaulting to SATA per your current test-drive status
    };
in
{
  config = lib.mkIf (cfg.enable or false) {

    # --- NVMe Optimizations (Kyber / None) ---
    services.udev.extraRules = lib.mkMerge [
      (lib.mkIf (opt.nvme or false) ''
        # NVMe: Use Kyber (low latency) or None (let drive controller handle it)
        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="kyber"
      '')

      # --- SATA/HDD Optimizations (BFQ / MQ-Deadline) ---
      (lib.mkIf (opt.sata or true) ''
        # SSD (SATA): MQ-Deadline is usually best for SATA SSDs
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"

        # HDD (Rotational): BFQ provides best responsiveness during heavy I/O
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      '')
    ];

    # --- Generic IO Tweaks ---
    boot.kernel.sysctl = {
      # IO Affinity (High Perf)
      "fs.aio-max-nr" = 524288;
    };

    # Enable periodic TRIM for SSD health
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
