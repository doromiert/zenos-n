{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.zenos.desktop.gnome;

  # ============================================================================
  # [ EXTENSIONS & CUSTOM PACKAGES ]
  # ============================================================================

  # Define custom Forge extension from local precompiled resources
  forge-custom = pkgs.stdenv.mkDerivation {
    pname = "gnome-shell-extension-forge";
    version = "custom";
    # Point to the precompiled local directory
    # [UPDATED] Path adjusted to ../../ as requested
    src = ../../resources/forge;
    dontBuild = true;
    installPhase = ''
      export UUID="forge@jmmaranan.com"
      dest="$out/share/gnome-shell/extensions/$UUID"
      mkdir -p "$dest"
      cp -a . "$dest/"
      if [ -d "$dest/schemas" ]; then
        ${pkgs.glib.dev}/bin/glib-compile-schemas "$dest/schemas"
      fi
    '';
    passthru.extensionUuid = "forge@jmmaranan.com";
  };

  fake-gnome-terminal = pkgs.writeShellScriptBin "gnome-terminal" ''
    exec ${pkgs.kitty}/bin/kitty "$@"
  '';

  # Define extensions list
  extensions = [
    forge-custom
  ]
  ++ (with pkgs.gnomeExtensions; [
    user-themes
    # Window Management
    app-hider
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

    # Clock Formatting
    date-menu-formatter

    # System
    gsconnect
    clipboard-indicator
    notification-timeout
  ]);

in
{
  # 1. Define Options
  options.zenos.desktop.gnome = {
    enable = mkEnableOption "GNOME Desktop Environment";

    config = {
      zenosTheming = mkOption {
        type = types.bool;
        default = true;
        description = "Apply custom ZenOS GTK themes, icons, and fonts";
      };
      zeroClock = mkOption {
        type = types.bool;
        default = true;
        description = "Show the custom Zero Clock widget logic (if applicable)";
      };
    };
  };

  # 2. Implement Logic
  config = mkIf cfg.enable {

    # ============================================================================
    # [ CORE SERVICES ]
    # ============================================================================

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    services.udev.packages = with pkgs; [ gnome-settings-daemon ];

    # Fix for GDM in some setups
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    # ============================================================================
    # [ PORTALS & SYSTEM PACKAGES ]
    # ============================================================================

    # [FIX] Portal Configuration
    # Prioritize GNOME portal to fix VS Code freeze and PWA crashes
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

    environment.systemPackages =
      with pkgs;
      [
        # Core Audio/Video
        pipewire
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav

        # Tools
        gnome-tweaks
        fake-gnome-terminal
        kitty
        gnome-extension-manager
        wl-clipboard
        dconf-editor

        # Apps
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

    services.flatpak.enable = true;
    services.flatpak.packages = [
      "com.github.tchx84.Flatseal"
    ];

    environment.gnome.excludePackages = with pkgs; [
      gnome-software
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
    ];

    # ============================================================================
    # [ CONFIGURATION FILES ]
    # ============================================================================

    environment.etc."xdg/kitty/kitty.conf".text = ''
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

      color0  #241f31
      color1  #c01c28
      color2  #2ec27e
      color3  #f5c211
      color4  #1e78e4
      color5  #9841bb
      color6  #0ab9dc
      color7  #c0bfbc

      color8  #5e5c64
      color9  #ed333b
      color10 #57e389
      color11 #f8e45c
      color12 #51a1ff
      color13 #c061cb
      color14 #4fd2fd
      color15 #ffffff

      # --- Behavior ---
      cursor_shape beam
      cursor_beam_thickness 1.5
      cursor_blink_interval 0.5
      cursor_trail 3
      cursor_trail_decay 0.1 0.4
      cursor_trail_start_threshold 2
      touch_scroll_multiplier 5.0
      mouse_hide_wait 3.0
      window_padding_width 5
      hide_window_decorations yes
      repaint_delay 8
      input_delay 1
      sync_to_monitor yes
      confirm_os_window_close 0
      detect_urls yes
    '';

    # ============================================================================
    # [ DCONF SETTINGS ]
    # ============================================================================

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

            "org/gnome/shell/extensions/date-menu-formatter" = {
              pattern = "dd.MM  HH:mm";
              formatter = "01_luxon";
              text-align = "center";
              font-size = pkgs.lib.gvariant.mkInt32 9;
              update-level = pkgs.lib.gvariant.mkInt32 1;
            };

            "org/gnome/desktop/wm/preferences" = {
              edge-tiling = false;
              action-double-click-titlebar = "toggle-maximize";
            };

            "org/gnome/mutter" = {
              edge-tiling = false;
              center-new-windows = true;
              auto-maximize = false;
              experimental-features = [
                "scale-monitor-framebuffer"
                "xwayland-native-scaling"
              ];
            };

            # --- Alphabetical App Grid ---
            "org/gnome/shell/extensions/alphabetical-app-grid" = {
              folder-order-position = "end";
            };

            # --- Blur My Shell ---
            "org/gnome/shell/extensions/blur-my-shell" = {
              settings-version = 2;
              # pipelines handled by systemd service above
            };

            "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
              brightness = 0.59999999999999998;
              sigma = 30;
            };

            "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
              pipeline = "pipeline_default";
            };

            "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
              blur = true;
              brightness = 0.59999999999999998;
              pipeline = "pipeline_default_rounded";
              sigma = 30;
              static-blur = true;
              style-dash-to-dock = 0;
            };

            "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
              pipeline = "pipeline_default";
            };

            "org/gnome/shell/extensions/blur-my-shell/overview" = {
              pipeline = "pipeline_default";
            };

            "org/gnome/shell/extensions/blur-my-shell/panel" = {
              blur = false;
              brightness = 0.59999999999999998;
              pipeline = "pipeline_default";
              sigma = 30;
            };

            "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
              pipeline = "pipeline_default";
            };

            "org/gnome/shell/extensions/blur-my-shell/window-list" = {
              brightness = 0.59999999999999998;
              sigma = 30;
            };

            # --- Burn My Windows ---
            "org/gnome/shell/extensions/burn-my-windows" = {
              # [NOTE] Config path points to user home directory as requested
              active-profile = "/home/doromiert/.config/burn-my-windows/profiles/bmw.conf";
              last-extension-version = 47;
              last-prefs-version = 47;
              prefs-open-count = 2;
            };

            # --- Compiz Windows Effect ---
            "org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect" = {
              friction = 4.9000000000000004;
              last-version = 29;
              mass = 50.0;
              resize-effect = true;
              speedup-factor-divider = 4.7000000000000002;
              spring-k = 2.2000000000000002;
            };

            # --- Coverflow Alt-Tab ---
            "org/gnome/shell/extensions/coverflowalttab" = {
              desaturate-factor = 0.0;
              icon-style = "Classic";
              switcher-background-color = lib.gvariant.mkTuple [
                1.0
                1.0
                1.0
              ];
              use-glitch-effect = true;
            };

            # --- Forge ---
            "org/gnome/shell/extensions/forge" = {
              css-last-update = lib.gvariant.mkUint32 37;
              dnd-center-layout = "swap";
              float-always-on-top-enabled = false;
              focus-border-toggle = false;
              quick-settings-enabled = false;
              split-border-toggle = false;
              stacked-tiling-mode-enabled = false;
              tabbed-tiling-mode-enabled = false;
              window-gap-size = lib.gvariant.mkUint32 4;
            };

            # --- Hide Top Bar ---
            "org/gnome/shell/extensions/hidetopbar" = {
              enable-intellihide = false;
              mouse-sensitive = true;
              mouse-sensitive-fullscreen-window = false;
            };

            # --- Media Controls ---
            "org/gnome/shell/extensions/mediacontrols" = {
              extension-index = lib.gvariant.mkUint32 1;
              extension-position = "Left";
              show-control-icons = false;
            };

            # --- Notification Timeout ---
            "org/gnome/shell/extensions/notification-timeout" = {
              timeout = 2000;
            };

            # --- Panel Corners ---
            "org/gnome/shell/extensions/panel-corners" = {
              panel-corner-radius = 22;
              screen-corner-radius = 22;
            };

            # --- Quick Settings Tweaks ---
            "org/gnome/shell/extensions/quick-settings-tweaks" = {
              datemenu-hide-left-box = false;
              media-gradient-enabled = false;
              media-progress-enabled = false;
              menu-animation-enabled = true;
              notifications-enabled = false;
              overlay-menu-enabled = true;
            };

            # --- Rounded Window Corners Reborn ---
            "org/gnome/shell/extensions/rounded-window-corners-reborn" = {
              border-width = 1;
              settings-version = lib.gvariant.mkUint32 7;
            };

            # --- Tweaks System Menu ---
            "org/gnome/shell/extensions/tweaks-system-menu" = {
              applications = [
                "org.gnome.tweaks.desktop"
                "com.mattjakeman.ExtensionManager.desktop"
              ];
            };
          };
        }
      ];
    };

    # ============================================================================
    # [ CONDITIONAL IMPORTS ]
    # ============================================================================

    # Import the styling module if enabled
    imports = lib.optional cfg.config.zenosTheming ./zenos-styling.nix;

    # [NOTE] ZeroClock logic is handled via zenos-styling.nix
    # No separate package installation is required here.
  };
}
