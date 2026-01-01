{ pkgs, config, ... }:
{
  # --- Audio Configuration ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig.pipewire."91-null-sinks" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "vmic";
            "node.description" = "Android Mic (Virtual Sink)";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "vout";
            "node.description" = "Main Output";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
      ];
    };
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

    # GStreamer Stack (Required for Low Latency Mode)
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly

    # Main ZBridge Script
    (pkgs.writeScriptBin "zbridge" (builtins.readFile ../../scripts/zbridge.sh))

    # ZBridge Receiver Installer
    (pkgs.writeScriptBin "zbr-installer" (builtins.readFile ../../scripts/zbr-installer.sh))
  ];
}
