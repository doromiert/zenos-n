{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.steam-custom;

  # User defined constraint [P5.6] + [Decky Requirement]
  # We append -gamepadui because Decky ONLY loads in the new React-based UI.
  customExec = "${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -r 120 -f --backend sdl --force-grab-cursor --mangoapp -e -- steam -gamepadui %U";

in
{
  options.programs.steam-custom = {
    enable = mkEnableOption "Steam with Gamescope/Decky integration for GNOME";
  };

  config = mkIf cfg.enable {

    # 1. Enable Hardware/Graphics Basics
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # 2. Enable Gamescope & MangoHud
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    programs.gamemode.enable = true;
    programs.mangohud.enable = true;

    # 3. Steam Configuration
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      # Override the package to patch the .desktop file directly
      package = pkgs.steam.overrideAttrs (oldAttrs: {
        postBuild = ''
          ${oldAttrs.postBuild or ""}
          echo "Patching Steam desktop file to use Gamescope..."
          sed -i 's|^Exec=.*|Exec=${customExec}|' $out/share/applications/steam.desktop
          sed -i 's|^Name=Steam|Name=Steam (Gamescope)|' $out/share/applications/steam.desktop
        '';
      });
    };

    # 4. System Packages required for Decky & the Bootstrap script
    environment.systemPackages = with pkgs; [
      curl
      unzip
      util-linux
      python3
      git
      jq # Added for parsing GitHub API in the bootstrap script

      # Quality of Life Gaming Tools
      protonup-qt # GUI to install Proton-GE
      protontricks # Winetricks for Proton
    ];

    # 5. Firewall for Decky
    networking.firewall.allowedTCPPorts = [ 1337 ];
    networking.firewall.allowedUDPPorts = [ 1337 ];

    # 6. Decky Loader Auto-Bootstrap Service
    # Instead of running the installer manually, this service ensures Decky is present and running.
    systemd.services.decky-loader = {
      description = "Decky Loader (Auto-Bootstrapped)";
      wantedBy = [ "multi-user.target" ];

      # We need internet to download the update
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        # Decky typically runs as root to access system services/input
        User = "root";
        WorkingDirectory = "/var/lib/decky-loader";
        StateDirectory = "decky-loader"; # Creates /var/lib/decky-loader automatically

        # The script checks if we have the loader. If not, it fetches the latest release.
        ExecStart = pkgs.writeShellScript "decky-loader-bootstrap" ''
          set -e
          echo "Checking for Decky Loader..."

          # URL to fetch the latest release info
          LATEST_URL="https://github.com/SteamDeckHomebrew/decky-loader/releases/latest/download/plugin_loader.zip"

          # If main.py doesn't exist, we assume it's a fresh install or broken state
          if [ ! -f "plugin_loader.py" ]; then
            echo "Decky Loader not found. Downloading latest release..."
            ${pkgs.curl}/bin/curl -L -o decky.zip "$LATEST_URL"
            ${pkgs.unzip}/bin/unzip -o decky.zip
            rm decky.zip
            
            # Ensure permissions
            chmod +x plugin_loader.py
            echo "Download complete."
          fi

          echo "Starting Decky Loader..."
          # Set python path to current directory to find dependencies inside the zip extraction
          export PYTHONPATH=$PYTHONPATH:.

          # Run the loader. 
          # We point to the local python environment we installed in systemPackages
          exec ${pkgs.python3}/bin/python3 plugin_loader.py
        '';

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # 7. Environment Vars
    environment.sessionVariables = {
      STEAM_FORCE_DESKTOPUI_SCALING = "1";
    };

    # 8. Kernel & System Tweaks for Gaming
    boot.kernel.sysctl = {
      # Essential for many large games (prevents crashes in Wine/Proton)
      "vm.max_map_count" = 2147483642;
    };

    # Enable NTFS support (common for external/shared game drives)
    boot.supportedFilesystems = [ "ntfs" ];
  };
}
