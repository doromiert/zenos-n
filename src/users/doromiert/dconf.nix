{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib.hm.gvariant)
    mkTuple
    mkUint32
    ;

  # Helper to create the nested variant structure: <{'position': <n>}>
  # The 'position' value inside is also a variant.
in
{
  # Provision the Burn My Windows profile
  home.file.".config/burn-my-windows/profiles/bmw.conf".source = ./resources/bmw.conf;

  # [Systemd Service]
  # We use a systemd user service instead of home.activation.
  # This ensures these commands run ONLY after the graphical session (and DBus) is ready.
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
      # We construct a script that runs dconf write for each complex key.
      # We use escapeShellArg to safely inject the raw file content.
      ExecStart = "${pkgs.writeShellScript "apply-dconf-complex" ''
        # Blur My Shell - Pipelines
        ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/blur-my-shell/pipelines ${lib.strings.escapeShellArg (builtins.readFile ./resources/bms_settings.txt)}

        # Rounded Window Corners Reborn - Global Settings
        ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/rounded-window-corners-reborn/global-rounded-corner-settings ${lib.strings.escapeShellArg (builtins.readFile ./resources/rwcr_settings.txt)}

        # GSConnect - Run Command List
        ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/runcommand/command-list ${lib.strings.escapeShellArg (builtins.readFile ./resources/gsc_commands.txt)}

        # GSConnect - Notifications
        # ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/notification/applications ${lib.strings.escapeShellArg (builtins.readFile ./resources/gsc_notifications.txt)}
      ''}";
    };
  };

  # Use the native dconf module for standard/simple GNOME settings
  dconf.settings = {
    # "org/gnome/desktop" = {
    #   app-folders = [
    #     "System"
    #     "YaST"
    #     "Pardus"
    #     "d4b55352-0853-4306-9cb0-4b01a00a9537"
    #   ];
    # };
    "org/gnome/shell" = {

      favorite-apps = [
        "firefox.desktop"
        "discord.desktop"
        "org.telegram.desktop.desktop"
        "figma.desktop"
        "code.desktop"
        "org.gnome.Nautilus.desktop"
        "kitty.desktop"
        "steam.desktop"
        "obsidian.desktop"
        "gemini.desktop"
      ];
    };
    # --- Alphabetical App Grid ---
    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = "end";
    };

    "org/gnome/shell/extensions/app-hider" = {
      hidden-apps = [ "vesktop.desktop" ];
    };

    # --- BlackBox Terminal ---
    "com/raggesilver/BlackBox" = {
      floating-controls = true;
      font = "Atkynson Mono NF 11";
      show-headerbar = false;
      terminal-padding = mkTuple [
        (mkUint32 5)
        (mkUint32 5)
        (mkUint32 5)
        (mkUint32 5)
      ];
      window-height = mkUint32 744;
      window-width = mkUint32 828;
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
      active-profile = "${config.home.homeDirectory}/.config/burn-my-windows/profiles/bmw.conf";
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
      switcher-background-color = mkTuple [
        1.0
        1.0
        1.0
      ];
      use-glitch-effect = true;
    };

    # --- Forge ---
    "org/gnome/shell/extensions/forge" = {
      css-last-update = mkUint32 37;
      dnd-center-layout = "swap";
      float-always-on-top-enabled = false;
      focus-border-toggle = false;
      quick-settings-enabled = false;
      split-border-toggle = false;
      stacked-tiling-mode-enabled = false;
      tabbed-tiling-mode-enabled = false;
      window-gap-size = mkUint32 4;
    };

    "org/gnome/shell/extensions/gsconnect/preferences" = {
      window-maximized = false;
      window-size = mkTuple [
        945
        478
      ];
    };

    # --- Hide Top Bar ---
    "org/gnome/shell/extensions/hidetopbar" = {
      enable-intellihide = false;
      mouse-sensitive = true;
      mouse-sensitive-fullscreen-window = false;
    };

    # --- Rounded Corners ---
    "org/gnome/shell/extensions/lennart-k/rounded_corners" = {
      corner-radius = 24;
    };

    # --- Media Controls ---
    "org/gnome/shell/extensions/mediacontrols" = {
      extension-index = mkUint32 1;
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
      # global-rounded-corner-settings handled by systemd service
      settings-version = mkUint32 7;
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
