# contains gnome-specific configs
{ lib, pkgs, ... }:

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

  fake-gnome-terminal = pkgs.writeShellScriptBin "gnome-terminal" ''
    exec ${pkgs.kitty}/bin/kitty "$@"
  '';

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
    etc."xdg/kitty/kitty.conf".text = ''
      # --- Font ---
      font_family      Atkynson Mono NF
      bold_font        auto
      italic_font      auto
      bold_italic_font auto
      font_size        11

      # --- Adwaita Dark (Official Palette) ---
      background            #1e1e1e
      foreground            #ffffff
      selection_background  #9841bb
      selection_foreground  #ffffff
      url_color             #c061cb
      cursor                #ffffff

      # Standard Colors
      color0  #241f31
      color1  #c01c28
      color2  #2ec27e
      color3  #f5c211
      color4  #1e78e4
      color5  #9841bb
      color6  #0ab9dc
      color7  #c0bfbc

      # Bright Colors
      color8  #5e5c64
      color9  #ed333b
      color10 #57e389
      color11 #f8e45c
      color12 #51a1ff
      color13 #c061cb
      color14 #4fd2fd
      color15 #ffffff

      # --- UX & Cursor Anims (GPU Accel) ---
      cursor_shape beam
      cursor_beam_thickness 1.5
      cursor_blink_interval 0.5

      # The "Fluid" Feel
      cursor_trail 3
      cursor_trail_decay 0.1 0.4
      cursor_trail_start_threshold 2

      # --- Touchscreen Optimization ---
      # Multiplier > 1.0 makes scrolling feel like a phone/GTK
      touch_scroll_multiplier 5.0
      # Prevent cursor flickering on touch tap
      mouse_hide_wait 3.0

      # --- Layout ---
      # (if you use Super+Drag on the window body)
      window_padding_width 5
      hide_window_decorations yes

      # --- Performance & Behavior ---
      repaint_delay 8
      input_delay 1
      sync_to_monitor yes
      confirm_os_window_close 0
      detect_urls yes
    '';

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
        fake-gnome-terminal
        kitty
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
        nautilus-open-any-terminal
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
        gnome-console
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
          "com/github/stunkymonkey/nautilus-open-any-terminal" = {
            terminal = "kitty";
            keybindings = "<Ctrl><Alt>t";
            new-tab = true;
            flatpak = false;
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
            experimental-features = [
              "scale-monitor-framebuffer"
              "xwayland-native-scaling"
            ];
          };
        };
      }
    ];
  };
}
