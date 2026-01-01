# contains gnome-specific configs
{ pkgs, lib, ... }:

let
  # Define custom Forge extension from local precompiled resources
  forge-custom = pkgs.stdenv.mkDerivation rec {
    pname = "gnome-shell-extension-forge";
    version = "custom";

    # Point to the precompiled local directory
    src = ../../../../resources/forge;

    # No build steps needed for precompiled code
    dontBuild = true;

    installPhase = ''
      export UUID="forge@jmmaranan.com"
      dest="$out/share/gnome-shell/extensions/$UUID"
      mkdir -p "$dest"

      # Copy the precompiled contents directly
      cp -a . "$dest/"

      # Just in case, ensure schemas are compiled for the store path
      if [ -d "$dest/schemas" ]; then
        ${pkgs.glib.dev}/bin/glib-compile-schemas "$dest/schemas"
      fi
    '';

    passthru.extensionUuid = "forge@jmmaranan.com";
  };

  # Define extensions
  extensions = [
    forge-custom
  ]
  ++ (with pkgs.gnomeExtensions; [
    # Window Management
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
    window-is-ready-remover

    # System
    gsconnect
    clipboard-indicator
    notification-timeout
  ]);
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
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    udev.packages = with pkgs; [ gnome-settings-daemon ];
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # 2. System-wide Packages
  environment = {
    systemPackages =
      with pkgs;
      [
        gnome-tweaks
        blackbox-terminal
        gnome-extension-manager
        wl-clipboard
        dconf-editor

        biblioteca
        dialect
        decoder
        raider
        wike
        curtail
        czkawka
        hieroglyphic
        warehouse
        switcheroo
        letterpress
        resources
        icon-library
        pika-backup
        helvum
        commit
      ]
      ++ extensions;

    gnome.excludePackages = (
      with pkgs;
      [
        gnome-photos
        gnome-tour
        gedit
        cheese
        gnome-music
        gnome-maps
        epiphany
        gnome-contacts
        gnome-weather
      ]
    );
  };

  services.flatpak.packages = [
    "com.github.tchx84.Flatseal"
  ];

  # 3. Declarative GSettings (Dconf) for All Users
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            enable-hot-corners = false;
          };

          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = map (ext: ext.extensionUuid) extensions;

            favorite-apps = [
              "nautilus.desktop"
              "org.gnome.Nautilus.desktop"
              "com.raggesilver.BlackBox.desktop"
              "org.gnome.Epiphany.desktop"
            ];
          };
        };
      }
    ];
  };
}
