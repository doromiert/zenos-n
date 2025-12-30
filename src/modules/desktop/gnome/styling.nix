{ config, pkgs, inputs, ... }:

let
  # -- Helper: Package Local Resources --
  cursorPkg = pkgs.runCommand "zenos-cursor" {} ''
    mkdir -p $out/share/icons
    cp -r ${../../resources/GoogleDot-Black} $out/share/icons/GoogleDot-Black
  '';

  iconPkg = pkgs.runCommand "zenos-icons" {} ''
    mkdir -p $out/share/icons
    cp -r ${../../resources/Adwaita-hacks} $out/share/icons/Adwaita-hacks
  '';

  # [ ! ] Installs the Custom Mime XML
  # NixOS will automatically run update-mime-database when this is in systemPackages
  mimePkg = pkgs.runCommand "zenos-mimetypes" {} ''
    mkdir -p $out/share/mime/packages
    # Copies your structure: resources/mimetypes/share/mime/packages/zenos-custom.xml
    cp -r ${../../resources/mimetypes}/* $out/
  '';

  # -- Helper: Emulator Association Generator --
  # Creates individual .desktop files for "Open With" support based on your Python script
  mkAssoc = name: exec: mimes: pkgs.makeDesktopItem {
    name = "zeroplay-assoc-${name}";
    desktopName = "ZeroPlay: ${name}";
    genericName = "Emulator";
    comment = "Launch with ${name}";
    icon = name; # Matches the svg icon names
    inherit exec;
    categories = [ "Game" "Emulator" ];
    mimeTypes = mimes;
  };

  # -- Mappings derived from zeroplay-manager.py --
  emulatorAssocs = [
    # Modern / High Level
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
    
    # Classics (Standalone preference)
    (mkAssoc "mesen"       "mesen %f"       [ "application/x-nes-rom" ])
    (mkAssoc "bsnes"       "bsnes %f"       [ "application/x-snes-rom" ])

    # RetroArch Fallbacks (Systems where Core usage is standard or wrapper script implied)
    # Includes: Genesis, Saturn, GBA, GB, GBC, DS, Wii U (Cemu often runs via Wine/RA)
    (mkAssoc "retroarch"   "retroarch %f"   [ 
      "application/x-genesis-rom"
      "application/x-saturn-rom"
      "application/x-gba-rom"
      "application/x-gameboy-rom"
      "application/x-gameboy-color-rom"
      "application/x-nintendo-ds-rom"
      "application/x-wiiu-rom" 
    ])
  ];

  wallpaper = ../../resources/wallpapers/default.png;
in
{
  # ---------------------------------------------------------------------------
  # ZenOS 1.0N: Styling (Stylix)
  # ---------------------------------------------------------------------------
  stylix = {
    enable = true;
    image = wallpaper; 
    polarity = "dark";

    cursor = {
      package = cursorPkg;
      name = "GoogleDot-Black";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.atkinson-hyperlegible-mono;
        name = "Atkinson Hyperlegible Mono";
      };
      sansSerif = {
        package = pkgs.atkinson-hyperlegible;
        name = "Atkinson Hyperlegible";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      
      sizes = {
        terminal = 12;
        applications = 10;
        desktop = 10;
      };
    };
  };

  # -- Apply System Packages --
  # These are added to system-wide environment
  environment.systemPackages = [ 
    iconPkg 
    mimePkg 
  ] ++ emulatorAssocs; # Expands the list of desktop items

  # -- User Interface Config (Dconf) --
  home-manager.users.doromiert = { pkgs, ... }: {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        icon-theme = "Adwaita-hacks";
      };
    };
  };

  # -- Boot Animation --
  boot.plymouth.enable = true;
}