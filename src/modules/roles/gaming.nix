{ config, pkgs, inputs, lib, ... }:

let
  # Dynamically find the main user (first user with isNormalUser = true)
  # This pulls the user defined in your flake/host config automatically
  mainUser = lib.head (lib.attrValues (lib.filterAttrs (n: u: u.isNormalUser) config.users.users));
  
  # Path to the scripts in your flake configuration directory
  scriptDir = "${mainUser.home}/.config/zenos/src/scripts/gaming";

  # [ ! ] Wrapper to alias 'yuzu' to the Suyu AppImage
  # Requires the AppImage to be at ~/Games/Resources/suyu.appimage
  yuzu-suyu-wrapper = pkgs.writeShellScriptBin "yuzu" ''
    exec ${pkgs.appimage-run}/bin/appimage-run ${mainUser.home}/Games/Resources/suyu.appimage "$@"
  '';

in {

  # -- Steam Configuration --
  programs.steam = {
    enable = true;
    # gamescopeSession.enable = false; # Disabled: Using Gamescope as a window in DE only
    remotePlay.openFirewall = true; # Open ports for Steam Remote Play
    dedicatedServer.openFirewall = true;
    
    # Compatibility tools and extra packages visible to Steam
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  jovian = {
    steam.enable = true;
    decky-loader = {
      enable = true;
    };
  };

  # -- VR Configuration --
  # ALVR firewall rules are critical for Quest 3 streaming
  programs.alvr = {
    enable = true;
    openFirewall = true; 
  };
  
  # High-performance UDEV rules for VR headsets and controllers
  hardware.graphics.enable = true;

  # -- System Packages --
  environment.systemPackages = with pkgs; [
    # Core Tools
    gamescope
    mangohud
    gamemode
    steam-rom-manager
    # decky-loader
    appimage-run     # Required for Suyu
    yuzu-suyu-wrapper # Exposes 'yuzu' command
    
    # VR Stack
    wlx-overlay-s         # Wayland VR Desktop Overlay
    # ovr-advanced-settings # (Check availability in your specific nixpkgs channel)
    
    # Launchers
    prismlauncher
    
    # Emulators (Verify availability in your flake inputs/unstable)
    ryubing               # Switch (Alternate)
    dolphin-emu           # GC/Wii
    pcsx2                 # PS2
    rpcs3                 # PS3
    duckstation           # PS1
    ppsspp                # PSP
    xemu                  # Xbox
    # yuzu-mainline       # [ ! ] Replaced by wrapper above
  ];

  # -- ZeroPlay Library Scaffolder --
  # Runs on login to ensure ~/Games directory structure is correct
  systemd.user.services.zeroplay-init = {
    description = "ZeroPlay Library Scaffolder";
    serviceConfig = {
      Type = "oneshot";
      # Updated to include 'watchdog' and use dynamic path
      ExecStart = "${pkgs.python3.withPackages (ps: [ ps.watchdog ])}/bin/python ${scriptDir}/zeroplay-manager.py scan ${mainUser.home}/Games";
    };
    wantedBy = [ "default.target" ];
  };
  
  # -- Helper Scripts --
  # Add the VR startup script to the path
  environment.etc."zenos/scripts/start-vr".source = "${scriptDir}/start-vr.sh";
  environment.shellAliases = {
    vr-mode = "bash /etc/zenos/scripts/start-vr";
  };
}