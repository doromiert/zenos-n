# contains gnome-specific configs
{ config, pkgs, ... }:

let
  # Define extensions here for easier management
  extensions = with pkgs.gnomeExtensions; [
    # Window Management
    forge
    burn-my-windows
    compiz-windows-effect
    compiz-alike-magic-lamp-effect
    rounded-window-corners-reborn
    blur-my-shell

    # UX / Navigation
    alphabetical-app-grid
    category-sorted-app-grid
    coverflow-alt-tab
    hide-top-bar
    mouse-tail

    # System
    gsconnect
    clipboard-indicator
    notification-timeout
  ];
in
{

  imports = [
    ./styling.nix
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

  # 1. Core Desktop Services
  services = {
    # xserver = {
    #     enable = true;
    # };
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Ensure standard GNOME services are running
    udev.packages = with pkgs; [ gnome-settings-daemon ];

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };

  # 2. System-wide Packages (Extensions and Tools)
  environment = {
    systemPackages =
      with pkgs;
      [
        gnome-tweaks
        gnome-extension-manager
        wl-clipboard # Useful for Wayland GNOME
      ]
      ++ extensions;

    # Remove default GNOME bloat for all users
    gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
        gedit
        cheese
        gnome-music
        gnome-maps
        epiphany
        gnome-contacts
        gnome-weather
      ])
      ++ (with pkgs.gnome; [
      ]);
  };

  # 3. Declarative GSettings (Dconf) for All Users
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          # Global Interface Settings
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            enable-hot-corners = false;
          };

          # Shell & Extension Management
          "org/gnome/shell" = {
            disable-user-extensions = false;

            # Dynamically map the UUIDs of the extensions installed above
            enabled-extensions = map (ext: ext.extensionUuid) extensions;

            favorite-apps = [
              "nautilus.desktop"
              "org.gnome.Nautilus.desktop"
            ];
          };
        };
      }
    ];
  };
}
