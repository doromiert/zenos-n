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
        rounded-window-corners
        blur-my-shell
        
        # UX / Navigation
        alphabetical-app-grid
        category-sorted-app-grid
        coverflow-alt-tab
        hide-top-bar
        mouse-tail
        tweaks-system-menu
        
        # System
        gsconnect
        clipboard-indicator
        notification-timeout
        
        # Utilities used in previous version
        appindicator
        dash-to-dock
        just-perfection
    ];
in
{
    # 1. Core Desktop Services
    services = {
        xserver = {
            enable = true;
            displayManager.gdm.enable = true;
            desktopManager.gnome.enable = true;
        };
        
        # Ensure standard GNOME services are running
        udev.packages = with pkgs; [ gnome-settings-daemon ];
    };

    # 2. System-wide Packages (Extensions and Tools)
    environment = {
        systemPackages = with pkgs; [
            gnome-tweaks
            gnome-extension-manager
            wl-clipboard # Useful for Wayland GNOME
        ] ++ extensions;

        # Remove default GNOME bloat for all users
        gnome.excludePackages = (with pkgs; [
            gnome-photos
            gnome-tour
            gedit
        ]) ++ (with pkgs.gnome; [
            cheese
            gnome-music
            gnome-maps
            epiphany
            gnome-contacts
            gnome-weather
        ]);
    };

    # 3. Declarative GSettings (Dconf) for All Users
    programs.dconf = {
        enable = true;
        profiles.user.databases = [{
            settings = {
                # Global Interface Settings
                "org/gnome/desktop/interface" = {
                    color-scheme = "prefer-dark";
                    enable-hot-corners = false;
                    clock-show-weekday = true;
                };

                # Shell & Extension Management
                "org/gnome/shell" = {
                    disable-user-extensions = false;
                    
                    # Dynamically map the UUIDs of the extensions installed above
                    enabled-extensions = map (ext: ext.extensionUuid) extensions;
                    
                    favorite-apps = [
                        "firefox.desktop"
                        "org.gnome.Nautilus.desktop"
                        "org.gnome.Console.desktop"
                        "code.desktop"
                    ];
                };

                # Extension Specific Defaults
                "org/gnome/shell/extensions/dash-to-dock" = {
                    dock-position = "BOTTOM";
                    extend-height = false;
                    dash-max-icon-size = 48;
                };

                "org/gnome/shell/extensions/forge" = {
                    tiling-mode-enabled = true;
                };

                "org/gnome/shell/extensions/hidetopbar" = {
                    enable-active-window-hits = true;
                };
            };
        }];
    };

    # 4. Font Configuration (Optimized for GNOME)
    fonts = {
        packages = with pkgs; [
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-emoji
            font-awesome
            (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
        ];
        fontconfig = {
            defaultFonts = {
                serif = [ "Noto Serif" ];
                sansSerif = [ "Noto Sans" ];
                monospace = [ "JetBrainsMono Nerd Font" ];
            };
        };
    };
}