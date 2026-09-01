# [ XR ] Minimal VR stack: Steam(VR) + ALVR + OVR Advanced Settings
# Targeted at standalone-headset streaming into VRChat. Intentionally does NOT
# pull in the full 'gaming' role (emulators / Decky / Jovian).
{ pkgs, lib, ... }:

let
  # OVR Advanced Settings is not in nixpkgs, so we wrap the upstream AppImage.
  # Non-STEAM build: registers its own SteamVR overlay manifest on first run.
  ovr-advanced-settings = pkgs.appimageTools.wrapType2 rec {
    pname = "ovr-advanced-settings";
    version = "5.8.11";
    src = pkgs.fetchurl {
      url = "https://github.com/OpenVR-Advanced-Settings/OpenVR-AdvancedSettings/releases/download/v${version}/OpenVR_Advanced_Settings-72e91e9-x86_64.AppImage";
      hash = "sha256-ql6wCqFySjWe/hoRPpik7uNVmN9Rc0ZcRhAZDuscQqU=";
    };
    extraPkgs = pkgs: [
      pkgs.libGL
      pkgs.udev
      pkgs.xorg.libXrandr
    ];
  };

  vr-overlay-supervisor = pkgs.writeShellApplication {
    name = "vr-overlay-supervisor";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      steam-run
      util-linux
      wlx-overlay-s
      ovr-advanced-settings
    ];
    text = builtins.readFile ../../../scripts/gaming/vr-overlay-supervisor.sh;
  };

  # ALVR -> SteamVR -> overlays, in that order. Store paths are substituted into
  # the repair routine so mutable SteamVR depot fixes survive updates.
  vr-mode = pkgs.writeShellApplication {
    name = "vr-mode";
    runtimeInputs = with pkgs; [
      alvr-patched
      binutils
      coreutils
      gnugrep
      jq
      libcap
      patchelf
      procps
      steam
      systemd
      util-linux
    ];
    text = builtins.replaceStrings
      [ "@libSM@" "@libICE@" "@nss@" "@nspr@" "@setcap@" ]
      [
        "${pkgs.xorg.libSM}/lib"
        "${pkgs.xorg.libICE}/lib"
        "${pkgs.nss}/lib"
        "${pkgs.nspr}/lib"
        "${pkgs.libcap}/bin/setcap"
      ]
      (builtins.readFile ../../../scripts/gaming/start-vr.sh);
  };

  vr-desktop = pkgs.makeDesktopItem {
    name = "zenos-vr";
    desktopName = "ZenOS VR";
    genericName = "Virtual Reality";
    comment = "Start ALVR, SteamVR, and VR overlays";
    exec = "vr-mode";
    icon = "steam_icon_250820";
    categories = [ "Game" ];
    startupNotify = true;
  };

  # ALVR's DRM-lease shim picks the first /dev/dri/card* that has any connectors
  # at all, ignoring whether a display is actually attached. On this box that is
  # the unused Raphael iGPU rather than the dGPU driving the monitors, so
  # SteamVR gets a lease on the idle GPU -> black screen -> compositor crash.
  # The patch makes it prefer a card with a CONNECTED connector.
  # ALVR 20.14's VAAPI pipeline is not compatible with FFmpeg 8. Nixpkgs has
  # since pinned the package to FFmpeg 7; keep that fix while this flake remains
  # on the older package expression.
  alvr-patched = (pkgs.alvr.override { ffmpeg = pkgs.ffmpeg_7; }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./resources/alvr-drm-lease-prefer-connected-gpu.patch
      ./resources/alvr-steamvr-2.16-compositor-name.patch
      # PR #3353 backport: recover the exact frame pose from stripped SteamVR
      # compositors instead of tagging frames with the newest head pose.
      ./resources/alvr-steamvr-stripped-pose-recovery.patch
      ./resources/alvr-quest-left-menu-dashboard.patch
    ];
  });
in
{
  # -- Steam --
  # Proton-GE is what VRChat wants; the stock Proton runtime chokes on it.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    extraPackages = [
      pkgs.xorg.libICE
      pkgs.xorg.libSM
    ];
  };

  # SteamVR's udev rules (lighthouse, controllers, USB permissions)
  hardware.steam-hardware.enable = true;

  # 32-bit userspace is mandatory for the Steam/Proton side of SteamVR
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # -- ALVR --
  # openFirewall covers 9943/9944 (TCP+UDP) used for headset discovery/streaming
  programs.alvr = {
    enable = true;
    openFirewall = true;
    package = alvr-patched;
  };

  # wlx's default Liberation Sans match resolves through steam-run to an FHS
  # symlink whose store target may not be visible when the overlay starts.
  home-manager.sharedModules = [
    {
      xdg.configFile."wlxoverlay/conf.d/00-zenos-font.yaml".text = ''
        primary_font: "Atkinson Hyperlegible Next:style=Bold"
      '';
    }
  ];

  # Keep overlays aligned with SteamVR's compositor lifecycle. ALVR restarts
  # SteamVR when the wireless HMD connects, so one-shot overlay launches are
  # killed or left attached to the outgoing compositor.
  systemd.user.services.zenos-vr-overlays = {
    description = "ZenOS VR overlay supervisor";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${vr-overlay-supervisor}/bin/vr-overlay-supervisor";
      Restart = "always";
      RestartSec = 2;
    };
  };

  environment.systemPackages = with pkgs; [
    ovr-advanced-settings
    vr-desktop
    vr-mode
    vr-overlay-supervisor
    wlx-overlay-s # Wayland desktop overlay inside VR

    # Proton wrangling for VRChat
    protonup-qt
    protontricks
  ];

  # VRChat maps a huge number of regions when loading worlds/avatars;
  # the default ceiling makes it hard-crash under Proton. mkDefault so hosts
  # that already raise this themselves (e.g. doromi-tul-2) still win.
  boot.kernel.sysctl."vm.max_map_count" = lib.mkDefault 2147483642;

  # SteamVR spawns a lot of processes/handles per session.
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "524288";
    }

    # SteamVR's compositor and tracking threads ask for SCHED_FIFO directly via
    # sched_setscheduler -- they do not go through rtkit, so rtkit.enable does
    # nothing for them. Without an rtprio rlimit every request fails with
    # "setschedparam failed" and the session runs at normal priority: low
    # framerate, dropped controller input, and the compositor giving up after a
    # few seconds. Only @pipewire had these, and the main user isn't in it.
    {
      domain = "@users";
      type = "-";
      item = "rtprio";
      value = "95";
    }
    {
      domain = "@users";
      type = "-";
      item = "nice";
      value = "-19";
    }
  ];

  # Let SteamVR's compositor request realtime priority (async reprojection).
  programs.gamemode.enable = true;
}
