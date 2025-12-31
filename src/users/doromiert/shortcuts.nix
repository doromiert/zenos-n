{ config, pkgs, ... }:

{
  dconf.settings = {
    # --- System Shortcuts ---
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      toggle-maximized = [ "<Super>w" ];
      minimize = [ "<Super>Page_Down" ];
      activate-window-menu = [ "<Alt>space" ];

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
      command = "flatpak run com.raggesilver.BlackBox";
      binding = "<Super>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Buffer";
      command = "flatpak run org.gnome.gitlab.cheywood.Buffer";
      binding = "<Super>b";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name = "System Resources";
      command = "flatpak run net.nokyan.Resources";
      binding = "<Control><Shift>Escape";
    };

    # --- Extensions ---

    # Clipboard Indicator
    "org/gnome/shell/extensions/clipboard-indicator" = {
      toggle-menu = [ "<Control><Super>v" ];
    };

    # Forge (Tiling)
    "org/gnome/shell/extensions/forge/keybindings" = {
      con-split-horizontal = [ ];
      con-split-layout-toggle = [ ];
      con-split-vertical = [ ];
      con-stacked-layout-toggle = [ ];
      con-tabbed-layout-toggle = [ ];
      con-tabbed-showtab-decoration-toggle = [ ];
      focus-border-toggle = [ ];
      prefs-open = [ ];
      prefs-tiling-toggle = [ ];
      window-focus-down = [ "<Super>Down" ];
      window-focus-left = [ "<Super>Left" ];
      window-focus-right = [ "<Super>Right" ];
      window-focus-up = [ "<Super>Up" ];
      window-gap-size-decrease = [ ];
      window-gap-size-increase = [ ];
      window-move-down = [ "<Shift><Super>Down" ];
      window-move-left = [ "<Shift><Super>Left" ];
      window-move-right = [ "<Shift><Super>Right" ];
      window-move-up = [ "<Shift><Super>Up" ];
      window-resize-bottom-decrease = [ ];
      window-resize-bottom-increase = [ ];
      window-resize-left-decrease = [ ];
      window-resize-left-increase = [ ];
      window-resize-right-decrease = [ ];
      window-resize-right-increase = [ ];
      window-resize-top-decrease = [ ];
      window-resize-top-increase = [ ];
      window-snap-center = [ ];
      window-snap-one-third-left = [ ];
      window-snap-one-third-right = [ ];
      window-snap-two-third-left = [ ];
      window-snap-two-third-right = [ ];
      window-swap-down = [ ];
      window-swap-last-active = [ ];
      window-swap-left = [ ];
      window-swap-right = [ ];
      window-swap-up = [ ];
      window-toggle-always-float = [ "<Super><Shift>f" ];
      window-toggle-float = [ "<Super>f" ];
      workspace-active-tile-toggle = [ ];
    };
  };
}
