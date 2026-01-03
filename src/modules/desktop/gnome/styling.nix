{
  pkgs,
  lib,
  config,
  ...
}:

let
  # ============================================================================
  # [ TARGETED APPS ]
  # List of Legacy GTK3 Flatpaks that NEED the theme override.
  # LibAdwaita apps (Flatseal, Amberol, etc.) MUST NOT be in this list.
  # ============================================================================
  legacyGtk3Apps = [
    # Examples (Uncomment if you use them):
    # "org.gimp.GIMP"
    # "org.inkscape.Inkscape"
    # "org.libreoffice.LibreOffice"
    # "com.github.rafostar.Clapper"
  ];

  # ============================================================================
  # [ HELPER PACKAGES ]
  # Custom derivations for assets to keep the store clean.
  # ============================================================================

  wallpaperPkg = pkgs.runCommand "zenos-wallpapers" { } ''
    dest=$out/share/backgrounds/zenos
    mkdir -p $dest
    mkdir -p $out/share/gnome-background-properties

    # Copy all wallpapers (Ensure path exists in your repo)
    cp -r ${../../../../resources/wallpapers}/* $dest/ || echo "Warning: Wallpapers not found"

    # Generate XML for GNOME Settings
    echo '<?xml version="1.0"?>' > $out/share/gnome-background-properties/zenos.xml
    echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">' >> $out/share/gnome-background-properties/zenos.xml
    echo '<wallpapers>' >> $out/share/gnome-background-properties/zenos.xml

    for img in "$dest"/*.{png,jpg,jpeg}; do
        [ -e "$img" ] || continue
        filename=$(basename "$img")
        name="''${filename%.*}"
        
        printf "  <wallpaper>\n" >> $out/share/gnome-background-properties/zenos.xml
        printf "    <name>ZenOS: %s</name>\n" "$name" >> $out/share/gnome-background-properties/zenos.xml
        printf "    <filename>%s</filename>\n" "$img" >> $out/share/gnome-background-properties/zenos.xml
        printf "    <options>zoom</options>\n" >> $out/share/gnome-background-properties/zenos.xml
        printf "  </wallpaper>\n" >> $out/share/gnome-background-properties/zenos.xml
    done

    echo '</wallpapers>' >> $out/share/gnome-background-properties/zenos.xml
  '';

  cursorPkg = pkgs.runCommand "zenos-cursor" { } ''
    mkdir -p $out/share/icons
    # Ensure path exists in your repo
    cp -r ${../../../../resources/GoogleDot-Black} $out/share/icons/GoogleDot-Black || mkdir -p $out/share/icons/GoogleDot-Black
  '';

  iconPkg = pkgs.runCommand "zenos-icons" { } ''
    mkdir -p $out/share/icons
    # Ensure path exists in your repo
    cp -r ${../../../../resources/Adwaita-hacks} $out/share/icons/Adwaita-hacks || mkdir -p $out/share/icons/Adwaita-hacks
  '';

  mimePkg = pkgs.runCommand "zenos-mimetypes" { } ''
    mkdir -p $out/share/mime/packages
    # Ensure path exists in your repo
    cp -r ${../../../../resources/mimetypes}/* $out/ || true
  '';

  # ============================================================================
  # [ DESKTOP ASSOCIATIONS ]
  # Helper for creating game/emulator launchers
  # ============================================================================

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
  # [ SYSTEM-WIDE CONFIGURATION ]
  # ============================================================================

  # 1. Fonts
  fonts = {
    packages = with pkgs; [
      atkinson-hyperlegible
      atkinson-hyperlegible-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      monospace = [ "Atkinson Hyperlegible Mono" ];
      sansSerif = [ "Atkinson Hyperlegible" ];
      serif = [ "Noto Serif" ];
    };
  };

  # 2. Qt and GTK Styling (System Variables)
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  environment.sessionVariables = {
    XCURSOR_THEME = "GoogleDot-Black";
    XCURSOR_SIZE = "24";

    # [ REMOVED ] GTK_THEME = "adw-gtk3-dark";
    # This was causing layout breakage in Native LibAdwaita apps (RNote, etc.)
    # Legacy apps will now correctly rely on the Home Manager settings.ini file instead.

    QT_STYLE_OVERRIDE = "adwaita-dark";
    ZENOS_WALLPAPER = "${wallpaperPkg}/share/backgrounds/zenos/default.png";
  };

  # 3. System Packages
  environment.systemPackages =
    with pkgs;
    [
      iconPkg
      mimePkg
      cursorPkg
      wallpaperPkg
      adw-gtk3
      adwaita-qt
      adwaita-qt6
      gnome-themes-extra
      libsForQt5.qt5ct
    ]
    ++ emulatorAssocs;

  # 4. Boot Animation
  boot.plymouth.enable = true;

  # ============================================================================
  # [ FLATPAK CONFIGURATION ]
  # Using gmodena/nix-flatpak declarative options.
  # ============================================================================

  services.flatpak.enable = true;

  # We merge the GLOBAL settings with the TARGETED APP settings
  services.flatpak.overrides = {

    # 1. Global Safe Defaults (Applies to everyone, including LibAdwaita)
    global = {
      Context = {
        filesystems = [
          "xdg-config/gtk-3.0:ro"
          "xdg-config/gtk-4.0:ro"
          "xdg-data/icons:ro"
          "xdg-data/themes:ro"
          "~/.icons:ro"
          # [ CRITICAL FIX ]
          # Mount /nix/store read-only.
          # Home Manager config files are symlinks into the store.
          # Without this, Flatpaks see the symlink but cannot read the target,
          # causing them to fail reading 'settings.ini' (Dark Mode preference).
          "/nix/store:ro"
        ];

        # Prevent Host Environment Leakage (Fixes BlackBox crash)
        unset-environment = [
          "NIX_LD"
          "NIX_LD_LIBRARY_PATH"
          "LD_LIBRARY_PATH"
        ];
      };

      Environment = {
        # Note: GTK_THEME is REMOVED from here to fix padding issues!
        XCURSOR_THEME = "GoogleDot-Black";
        XCURSOR_SIZE = "24";
      };
    };

  }
  # 2. Dynamically Generate Overrides for Legacy GTK3 Apps
  // (lib.genAttrs legacyGtk3Apps (app: {
    Environment = {
      GTK_THEME = "adw-gtk3-dark";
    };
  }));

  # ============================================================================
  # [ HOME MANAGER SHARED MODULE ]
  # Applies to ALL users managed by Home Manager
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

        # [ STABILITY FIX ]
        # Force overwrite GTK settings.ini to prevent "backup clobbered" errors.
        # This handles cases where GNOME or Apps regenerate these files, causing HM to fail.
        xdg.configFile."gtk-3.0/settings.ini".force = true;
        xdg.configFile."gtk-4.0/settings.ini".force = true;

        # 1. GTK Module
        gtk = {
          enable = true;

          # [ CRITICAL CHANGE ]
          # Do NOT set global theme.name here.
          # Setting it globally forces it into ~/.config/gtk-4.0/settings.ini,
          # which breaks LibAdwaita apps because they don't support custom themes.
          # theme = { ... }; <--- REMOVED

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
            name = "Atkinson Hyperlegible 11";
            package = pkgs.atkinson-hyperlegible;
          };

          # [ GTK3 SPECIFIC ]
          # Apply adw-gtk3 ONLY to GTK3 apps. They need it to match the system style.
          gtk3.extraConfig = {
            gtk-theme-name = "adw-gtk3-dark";
            gtk-application-prefer-dark-theme = 1;
          };

          # [ GTK4 / LIBADWAITA ]
          # Do NOT set gtk-theme-name. LibAdwaita uses its internal engine.
          # We only set the dark theme preference signal.
          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
          };
        };

        # 2. Pointer Cursor
        home.pointerCursor = {
          package = cursorPkg;
          name = "GoogleDot-Black";
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };

        # 3. DConf Settings
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            icon-theme = "Adwaita-hacks";
            cursor-theme = "GoogleDot-Black";
            font-name = lib.mkForce "Atkinson Hyperlegible 11";
            document-font-name = "Atkinson Hyperlegible 11";
            monospace-font-name = "Atkinson Hyperlegible Mono 11";
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${wallpaperPkg}/share/backgrounds/zenos/default.png";
            picture-uri-dark = "file://${wallpaperPkg}/share/backgrounds/zenos/default.png";
            primary-color = "#000000";
            secondary-color = "#000000";
          };
        };

        # 4. [ THE BRIDGE ] Symlink Themes for Flatpak Access
        home.file.".local/share/themes/adw-gtk3-dark".source =
          "${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark";
        home.file.".local/share/icons/Adwaita-hacks".source = "${iconPkg}/share/icons/Adwaita-hacks";
      }
    )
  ];
}
