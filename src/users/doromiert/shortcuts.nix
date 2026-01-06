{ config, pkgs, ... }:

{
  dconf.settings = {
    # --- System Shortcuts ---
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      # [RESIZING] Updated to Ctrl+Shift+C per user request
      toggle-maximized = [ "<Control><Shift>c" ];
      minimize = [ "<Super>Page_Down" ];
      activate-window-menu = [ "<Alt>space" ];

      # [CONFLICT REMOVAL]
      # Disable default Gnome tiling keys to prevent interference with Forge
      maximize = [ ];
      unmaximize = [ ];

      # Workspaces (HJKL)
      switch-to-workspace-left = [ "<Super><Control>h" ];
      switch-to-workspace-right = [ "<Super><Control>l" ];
      move-to-workspace-left = [ "<Super><Control><Shift>h" ];
      move-to-workspace-right = [ "<Super><Control><Shift>l" ];

      # Monitors (HJKL)
      move-to-monitor-left = [ "<Super><Alt>h" ];
      move-to-monitor-right = [ "<Super><Alt>l" ];

      # Input
      switch-input-source = [ "<Super>space" ];
      switch-input-source-backward = [ "<Shift><Super>space" ];
    };

    # [CONFLICT REMOVAL] Disable side tiling
    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ ];
      toggle-tiled-right = [ ];
    };

    "org/gnome/shell/keybindings" = {
      # Notification Center (Calendar/Notifications)
      toggle-message-tray = [ "<Super>v" ];
    };

    # --- Custom Keybindings (Apps) ---
    "org/gnome/settings-daemon/plugins/media-keys" = {
      # [FIX] Remap Lock Screen to avoid conflict with <Super>l (Focus Right)
      screensaver = [ "<Super>Escape" ];

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
      command = "blackbox";
      binding = "<Super>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Buffer";
      command = "flatpak run org.gnome.gitlab.cheywood.Buffer";
      binding = "<Super>b";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name = "System Resources";
      command = "resources";
      binding = "<Control><Shift>Escape";
    };

    # --- Extensions ---

    # Clipboard Indicator
    "org/gnome/shell/extensions/clipboard-indicator" = {
      toggle-menu = [ "<Control><Super>v" ];
    };

    # Forge (Tiling) - HJKLified
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

      # Focus (HJKL)
      window-focus-left = [ "<Super>h" ];
      window-focus-down = [ "<Super>j" ];
      window-focus-up = [ "<Super>k" ];
      window-focus-right = [ "<Super>l" ];

      window-gap-size-decrease = [ ];
      window-gap-size-increase = [ ];

      # Move (Shift + HJKL)
      window-move-left = [ "<Shift><Super>h" ];
      window-move-down = [ "<Shift><Super>j" ];
      window-move-up = [ "<Shift><Super>k" ];
      window-move-right = [ "<Shift><Super>l" ];

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

  # --- VS Code Keybindings ---
  programs.vscode.keybindings = [
    # NAVIGATION
    {
      key = "ctrl+shift+a";
      command = "workbench.action.terminal.focusNext";
      when = "terminalFocus";
    }
    {
      key = "ctrl+shift+b";
      command = "workbench.action.terminal.focusPrevious";
      when = "terminalFocus";
    }
    {
      key = "ctrl+shift+j";
      command = "workbench.action.togglePanel";
    }
    {
      key = "ctrl+shift+n";
      command = "workbench.action.terminal.new";
      when = "terminalFocus";
    }
    {
      key = "ctrl+shift+w";
      command = "workbench.action.terminal.kill";
      when = "terminalFocus";
    }
    # FILE TREE
    {
      command = "workbench.action.toggleSidebarVisibility";
      key = "ctrl+e";
    }
    {
      command = "workbench.files.action.focusFilesExplorer";
      key = "ctrl+e";
      when = "editorTextFocus";
    }
    {
      key = "n";
      command = "explorer.newFile";
      when = "filesExplorerFocus && !inputFocus";
    }
    {
      command = "renameFile";
      key = "r";
      when = "filesExplorerFocus && !inputFocus";
    }
    {
      key = "shift+n";
      command = "explorer.newFolder";
      when = "explorerViewletFocus";
    }
    {
      key = "shift+n";
      command = "workbench.action.newWindow";
      when = "!explorerViewletFocus";
    }

    {
      key = "ctrl+w";
      command = "workbench.action.closeActiveEditor";
    }
    {
      command = "deleteFile";
      key = "d";
      when = "filesExplorerFocus && !inputFocus";
    }
    # EXTRA
    {
      key = "ctrl+shift+5";
      command = "editor.emmet.action.matchTag";
    }
    {
      # [FIXED] Changed to avoid conflict with Undo (Ctrl+Z)
      key = "ctrl+alt+z";
      command = "workbench.action.toggleZenMode";
    }
    {
      key = "ctrl+shift+c";
      command = "workbench.action.toggleMaximizeEditorGroup";
    }
  ];
}
