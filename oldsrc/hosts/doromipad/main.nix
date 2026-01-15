{
  pkgs,
  lib,
  ...
}:

{
  # ============================================================================
  #  Doromipad (ThinkPad L13 Yoga) - Optimized [P13.D]
  # ============================================================================

  # [ Hardware Support ]
  hardware = {
    sensor.iio.enable = true; # Auto-rotation
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Graphics: Modern Intel Stack
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD (Broadwell+) - REQUIRED for L13 Gen1/2+
        intel-vaapi-driver # i965 (Older fallback, likely unused but safe)
        libvdpau-va-gl
      ];
    };
  };

  # [ Environment Variables ]
  environment.variables = {
    # Force Intel Media Driver (iHD) for video acceleration
    LIBVA_DRIVER_NAME = "iHD";

    # Firefox VAAPI Fixes
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # [ ! ] DRIVER FIX: Removed "services.xserver.videoDrivers" to use 'modesetting'.

  # [ Boot / Kernel / Throttling ]
  boot = {
    kernelModules = [ "msr" ];

    kernelParams = [
      "quiet"
      "splash"
      "i915.enable_guc=3" # Enable GuC/HuC firmware
      "i915.enable_fbc=1" # Framebuffer compression (Saves RAM bandwidth)
      "mem_sleep_default=s2idle" # Modern standby
      "nowatchdog" # Disable watchdog timers to save CPU cycles
    ];

    extraModprobeConfig = ''
      options i915 enable_fbc=1 enable_guc=3 
    '';

    # [ MEMORY TUNING ]
    # Critical for 27% Swap usage. We shift pressure to ZRAM.
    kernel.sysctl = {
      "dev.nvme.0.queue_mode" = "none";

      # ZRAM Optimization
      "vm.swappiness" = lib.mkForce 130; # Aggressively use swap (ZRAM) to keep RAM free for active tasks
      "vm.watermark_boost_factor" = lib.mkForce 0; # Disable aggressive reclaimer boosting (reduces stutter)
      "vm.watermark_scale_factor" = lib.mkForce 125; # Increase headroom before direct reclaim kicks in
      "vm.page-cluster" = 0; # Read 1 page at a time (better for ZRAM latency)
    };
  };

  # [ Memory Management ]
  # Explicitly defined here to ensure integration with the sysctl settings above
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; # Use up to 100% of RAM as swap (compressed)
    priority = 100;
  };

  # [ Power Management & Services ]
  services = {
    power-profiles-daemon.enable = true;
    thermald.enable = true;

    # [ SAFETY NET ]
    # Kills heavy background tabs instead of freezing the OS
    earlyoom = {
      enable = true;
      enableNotifications = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
    };

    # [ THERMAL ]
    # Attempt to undervolt if CPU allows (Mitigates 87°C peaks)
    # If locked by BIOS, this service will just fail quietly or do nothing.
    undervolt = {
      enable = true;
      # Moderate defaults for ThinkPads. Adjust if unstable.
      coreOffset = -50;
      gpuOffset = -50;
      uncoreOffset = -50;
      analogioOffset = -50;
    };
  };

  # [ Systemd Services ]
  systemd = {
    sleep.extraConfig = ''
      [Sleep]
      SuspendMode=suspend
      SuspendState=mem
      HibernateMode=platform
      HibernateState=disk
    '';

    # BD_PROCHOT Dethrottle Service
    # WARNING: With 87°C temps, this removes the safety brake.
    # If the laptop shuts down abruptly, DISABLE THIS.
    services.disable-throttling = {
      description = "Disable BD_PROCHOT Throttling";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -e /dev/cpu/0/msr ]; then ${pkgs.msr-tools}/bin/wrmsr 0x1FC 2 || true; fi'";
        After = [ "local-fs.target" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    libsmbios
    msr-tools
    intel-gpu-tools
    undervolt # Tool to check/set undervolt manually if needed
  ];
}
