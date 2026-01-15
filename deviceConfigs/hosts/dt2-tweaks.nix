{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.hosts.dt2.tweaks or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {

    # --- 1. Kernel Latency & Preemption (Specific to DT2 Hardware) ---
    boot.kernelParams = [
      "nmi_watchdog=0" # Disable NMI watchdog for slight perf gain
      "split_lock_detect=off" # Prevent gaming stutters in some titles

      # Real-time-ish constraints
      "preempt=full" # Force full kernel preemption (Low Latency Desktop)
      "threadirqs" # Threaded IRQ handling

      # [CRITICAL] Fix for AMDGPU Ring Timeouts & Mutter Crashes on 6900 XT
      "amdgpu.mcbp=0"
    ];

    # --- 2. GNOME/Mutter Specific Optimizations ---
    environment.variables = {
      # Move KMS thread to user space (Fixes cursor stutter on GNOME 49+)
      "MUTTER_DEBUG_KMS_THREAD_TYPE" = "user";

      # Legacy atomic override
      "WLR_DRM_NO_ATOMIC" = "1";
    };

    # --- 3. System Stability ---
    systemd.extraConfig = ''
      DefaultTimeoutStopSec=10s
    '';

    # --- 4. Audio Latency ---
    services.pipewire.extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 32;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 1024;
      };
    };
  };
}
