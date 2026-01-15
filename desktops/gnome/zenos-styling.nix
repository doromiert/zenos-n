# @file: desktops/gnome/zenos-styling.nix
# @brief: ZenOS styling, assets, and theming for the GNOME desktop environment.
# @context: desktop environment
{ pkgs, lib, ... }:

let
  # ============================================================================
  # [ TARGETED APPS ]
  # List of Legacy GTK3 Flatpaks that NEED the theme override.
  # LibAdwaita apps (Flatseal, Amberol, etc.) MUST NOT be in this list.
  # ============================================================================
  legacyGtk3Apps = [
    # "org.gimp.GIMP"
    # "org.inkscape.Inkscape"
  ];

  # ============================================================================
  # [ FIREFOX THEMING RESOURCES ]
  # ============================================================================

  gnomeThemeRepo = pkgs.fetchFromGitHub {
    owner = "rafaelmardojai";
    repo = "firefox-gnome-theme";
    rev = "v143";
    sha256 = "sha256-0E3TqvXAy81qeM/jZXWWOTZ14Hs1RT7o78UyZM+Jbr4=";
  };

  # [FIX] Import from the subdirectory so relative paths in the theme work
  customChromeCss = pkgs.writeText "userChrome.css" ''
    @import "gnome-theme/userChrome.css";
  '';

  # [FIX] Added wrapper for userContent.css to maintain relative path integrity
  customContentCss = pkgs.writeText "userContent.css" ''
    @import "gnome-theme/userContent.css";
  '';

  # ============================================================================
  # [ ASSETS & HELPERS ]
  # ============================================================================

  # [CRITICAL FIX] Font Generator
  # This builds a fresh TTF font ("ZeroClock") from source SVGs.
  zeroFontPkg =
    let
      # Define paths - ensure these match your actual structure
      # [UPDATED] Path adjusted to ../../resources/ as requested
      rawPath = ../../resources/Fonts/zero-raw;
      condensedPath = ../../resources/Fonts/zero-raw-condensed;
      hasCondensed = builtins.pathExists condensedPath;
      scriptPath = ../../scripts/make-zero.py;
    in
    pkgs.runCommand "zenos-font-zero-generated"
      {
        nativeBuildInputs = [ pkgs.fontforge ];
        inherit rawPath;
        condensedPath = if hasCondensed then condensedPath else "";
        inherit scriptPath;
      }
      ''
        mkdir -p $out/share/fonts/truetype
        cp $scriptPath ./build.py
        fontforge -script ./build.py
      '';

  wallpaperPkg = pkgs.runCommand "zenos-wallpapers" { } ''
    dest=$out/share/backgrounds/zenos
    mkdir -p $dest
    mkdir -p $out/share/gnome-background-properties
    # [UPDATED] Path adjusted to ../../resources/
    cp -r ${../../resources/wallpapers}/* $dest/ || echo "Warning: Wallpapers not found"

    echo '<?xml version="1.0"?>' > $out/share/gnome-background-properties/zenos.xml
    echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">' >> $out/share/gnome-background-properties/zenos.xml
    echo '<wallpapers>' >> $out/share/gnome-background-properties/zenos.xml
    for img in "$dest"/*.{png,jpg,jpeg}; do
        [ -e "$img" ] || continue
        filename=$(basename "$img")
        name="''${filename%.*}"
        printf "  <wallpaper>\n    <name>ZenOS: %s</name>\n    <filename>%s</filename>\n    <options>zoom</options>\n  </wallpaper>\n" "$name" "$img" >> $out/share/gnome-background-properties/zenos.xml
    done
    echo '</wallpapers>' >> $out/share/gnome-background-properties/zenos.xml
  '';

  cursorPkg = pkgs.runCommand "zenos-cursor" { } ''
    mkdir -p $out/share/icons
    # [UPDATED] Path adjusted to ../../resources/
    cp -r ${../../resources/GoogleDot-Black} $out/share/icons/GoogleDot-Black || mkdir -p $out/share/icons/GoogleDot-Black
  '';

  iconPkg = pkgs.runCommand "zenos-icons" { } ''
    mkdir -p $out/share/icons
    # [UPDATED] Path adjusted to ../../resources/
    cp -r ${../../resources/Adwaita-hacks} $out/share/icons/Adwaita-hacks || mkdir -p $out/share/icons/Adwaita-hacks
  '';

  # [FIX] GDM Logo Rasterizer: Bakes SVG to high-res PNG
  gdmLogoPkg =
    pkgs.runCommand "zenos-gdm-logo"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        mkdir -p $out/share/pixmaps
        # [UPDATED] Path adjusted to ../../resources/
        magick -background none -density 2400 ${../../resources/plymouth/zenos.svg} \
          -resize 256x256 $out/share/pixmaps/zenos-gdm.png
      '';

  mimePkg = pkgs.runCommand "zenos-mimetypes" { } ''
    mkdir -p $out/share/mime/packages
    # [UPDATED] Path adjusted to ../../resources/
    cp -r ${../../resources/mimetypes}/* $out/ || true
  '';

  # Helper for creating game/emulator launchers
  mkAssoc =
    name: exec: mimes:
    pkgs.makeDesktopItem {
      name = "zeroplay-assoc-${name}";
      desktopName = "ZeroPlay: ${name}";
      genericName = "Emulator";
      comment = "Launch with ${name}";
      icon = name;
      inherit exec;
      categories = [
        "Game"
        "Emulator"
      ];
      mimeTypes = mimes;
    };

  emulatorAssocs = [
    (mkAssoc "yuzu" "yuzu %f" [ "application/x-switch-rom" ])
    (mkAssoc "pcsx2" "pcsx2 %f" [ "application/x-ps2-rom" ])
    (mkAssoc "rpcs3" "rpcs3 %f" [ "application/x-ps3-rom" ])
    (mkAssoc "duckstation" "duckstation %f" [ "application/x-ps1-rom" ])
    (mkAssoc "simple64" "simple64 %f" [ "application/x-n64-rom" ])
    (mkAssoc "dolphin" "dolphin-emu %f" [
      "application/x-gamecube-rom"
      "application/x-wii-rom"
    ])
    (mkAssoc "citra" "citra %f" [ "application/x-nintendo-3ds-rom" ])
    (mkAssoc "flycast" "flycast %f" [ "application/x-dreamcast-rom" ])
    (mkAssoc "xemu" "xemu %f" [ "application/x-xbox-rom" ])
    (mkAssoc "xenia" "xenia %f" [ "application/x-xbox360-rom" ])
    (mkAssoc "mesen" "mesen %f" [ "application/x-nes-rom" ])
    (mkAssoc "bsnes" "bsnes %f" [ "application/x-snes-rom" ])
    (mkAssoc "retroarch" "retroarch %f" [
      "application/x-genesis-rom"
      "application/x-saturn-rom"
      "application/x-gba-rom"
      "application/x-gameboy-rom"
      "application/x-gameboy-color-rom"
      "application/x-nintendo-ds-rom"
      "application/x-wiiu-rom"
    ])
  ];

in
{
  # ============================================================================
  # [ SYSTEM CONFIGURATION ]
  # ============================================================================

  # 1. Fonts
  fonts = {
    packages = with pkgs; [
      atkinson-hyperlegible-next
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.atkynson-mono
      zeroFontPkg
    ];

    fontDir.enable = true;

    fontconfig = {
      defaultFonts = {
        monospace = [ "AtkynsonMono NF" ];
        sansSerif = [
          "Atkinson Hyperlegible Next"
          "Symbols Nerd Font"
        ];
        serif = [ "Noto Serif" ];
      };
    };
  };

  # 2. Qt and GTK Styling (System Level)
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  environment.sessionVariables = {
    XCURSOR_THEME = "GoogleDot-Black";
    XCURSOR_SIZE = "24";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    ZENOS_WALLPAPER = "${wallpaperPkg}/share/backgrounds/zenos/default.png";
  };

  # 3. System Packages for Theming
  environment.systemPackages =
    with pkgs;
    [
      iconPkg
      mimePkg
      cursorPkg
      wallpaperPkg
      gdmLogoPkg
      adw-gtk3
      adwaita-qt
      adwaita-qt6
      gnome-themes-extra
      libsForQt5.qt5ct
    ]
    ++ emulatorAssocs;

  boot.plymouth.enable = true;

  # ============================================================================
  # [ GDM CONFIGURATION ]
  # ============================================================================
  programs.dconf.profiles.gdm.databases = [
    {
      settings = {
        "org/gnome/login-screen" = {
          logo = "${gdmLogoPkg}/share/pixmaps/zenos-gdm.png";
        };
        "org/gnome/desktop/interface" = {
          accent-color = "purple";
          cursor-theme = "GoogleDot-Black";
          icon-theme = "Adwaita-hacks";
          font-name = "Atkinson Hyperlegible Next 11";
          color-scheme = "prefer-dark";
        };
      };
    }
  ];

  # ============================================================================
  # [ FIREFOX & PWA FIX ]
  # ============================================================================

  environment.etc = {
    "firefox/gnome-theme".source = gnomeThemeRepo;
    "firefox/custom/userChrome.css".source = customChromeCss;
  };

  # Profile Rescue Script
  system.activationScripts.firefoxProfileRescue = {
    text = ''
      for user_home in /home/*; do
        p_ini="$user_home/.mozilla/firefox/profiles.ini"
        if [ -f "$p_ini" ] && [ ! -L "$p_ini" ]; then
          mv "$p_ini" "$p_ini.bak.$(date +%s)"
        fi
      done
    '';
  };

  # PWA Theming Script
  system.activationScripts.firefoxPwaTheming = {
    text = ''
      for pwa_root in /home/*/.local/share/firefoxpwa/profiles/*/; do
        [ -d "$pwa_root" ] || continue
        mkdir -p "$pwa_root/chrome"
        ln -sfn /etc/firefox/custom/userChrome.css "$pwa_root/chrome/" || true
        ln -sfn /etc/firefox/gnome-theme "$pwa_root/chrome/" || true
      done
    '';
  };

  # ============================================================================
  # [ FLATPAK OVERRIDES ]
  # ============================================================================

  services.flatpak.overrides = {
    global = {
      Context.filesystems = [
        "xdg-config/gtk-3.0:ro"
        "xdg-config/gtk-4.0:ro"
        "xdg-data/icons:ro"
        "xdg-data/themes:ro"
        "~/.icons:ro"
        "/nix/store:ro"
      ];
      Environment = {
        XCURSOR_THEME = "GoogleDot-Black";
        XCURSOR_SIZE = "24";
      };
    };
  }
  // (lib.genAttrs legacyGtk3Apps (app: {
    Environment = {
      GTK_THEME = "adw-gtk3-dark";
    };
  }));

  # ============================================================================
  # [ HOME MANAGER MODULE ]
  # ============================================================================
  home-manager.sharedModules = [
    (
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        xdg.configFile."gtk-3.0/settings.ini".force = true;
        xdg.configFile."gtk-4.0/settings.ini".force = true;

        gtk = {
          enable = true;
          iconTheme = {
            name = "Adwaita-hacks";
            package = iconPkg;
          };
          cursorTheme = {
            name = "GoogleDot-Black";
            size = 24;
            package = cursorPkg;
          };
          font = {
            name = "Atkinson Hyperlegible Next 11";
            package = pkgs.atkinson-hyperlegible-next;
          };
          gtk3.extraConfig = {
            gtk-theme-name = "adw-gtk3-dark";
            gtk-application-prefer-dark-theme = 1;
          };
          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
          };
        };

        home.pointerCursor = {
          package = cursorPkg;
          name = "GoogleDot-Black";
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };

        # Custom Shell Theme Override for Clock
        home.file.".local/share/themes/ClockOverride/gnome-shell/gnome-shell.css".text = ''
          @import url("resource:///org/gnome/shell/theme/default.css");
          .clock-display {
              font-family: 'ZeroClock', sans-serif !important;
              font-weight: normal !important;
              font-style: normal !important;
              font-size: 12px;
          }
        '';

        # Burn My Windows profile
        # [FIX] Source path updated to gnome/ subdirectory
        home.file.".config/burn-my-windows/profiles/bmw.conf".source = ../../resources/gnome/bmw.conf;

        # [Systemd Service]
        # This service applies the complex dconf settings once the session is ready.
        systemd.user.services.dconf-complex-apply = {
          Unit = {
            Description = "Apply complex dconf settings from raw files";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };

          Service = {
            Type = "oneshot";
            # [FIX] Read files from ../../resources/gnome/
            ExecStart = "${pkgs.writeShellScript "apply-dconf-complex" ''
              # Blur My Shell - Pipelines
              ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/blur-my-shell/pipelines ${lib.strings.escapeShellArg (builtins.readFile ../../resources/gnome/bms_settings.txt)}

              # Rounded Window Corners Reborn - Global Settings
              ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/rounded-window-corners-reborn/global-rounded-corner-settings ${lib.strings.escapeShellArg (builtins.readFile ../../resources/gnome/rwcr_settings.txt)}

              # GSConnect - Run Command List
              ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/runcommand/command-list ${lib.strings.escapeShellArg (builtins.readFile ../../resources/gnome/gsc_commands.txt)}
            ''}";
          };
        };

        dconf.settings = {
          "org/gnome/shell/extensions/user-theme" = {
            name = "ClockOverride";
          };
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            accent-color = "purple";
            gtk-theme = "adw-gtk3-dark";
            icon-theme = "Adwaita-hacks";
            cursor-theme = "GoogleDot-Black";
            font-name = lib.mkForce "Atkinson Hyperlegible Next 11";
            document-font-name = "Atkinson Hyperlegible Next 11";
            monospace-font-name = "AtkynsonMono NF 11";
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${wallpaperPkg}/share/backgrounds/zenos/default.png";
            picture-uri-dark = "file://${wallpaperPkg}/share/backgrounds/zenos/default.png";
            primary-color = "#000000";
            secondary-color = "#000000";
          };

          # [FIX] Use dynamic home directory instead of hardcoded user
          "org/gnome/shell/extensions/burn-my-windows" = {
            active-profile = "${config.home.homeDirectory}/.config/burn-my-windows/profiles/bmw.conf";
            last-extension-version = 47;
            last-prefs-version = 47;
            prefs-open-count = 2;
          };
        };

        home.file.".local/share/themes/adw-gtk3-dark".source =
          "${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark";
        home.file.".local/share/icons/Adwaita-hacks".source = "${iconPkg}/share/icons/Adwaita-hacks";

        xdg.configFile."gtk-3.0/gtk.css".text = ''
          @define-color accent_color #9141AC;
          @define-color accent_bg_color #9141AC;
          @define-color accent_fg_color #ffffff;
        '';
        xdg.configFile."gtk-4.0/gtk.css".text = ''
          @define-color accent_color #9141AC;
          @define-color accent_bg_color #9141AC;
          @define-color accent_fg_color #ffffff;
        '';

        programs.firefox = {
          enable = true;
          profiles.default = {
            id = 0;
            name = "default";
            isDefault = true;
            settings = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "svg.context-properties.content.enabled" = true;
              "gnomeTheme.hideSingleTab" = true;
              "browser.tabs.drawInTitlebar" = true;
              "widget.gtk.rounded-bottom-corners.enabled" = true;
              "layers.acceleration.force-enabled" = true;
              "gfx.webrender.all" = true;
            };
          };
        };

        home.file = {
          ".mozilla/firefox/default/chrome/userChrome.css".source = customChromeCss;
          ".mozilla/firefox/default/chrome/userContent.css".source = customContentCss;
          ".mozilla/firefox/default/chrome/gnome-theme".source = gnomeThemeRepo;
        };
      }
    )
  ];
}
