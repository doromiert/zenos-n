{ pkgs, config, ... }:
let
  zb-daemon-script = pkgs.writeScriptBin "zb-daemon" (
    builtins.readFile ../../scripts/zbridge/zb-daemon.sh
  );
  zb-config-script = pkgs.writeScriptBin "zb-config" (
    builtins.readFile ../../scripts/zbridge/zb-config.sh
  );
  zb-installer-script = pkgs.writeScriptBin "zb-installer" (
    builtins.readFile ../../scripts/zbridge/zb-installer.sh
  );
in
{
  # --- PipeWire (Clean) ---
  # We removed the extraConfig block causing the crash.
  # The sinks (zbin/zbout/zmic) will be created by zb-daemon.sh at runtime.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- Video Configuration ---
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera" video_nr=9
  '';

  # --- System Packages ---
  environment.systemPackages = with pkgs; [
    android-tools
    scrcpy
    ffmpeg
    pulseaudio
    procps
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    zb-daemon-script
    zb-config-script
    zb-installer-script
  ];

  # --- Systemd User Service ---
  systemd.user.services.zbridge = {
    description = "ZeroBridge Background Daemon";
    after = [
      "pipewire.service"
      "network.target"
    ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${zb-daemon-script}/bin/zb-daemon";
      Restart = "always";
      RestartSec = "3";
      Environment = "PATH=${
        pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.android-tools
          pkgs.scrcpy
          pkgs.ffmpeg
          pkgs.gst_all_1.gstreamer
          pkgs.pulseaudio
          pkgs.procps
          pkgs.pipewire
        ]
      }:/run/current-system/sw/bin";
    };
  };
}
