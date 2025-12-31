{ config, pkgs, lib, ... }:

let
    # -- Helper: Package Local Resources --
    cursorPkg = pkgs.runCommand "zenos-cursor" {} ''
        mkdir -p $out/share/icons
        cp -r ${../../../../resources/GoogleDot-Black} $out/share/icons/GoogleDot-Black
    '';

    iconPkg = pkgs.runCommand "zenos-icons" {} ''
        mkdir -p $out/share/icons
        cp -r ${../../../../resources/Adwaita-hacks} $out/share/icons/Adwaita-hacks
    '';

    mimePkg = pkgs.runCommand "zenos-mimetypes" {} ''
        mkdir -p $out/share/mime/packages
        cp -r ${../../../../resources/mimetypes}/* $out/
    '';

    mkAssoc = name: exec: mimes: pkgs.makeDesktopItem {
        name = "zeroplay-assoc-${name}";
        desktopName = "ZeroPlay: ${name}";
        genericName = "Emulator";
        comment = "Launch with ${name}";
        icon = name;
        inherit exec;
        categories = [ "Game" "Emulator" ];
        mimeTypes = mimes;
    };

    emulatorAssocs = [
        (mkAssoc "yuzu"        "yuzu %f"        [ "application/x-switch-rom" ])
        (mkAssoc "pcsx2"       "pcsx2 %f"       [ "application/x-ps2-rom" ])
        (mkAssoc "rpcs3"       "rpcs3 %f"       [ "application/x-ps3-rom" ])
        (mkAssoc "duckstation" "duckstation %f" [ "application/x-ps1-rom" ])
        (mkAssoc "simple64"    "simple64 %f"    [ "application/x-n64-rom" ])
        (mkAssoc "dolphin"     "dolphin-emu %f" [ "application/x-gamecube-rom" "application/x-wii-rom" ])
        (mkAssoc "citra"       "citra %f"       [ "application/x-nintendo-3ds-rom" ])
        (mkAssoc "flycast"     "flycast %f"     [ "application/x-dreamcast-rom" ])
        (mkAssoc "xemu"        "xemu %f"        [ "application/x-xbox-rom" ])
        (mkAssoc "xenia"       "xenia %f"       [ "application/x-xbox360-rom" ])
        (mkAssoc "mesen"       "mesen %f"       [ "application/x-nes-rom" ])
        (mkAssoc "bsnes"       "bsnes %f"       [ "application/x-snes-rom" ])
        (mkAssoc "retroarch"   "retroarch %f"   [ 
            "application/x-genesis-rom" "application/x-saturn-rom"
            "application/x-gba-rom" "application/x-gameboy-rom"
            "application/x-gameboy-color-rom" "application/x-nintendo-ds-rom"
            "application/x-wiiu-rom" 
        ])
    ];
in
{
    # 1. Fonts Configuration (System-wide)
    fonts = {
        packages = with pkgs; [
            atkinson-hyperlegible
            atkinson-hyperlegible-mono
            noto-fonts
            noto-fonts-color-emoji
        ];
        fontconfig = {
            defaultFonts = {
                monospace = [ "Atkinson Hyperlegible Mono" ];
                sansSerif = [ "Atkinson Hyperlegible" ];
                serif     = [ "Noto Serif" ];
            };
        };
    };

    # 2. Qt and GTK Styling
    qt = {
        enable = true;
        platformTheme = "gnome"; 
        style = "adwaita-dark";
    };

    # 3. System Packages
    environment.systemPackages = with pkgs; [ 
        iconPkg 
        mimePkg
        cursorPkg
        
        # Theming Packages
        adw-gtk3              # Required for GTK_THEME="adw-gtk3-dark"
        adwaita-qt            # Qt5 style
        adwaita-qt6           # Qt6 style
        gnome-themes-extra    # Standard Adwaita fallback
    ] ++ emulatorAssocs;

    # 4. Global Environment Variables (For Cursors/Themes)
    # Applying to both Host apps and Flatpaks
    environment.sessionVariables = {
        # Cursor
        XCURSOR_THEME = "GoogleDot-Black";
        XCURSOR_SIZE = "24";

        # GTK3 Theme Force (Host + Flatpak)
        GTK_THEME = "adw-gtk3-dark";

        # Qt Style Force (Host + Flatpak)
        QT_STYLE_OVERRIDE = "adwaita-dark";
    };

    # 5. User-specific Overrides (via Home Manager)
    home-manager.users.doromiert = { ... }: {
        home.pointerCursor = {
            package = cursorPkg;
            name = "GoogleDot-Black";
            size = 24;
            gtk.enable = true;
            x11.enable = true;
        };

        dconf.settings = {
            "org/gnome/desktop/interface" = {
                icon-theme = "Adwaita-hacks";
                cursor-theme = "GoogleDot-Black";
                font-name = "Atkinson Hyperlegible 11";
                document-font-name = "Atkinson Hyperlegible 11";
                monospace-font-name = "Atkinson Hyperlegible Mono 11";
            };
        };
    };

    # 6. Boot Animation
    boot.plymouth.enable = true;
}