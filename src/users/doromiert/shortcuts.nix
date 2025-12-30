# shortcuts ended up being so massive i moved them here
{ config, pkgs, ... }:{

    dconf.settings = {
        # --- System Shortcuts ---
        "org/gnome/desktop/wm/keybindings" = {
            close = [ "<Super>q" ];
            maximize = [ "<Super>w" ];
            minimize = [ "<Super>Page_Down" ];
            activate-window-menu = [ "<Super>space" ];
            
            # Workspaces
            switch-to-workspace-left = [ "<Super><Control>Left" ];
            switch-to-workspace-right = [ "<Super><Control>Right" ];
            move-to-workspace-left = [ "<Super><Control><Shift>Left" ];
            move-to-workspace-right = [ "<Super><Control><Shift>Right" ];

            # Monitors
            move-to-monitor-left = [ "<Super><Alt>Left" ];
            move-to-monitor-right = [ "<Super><Alt>Right" ];

            # Input
            switch-input-source = [ "<Super>space" ];
            switch-input-source-backward = [ "<Shift><Super>space" ];
        };

        "org/gnome/shell/keybindings" = {
            # Notification Center (Calendar/Notifications)
            toggle-message-tray = [ "<Super>v" ];
        };

        # --- Custom Keybindings (Apps) ---
        "org/gnome/settings-daemon/plugins/media-keys" = {
            custom-keybindings = [
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
            ];
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            name = "Nautilus";
            command = "nautilus --new-window";
            binding = "<Super>e";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
            name = "Black Box";
            command = "flatpak run com.raggesilver.BlackBox"; # Verify binary name (sometimes 'com.raggesilver.BlackBox')
            binding = "<Super>t";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
            name = "Buffer";
            command = "flatpak run org.gnome.gitlab.cheywood.Buffer"; # Replace with actual binary command
            binding = "<Super>b";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
            name = "System Resources";
            command = "flatpak run net.nokyan.Resources"; # Requires 'resources' package
            binding = "<Control><Shift>Escape";
        };

        # --- Extensions ---
        
        # Clipboard Indicator
        "org/gnome/shell/extensions/clipboard-indicator" = {
            toggle-menu = [ "<Super><Control>v" ];
        };

        # Forge (Tiling)
        "org/gnome/shell/extensions/forge/keybindings" = {
            float-window-toggle = [ "<Super>f" ];
            window-move-left = [ "<Super><Shift>Left" ];
            window-move-right = [ "<Super><Shift>Right" ];
            window-move-up = [ "<Super><Shift>Up" ];
            window-move-down = [ "<Super><Shift>Down" ];
        };
    };
}