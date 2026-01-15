{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.amd.gpu.rx6900xt or { enable = false; };

  # Helper script to apply the OC safely
  apply-oc-script = pkgs.writeShellScriptBin "apply-6900xt-oc" ''
    # Wait for the card to initialize
    sleep 5

    CARD_PATH="/sys/class/drm/card0/device"

    if [ ! -d "$CARD_PATH" ]; then
      echo "GPU not found at $CARD_PATH"
      exit 1
    fi

    echo "Applying RX 6900 XT OC Profile..."

    # Enable manual overclocking mode
    echo "manual" > "$CARD_PATH/power_dpm_force_performance_level"

    # 1. Set Frequency Limits (Feature 26 & 5 from XML)
    # Core (SCLK): State 1 (Max) -> 2900 MHz
    echo "s 1 2900" > "$CARD_PATH/pp_od_clk_voltage"
    # Memory (MCLK): State 1 (Max) -> 2150 MHz (Linux often caps 2150+ unstable, setting 2150 safe, try 2180 if stable)
    echo "m 1 2180" > "$CARD_PATH/pp_od_clk_voltage"

    # 2. Set Voltage (Feature 12 from XML: 1100mV)
    # RDNA2 Sysfs Voltage Curve (vc) format: point, freq, voltage
    # We pin the max frequency point (2) to 2900MHz @ 1100mV
    echo "vc 2 2900 1100" > "$CARD_PATH/pp_od_clk_voltage"

    # 3. Apply Changes
    echo "c" > "$CARD_PATH/pp_od_clk_voltage"

    # 4. Set Power Limit (Feature 3 from XML: +12%)
    # We read the default cap and multiply by 1.12
    # Note: Using a safe hardcoded value for 6900XT Reference (255W Chip Power * 1.12 ≈ 285W)
    # If your card has a higher BIOS limit (e.g. 300W chip), adjust accordingly.
    # 290000000 microwatts = 290W
    echo 290000000 > "$CARD_PATH/hwmon/hwmon*/power1_cap"

    echo "OC Profile Applied: Core 2900MHz@1100mV, Mem 2180MHz"
  '';
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Import generic AMD GPU settings
    zenos.deviceConfigs.amd.gpu.generic.enable = true;

    # Early KMS
    hardware.amdgpu.initrd.enable = true;

    # UNLOCK Overclocking access (Critical)
    boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

    # Force RADV for gaming
    environment.variables.AMD_VULKAN_ICD = "radv";

    # Systemd service to apply the OC at boot
    systemd.services.amd-gpu-overclock = {
      description = "Apply RX 6900 XT Overclock Profile";
      after = [ "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${apply-oc-script}/bin/apply-6900xt-oc";
        # Root permission required to write to sysfs
        User = "root";
      };
    };

    # Install CoreCtrl just in case you want to verify visually
    environment.systemPackages = [ pkgs.corectrl ];
  };
}
