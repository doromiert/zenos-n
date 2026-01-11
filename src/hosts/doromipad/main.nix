{
  pkgs,
  lib,
  ...
}:

{
  # ============================================================================
  #  Doromipad (ThinkPad L13 Yoga) - Specific Toolset
  # ============================================================================

  # [ Hardware Support ]
  hardware = {
    # Enable IIO Sensor Proxy for auto-rotation (Accelerometer)
    sensor.iio.enable = true;

    # Bluetooth configuration
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Intel Media Driver for hardware acceleration
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
    };
  };

  # [ Boot / Kernel / Throttling ]
  boot = {
    # Load MSR module for dethrottling script
    kernelModules = [ "msr" ];

    # Merged Kernel Parameters
    kernelParams = [
      "quiet"
      "splash"
      # Graphics optimization
      "i915.enable_guc=2"
      # Power management & Sleep
      "mem_sleep_default=s2idle"
      "acpi.power_button.enable=1"
    ];

    # Intel Graphics Power Saving (Frame Buffer Compression)
    extraModprobeConfig = ''
      options i915 enable_fbc=1 enable_guc=2
    '';

    # Sysctl Tweaks
    kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 10; # Prefer ZRAM
      "dev.nvme.0.queue_mode" = lib.mkForce "none"; # NVMe Scheduler optimization
    };
  };

  # [ Power Management & Services ]
  services = {
    # 1. Fingerprint & Input
    fprintd.enable = true;
    xserver.wacom.enable = true;
    boltd.enable = true;

    # 2. Power Profiles Daemon (Standard GNOME Power Management)
    # Replaces TLP. Works better with GNOME's quick settings.
    power-profiles-daemon.enable = true;

    # 3. Thermald (Dynamic Thermal Management)
    # Works alongside PPD to prevent overheating on Intel chips
    thermald.enable = true;

    # [ REMOVED ] TLP configuration

    # 4. ACPI Power Button Handler (Lock Screen instead of Power Off)
    acpid = {
      enable = true;
      handlers.power = {
        event = "button/power";
        action = ''
          # Dynamic user detection for locking
          ACTIVE_USER=$(${pkgs.systemd}/bin/loginctl list-users --no-legend | ${pkgs.gawk}/bin/gawk '{print $2; exit}')

          if [ -n "$ACTIVE_USER" ]; then
            ${pkgs.systemd}/bin/machinectl shell "$ACTIVE_USER@.host" \
                ${pkgs.glib}/bin/gdbus call --session \
                    --dest org.gnome.ScreenSaver \
                    --object-path /org/gnome/ScreenSaver \
                    --method org.gnome.ScreenSaver.Lock
          fi
        '';
      };
    };

    # 5. Logind Overrides (Ignore power key so ACPI handler works)
    logind = {
      powerKey = "ignore";
      extraConfig = ''
        HandlePowerKey=ignore
        HandleLidSwitch=lock
        HandleLidSwitchExternalPower=lock
      '';
    };

    # 6. Udev Rules for Wakeup
    udev.extraRules = ''
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{power/wakeup}="enabled"
      SUBSYSTEM=="power", KERNEL=="PWRB", ATTR{power/wakeup}="enabled"
    '';

    # 7. GNOME Settings Overrides
    # Ensures GNOME doesn't try to hijack the power button from our ACPI script
    xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.settings-daemon.plugins.power]
      power-button-action='nothing'
      sleep-inactive-ac-type='nothing'
      sleep-inactive-battery-type='nothing'
    '';
  };

  # [ Systemd Services ]
  systemd = {
    # 1. Custom Sleep Config
    sleep.extraConfig = ''
      [Sleep]
      SuspendMode=suspend
      SuspendState=mem
      HibernateMode=platform
      HibernateState=disk
    '';

    # 2. BD_PROCHOT Dethrottle Service
    # Forcefully disables the "Bi-Directional Processor Hot" signal
    # which often causes ThinkPads to stick at 400MHz.
    services.disable-throttling = {
      description = "Disable BD_PROCHOT Throttling";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Checks for MSR device before running wrmsr to avoid failure
        ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -e /dev/cpu/0/msr ]; then ${pkgs.msr-tools}/bin/wrmsr 0x1FC 2 || true; fi'";
        After = [
          "local-fs.target"
          "systemd-modules-load.service"
        ];
      };
    };
  };

  # [ Swap / Memory ]
  zramSwap = {
    enable = true;
    priority = 100;
  };

  # [ Environment ]
  environment.systemPackages = with pkgs; [
    libsmbios
    rnote
    msr-tools # Required for the dethrottle script
  ];
}
