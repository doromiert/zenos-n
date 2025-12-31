{ lib, ... }:

let
  mkUint32 = lib.hm.gvariant.mkUint32;
  mkTuple = lib.hm.gvariant.mkTuple;
  mkVariant = lib.hm.gvariant.mkVariant;
in
{
  # Provision the Burn My Windows profile
  xdg.configFile."burn-my-windows/profiles/bmw.conf".source = ./resources/bmw.conf;

  dconf.settings = {
    # --- Alphabetical App Grid ---
    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      folder-order-position = "end";
    };

    # --- Blur My Shell ---
    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
      pipelines = {
        pipeline_default = mkVariant {
          name = mkVariant "Default";
          effects = mkVariant [
            (mkVariant {
              type = mkVariant "native_static_gaussian_blur";
              id = mkVariant "effect_000000000000";
              params = mkVariant {
                radius = mkVariant 30;
                brightness = mkVariant 0.29999999999999999;
                unscaled_radius = mkVariant 100;
              };
            })
            (mkVariant {
              type = mkVariant "noise";
              id = mkVariant "effect_08907494042010";
              params = mkVariant {
                noise = mkVariant 0.40000000000000002;
              };
            })
          ];
        };
        pipeline_default_rounded = mkVariant {
          name = mkVariant "Default rounded";
          effects = mkVariant [
            (mkVariant {
              type = mkVariant "native_static_gaussian_blur";
              id = mkVariant "effect_000000000001";
              params = mkVariant {
                radius = mkVariant 30;
                brightness = mkVariant 0.59999999999999998;
              };
            })
            (mkVariant {
              type = mkVariant "corner";
              id = mkVariant "effect_000000000002";
              params = mkVariant {
                radius = mkVariant 24;
              };
            })
          ];
        };
      };
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
      # This path aligns with the xdg.configFile target above
      active-profile = "/home/doromiert/.config/burn-my-windows/profiles/bmw.conf";
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
      switcher-background-color = mkTuple [ 1.0 1.0 1.0 ];
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
      incoming-capabilities = [ "kdeconnect.battery" "kdeconnect.clipboard" "kdeconnect.clipboard.connect" "kdeconnect.contacts.request_all_uids_timestamps" "kdeconnect.contacts.request_vcards_by_uid" "kdeconnect.findmyphone.request" "kdeconnect.mousepad.keyboardstate" "kdeconnect.mousepad.request" "kdeconnect.mpris" "kdeconnect.mpris.request" "kdeconnect.notification" "kdeconnect.notification.action" "kdeconnect.notification.reply" "kdeconnect.notification.request" "kdeconnect.ping" "kdeconnect.runcommand" "kdeconnect.sftp.request" "kdeconnect.share.request" "kdeconnect.share.request.update" "kdeconnect.sms.request" "kdeconnect.sms.request_attachment" "kdeconnect.sms.request_conversation" "kdeconnect.sms.request_conversations" "kdeconnect.systemvolume" "kdeconnect.telephony.request_mute" ];
      last-connection = "lan://192.168.1.12:1716";
      name = "Nothing Phone 2";
      outgoing-capabilities = [ "kdeconnect.battery" "kdeconnect.clipboard" "kdeconnect.clipboard.connect" "kdeconnect.connectivity_report" "kdeconnect.contacts.response_uids_timestamps" "kdeconnect.contacts.response_vcards" "kdeconnect.findmyphone.request" "kdeconnect.mousepad.echo" "kdeconnect.mousepad.keyboardstate" "kdeconnect.mousepad.request" "kdeconnect.mpris" "kdeconnect.mpris.request" "kdeconnect.notification" "kdeconnect.notification.request" "kdeconnect.ping" "kdeconnect.presenter" "kdeconnect.runcommand.request" "kdeconnect.sftp" "kdeconnect.share.request" "kdeconnect.sms.attachment_file" "kdeconnect.sms.messages" "kdeconnect.systemvolume.request" "kdeconnect.telephony" ];
      paired = true;
      supported-plugins = [ "battery" "clipboard" "connectivity_report" "contacts" "findmyphone" "mousepad" "mpris" "notification" "ping" "presenter" "runcommand" "sftp" "share" "sms" "systemvolume" "telephony" ];
      type = "phone";
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/battery" = {
      custom-battery-notification-value = mkUint32 80;
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/clipboard" = {
      receive-content = true;
      send-content = true;
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/notification" = {
      # This is a large JSON object stored as a string
      applications = "{\"Printers\":{\"iconName\":\"org.gnome.Settings-printers-symbolic\",\"enabled\":true},\"Events and Tasks Reminders\":{\"iconName\":\"org.gnome.Evolution-alarm-notify\",\"enabled\":true},\"Telegram\":{\"iconName\":\"org.telegram.desktop\",\"enabled\":true},\"Zenity\":{\"iconName\":\"application-x-executable\",\"enabled\":true},\"Disks\":{\"iconName\":\"org.gnome.DiskUtility\",\"enabled\":true},\"Software\":{\"iconName\":\"org.gnome.Software\",\"enabled\":true},\"Date & Time\":{\"iconName\":\"org.gnome.Settings-time-symbolic\",\"enabled\":true},\"Disk Usage Analyzer\":{\"iconName\":\"org.gnome.baobab\",\"enabled\":true},\"Power\":{\"iconName\":\"org.gnome.Settings-power-symbolic\",\"enabled\":true},\"Black Box\":{\"iconName\":\"com.raggesilver.BlackBox\",\"enabled\":true},\"Color Management\":{\"iconName\":\"org.gnome.Settings-color-symbolic\",\"enabled\":true},\"Console\":{\"iconName\":\"org.gnome.Console\",\"enabled\":true},\"Files\":{\"iconName\":\"org.gnome.Nautilus\",\"enabled\":true},\"Clocks\":{\"iconName\":\"org.gnome.clocks\",\"enabled\":true},\"File Roller\":{\"iconName\":\"org.gnome.FileRoller\",\"enabled\":true},\"Vesktop\":{\"iconName\":\"dev.vencord.Vesktop\",\"enabled\":true},\"Firefox\":{\"iconName\":\"\",\"enabled\":true},\"SimpleX Chat\":{\"iconName\":\"chat.simplex.simplex\",\"enabled\":true},\"Carburetor\":{\"iconName\":\"io.frama.tractor.carburetor\",\"enabled\":true},\"Parabolic\":{\"iconName\":\"org.nickvision.tubeconverter\",\"enabled\":true},\"Tuba\":{\"iconName\":\"dev.geopjr.Tuba\",\"enabled\":true},\"Online Accounts\":{\"iconName\":\"dialog-warning\",\"enabled\":true},\"CachyOS Update\":{\"iconName\":\"system-reboot\",\"enabled\":true},\"Alpaca\":{\"iconName\":\"document-save-symbolic\",\"enabled\":true},\"GPU Screen Recorder\":{\"iconName\":\"com.dec05eba.gpu_screen_recorder\",\"enabled\":true},\"Notify\":{\"iconName\":\"com.ranfdev.Notify\",\"enabled\":true},\"File Shredder\":{\"iconName\":\"com.github.ADBeveridge.Raider\",\"enabled\":true},\"Bottles\":{\"iconName\":\"com.usebottles.bottles\",\"enabled\":true},\"Pika Backup\":{\"iconName\":\"org.gnome.World.PikaBackup\",\"enabled\":true},\"Constrict\":{\"iconName\":\"io.github.wartybix.Constrict\",\"enabled\":true},\"Fractal\":{\"iconName\":\"org.gnome.Fractal\",\"enabled\":true},\"Pika Backup Monitor\":{\"iconName\":\"org.gnome.World.PikaBackup\",\"enabled\":true},\"Fragments\":{\"iconName\":\"folder-download-symbolic\",\"enabled\":true},\"Telegram Desktop\":{\"iconName\":\"\",\"enabled\":true},\"Varia\":{\"iconName\":\"io.github.giantpinkrobots.varia\",\"enabled\":true},\"Characters\":{\"iconName\":\"org.gnome.Characters\",\"enabled\":true},\"Polari\":{\"iconName\":\"org.gnome.Polari\",\"enabled\":true}}";
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/runcommand" = {
      # Mapped dictionary for commands
      command-list = {
        "lock" = mkVariant { name = "Lock"; command = "xdg-screensaver lock"; };
        "restart" = mkVariant { name = "Restart"; command = "systemctl reboot"; };
        "logout" = mkVariant { name = "Log Out"; command = "gnome-session-quit --logout --no-prompt"; };
        "poweroff" = mkVariant { name = "Power Off"; command = "systemctl poweroff"; };
        "suspend" = mkVariant { name = "Suspend"; command = "systemctl suspend"; };
        "1d21fa11-b507-4738-a2ab-3d41983cf751" = mkVariant { name = "smode"; command = "sudo systemctl isolate multi-user.target"; };
        "d0b24046-a05f-4705-8c91-2bd9e248e357" = mkVariant { name = "gmode"; command = "sudo systemctl isolate graphical.target"; };
      };
    };

    "org/gnome/shell/extensions/gsconnect/device/865f1fa442c84b45ae4f512266515aed/plugin/share" = {
      receive-directory = "/home/doromiert/Downloads";
    };

    "org/gnome/shell/extensions/gsconnect/preferences" = {
      window-maximized = false;
      window-size = mkTuple [ 945 478 ];
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
      # Nested dictionary variants for GVariant
      global-rounded-corner-settings = mkVariant {
        padding = mkVariant { left = mkUint32 1; right = 1; top = 1; bottom = 1; };
        keepRoundedCorners = mkVariant { maximized = false; fullscreen = false; };
        borderRadius = mkVariant (mkUint32 12);
        smoothing = mkVariant 0.0;
        borderColor = mkVariant (mkTuple [ 0.19215686619281769 0.19215686619281769 0.20784313976764679 1.0 ]);
        enabled = mkVariant true;
      };
      settings-version = mkUint32 7;
    };

    # --- Tweaks System Menu ---
    "org/gnome/shell/extensions/tweaks-system-menu" = {
      applications = [ "org.gnome.tweaks.desktop" "com.mattjakeman.ExtensionManager.desktop" ];
    };
  };
}