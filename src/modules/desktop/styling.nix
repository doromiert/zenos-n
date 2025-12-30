# will contain the default theming
{ config, pkgs, inputs, ... }: let
    # -- Helper: Package Local Resources --
    # Wraps your local resource folders into Nix packages for Stylix
    
    cursorPkg = pkgs.runCommand "zenos-cursor" {} ''
        mkdir -p $out/share/icons
        cp -r ${../../resources/GoogleDot-Black} $out/share/icons/GoogleDot-Black
    '';

    iconPkg = pkgs.runCommand "zenos-icons" {} ''
        mkdir -p $out/share/icons
        cp -r ${../../resources/Adwaita-hacks} $out/share/icons/Adwaita-hacks
    '';

    # Define the wallpaper path once
    wallpaper = ../../resources/wallpapers/default.png;
in {
    # ---------------------------------------------------------------------------
    # ZenOS 1.0N: Styling (Stylix)
    # ---------------------------------------------------------------------------

    stylix = {
        enable = true;
        
        # -- Base Image & Scheme --
        # Stylix generates the base16 scheme automatically from this image
        image = wallpaper; 
        polarity = "dark";

        # -- Cursor --
        cursor = {
        package = cursorPkg;
        name = "GoogleDot-Black";
        size = 24;
        };

        # -- Fonts --
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

    # -- Icon Theme --
    # Stylix doesn't have a direct "iconTheme" option for system-wide GTK yet in all versions,
    # but we can force it via GTK settings if needed. 
    # For now, we ensure the package is installed.
    environment.systemPackages = [ iconPkg ];

    # -- Boot Animation (Plymouth) --
    boot.plymouth = {
        enable = true;
    };
}