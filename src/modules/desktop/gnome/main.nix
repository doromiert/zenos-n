# contains gnome-specific configs
{ pkgs, ... }:

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
    app-hider
    undecorate
    hide-minimized
    hide-cursor
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

  # [FIX] Portal Configuration
  # This fixes the VS Code freeze and PWA crashes on file picker.
  # We strictly prioritize the GNOME portal.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gnome"
      "gtk"
    ];
  };

  # 1. Core Desktop Services
  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    udev.packages = with pkgs; [ gnome-settings-daemon ];

  };

  # 2. System-wide Packages
  environment = {
    systemPackages =
      with pkgs;
      [
        pipewire
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav # Essential for common formats like .mp4/.mkv

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
            gtk-enable-primary-paste = false;
          };

          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = map (ext: ext.extensionUuid) extensions;

            favorite-apps = [
              "firefox.desktop"
              "org.gnome.Nautilus.desktop"
              "com.raggesilver.BlackBox.desktop"
            ];
          };

          # [FIX] Crash Prevention: Disable edge tiling to stop auto-maximize logic
          "org/gnome/desktop/wm/preferences" = {
            edge-tiling = false;
            action-double-click-titlebar = "toggle-maximize";
          };

          # [FIX] UX: Center new windows since we disabled auto-max
          "org/gnome/mutter" = {
            edge-tiling = false;
            center-new-windows = true;
            auto-maximize = false;
          };
        };
      }
    ];
  };
}
