{
  lib,
  pkgs,
  config,
  ...
}:

let
  mkUint32 = lib.hm.gvariant.mkUint32;
  mkTuple = lib.hm.gvariant.mkTuple;
in
{
  # Provision the Burn My Windows profile

  # [P13.A.4] Activation scripts for complex GVariant structures
  # This bypasses Home Manager's strict typing for complex dictionaries
  home.activation = {
    provisionBmwProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BMW_DIR="${config.home.homeDirectory}/.config/burn-my-windows/profiles"
      BMW_CONF="${./resources/bmw.conf}"

      # Ensure directory exists
      run mkdir -p "$BMW_DIR"

      # Force copy (overwrite existing symlink if present) and set writable
      run cp -fL "$BMW_CONF" "$BMW_DIR/bmw.conf"
      run chmod 644 "$BMW_DIR/bmw.conf"
    '';
    applyBmsPipelines = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/blur-my-shell/pipelines "$(cat ${./resources/bms_settings.txt})"
    '';

    applyRwcrSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/rounded-window-corners-reborn/global-rounded-corner-settings "$(cat ${./resources/rwcr_settings.txt})"
    '';

    applyGscCommands = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/runcommand/command-list "$(cat ${./resources/gsc_commands.txt})"
    '';

    applyGscNotifications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/notification/applications "$(cat ${./resources/gsc_notifications.txt})"
    '';
  };

  dconf.settings = {
    # --- Alphabetical App Grid ---
    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = "end";
    };

    # --- Blur My Shell ---
    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
      # pipelines handled by activation script
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
      window-gap-size = mkUint32 5;
    };

    # --- GSConnect ---
    "org/gnome/shell/extensions/gsconnect" = {
      devices = [ "865f1fa442c84b45ae4f512266515aed" ];
      missing-openssl = false;
      name = "doromiert";
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed" = {
      certificate-pem = "-----BEGIN CERTIFICATE-----\\nMIIBijCCATGgAwIBAgIBATAKBggqhkjOPQQDBDBPMSkwJwYDVQQDDCA4NjVmMWZh\\nNDQyYzg0YjQ1YWU0ZjUxMjI2NjUxNWFlZDEUMBIGA1UECwwLS0RFIENvbm5lY3Qx\\nDDAKBgNVBAoMA0tERTAeFw0yNDA1MDEyMjAwMDBaFw0zNTA1MDEyMjAwMDBaME8x\\nKTAnBgNVBAMMIDg2NWYxZmE0NDJjODRiNDVhZTRmNTEyMjY2NTE1YWVkMRQwEgYD\\nVQQLDAtLREUgQ29ubmVjdDEMMAoGA1UECgwDS0RFMFkwEwYHKoZIzj0CAQYIKoZI\\nzj0DAQcDQgAE87ID03jlWxkfn7e7Iky/fq0JbYD/N5h3cPOr7xMT8nzUfnJoP143\\ndj92U72WaqCJ7AGzz47/BWDvbyfuKvXHLjAKBggqhkjOPQQDBANHADBEAiAcHGyv\\n/2jeC5gUeIrElppKdv7//9f/KVJs0YN2ROmdWQIgW1yOAHa7GS0ZRJqbGXqoCdP5\\nVaE3UONLDbT/HFPwoz8=\\n-----END CERTIFICATE-----\\n";
      incoming-capabilities = [
        "kdeconnect.battery"
        "kdeconnect.clipboard"
        "kdeconnect.clipboard.connect"
        "kdeconnect.contacts.request_all_uids_timestamps"
        "kdeconnect.contacts.request_vcards_by_uid"
        "kdeconnect.findmyphone.request"
        "kdeconnect.mousepad.keyboardstate"
        "kdeconnect.mousepad.request"
        "kdeconnect.mpris"
        "kdeconnect.mpris.request"
        "kdeconnect.notification"
        "kdeconnect.notification.action"
        "kdeconnect.notification.reply"
        "kdeconnect.notification.request"
        "kdeconnect.ping"
        "kdeconnect.runcommand"
        "kdeconnect.sftp.request"
        "kdeconnect.share.request"
        "kdeconnect.share.request.update"
        "kdeconnect.sms.request"
        "kdeconnect.sms.request_attachment"
        "kdeconnect.sms.request_conversation"
        "kdeconnect.sms.request_conversations"
        "kdeconnect.systemvolume"
        "kdeconnect.telephony.request_mute"
      ];
      last-connection = "lan://192.168.1.12:1716";
      name = "Nothing Phone 2";
      outgoing-capabilities = [
        "kdeconnect.battery"
        "kdeconnect.clipboard"
        "kdeconnect.clipboard.connect"
        "kdeconnect.connectivity_report"
        "kdeconnect.contacts.response_uids_timestamps"
        "kdeconnect.contacts.response_vcards"
        "kdeconnect.findmyphone.request"
        "kdeconnect.mousepad.echo"
        "kdeconnect.mousepad.keyboardstate"
        "kdeconnect.mousepad.request"
        "kdeconnect.mpris"
        "kdeconnect.mpris.request"
        "kdeconnect.notification"
        "kdeconnect.notification.request"
        "kdeconnect.ping"
        "kdeconnect.presenter"
        "kdeconnect.runcommand.request"
        "kdeconnect.sftp"
        "kdeconnect.share.request"
        "kdeconnect.sms.attachment_file"
        "kdeconnect.sms.messages"
        "kdeconnect.systemvolume.request"
        "kdeconnect.telephony"
      ];
      paired = true;
      supported-plugins = [
        "battery"
        "clipboard"
        "connectivity_report"
        "contacts"
        "findmyphone"
        "mousepad"
        "mpris"
        "notification"
        "ping"
        "presenter"
        "runcommand"
        "sftp"
        "share"
        "sms"
        "systemvolume"
        "telephony"
      ];
      type = "phone";
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/battery" = {
      custom-battery-notification-value = mkUint32 80;
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/clipboard" = {
      receive-content = true;
      send-content = true;
    };

    # Notifications handled by activation script

    # RunCommand handled by activation script

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/share" = {
      receive-directory = "${config.home.homeDirectory}/Downloads";
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
      # global-rounded-corner-settings handled by activation script
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
