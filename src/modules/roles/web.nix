{
  pkgs,
  lib,
  ...
}:

let
  # --- 1. SETUP & RESOURCES ---
  pwamakerScript = ../../scripts/pwamaker.py;
  delwaScript = ../../scripts/delwa.py;

  templateProfile = ./. + "/../../../resources/firefoxpwa/testprofile";

  # --- 2. EXTENSION DEFINITIONS ---
  extensions = {
    ublock = {
      id = "uBlock0@raymondhill.net";
      url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    };
    sponsorblock = {
      id = "sponsorBlocker@ajay.app";
      url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
    };
    ua-switcher = {
      id = "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}";
      url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
    };
    keepassxc = {
      id = "keepassxc-browser@keepassxc.org";
      url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
    };
  };

  globalExtensions = (
    builtins.listToAttrs (
      map (ext: {
        name = ext.id;
        value = {
          install_url = ext.url;
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
      }) (builtins.attrValues extensions)
    )
  );

  lock = value: {
    Value = value;
    Status = "locked";
  };

  # --- 3. PWA GENERATOR FUNCTION ---
  makePWA = user: name: url: icon: extraExts: ''
    echo "[*] Web.nix: Deploying ${name}..."
    ${pkgs.util-linux}/bin/runuser -u ${user} -- ${pkgs.python3}/bin/python3 ${pwamakerScript} \
      --name "${name}" \
      --url "${url}" \
      --icon "${icon}" \
      --template "${templateProfile}" \
      ${lib.concatMapStringsSep " " (e: "--addon '${e.id}:${e.url}'") extraExts}
  '';

  delwaPkg = pkgs.writeScriptBin "delwa" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.python3}/bin/python3 ${delwaScript} "$@"
  '';

in
{
  environment.sessionVariables = {
    BROWSER = "firefox";
    DEFAULT_BROWSER = "firefox";
  };

  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };

  environment.systemPackages = [
    # pkgs.firefox handled by programs.firefox below
    pkgs.firefoxpwa
    pkgs.python3
    delwaPkg
    pkgs.keepassxc
    pkgs.ntfy-sh
    pkgs.libnotify
  ];

  services.flatpak.packages = [
    "app.drey.Blurble"
    "co.logonoff.awakeonlan"
    "com.google.Chrome"
    "de.haeckerfelix.Fragments"
    "dev.geopjr.Tuba"
    "io.github.giantpinkrobots.varia"
    "org.nickvision.tubeconverter"
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      pkgs.keepassxc
    ];

    # [FIX] Policies updated with new Font Names
    policies = {
      ExtensionSettings = globalExtensions;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Locked = true;
      };
      SearchEngines = {
        Default = "DuckDuckGo";
        PreventInstalls = true;
      };
      HardwareAcceleration = true;

      Preferences = {
        "extensions.enabledScopes" = lock 15;
        "extensions.autoDisableScopes" = lock 0;
        "xpinstall.signatures.required" = lock false;
        "browser.contentblocking.category" = lock "strict";
        "extensions.pocket.enabled" = lock false;
        "browser.ctrlTab.sortByRecentlyUsed" = lock true;
        "layers.acceleration.force-enabled" = lock true;
        "gfx.webrender.all" = lock true;

        # [UPDATED] Font Preferences to match 'Atkinson Hyperlegible Next'
        "font.name.sans-serif.x-western" = lock "Atkinson Hyperlegible Next";
        "font.default.x-western" = lock "sans-serif";

        "toolkit.legacyUserProfileCustomizations.stylesheets" = lock true;
        "svg.context-properties.content.enabled" = lock true;
        "widget.gtk.rounded-bottom-corners.enabled" = lock true;
        "gnomeTheme.hideSingleTab" = lock true;
        "browser.tabs.drawInTitlebar" = lock true;
      };
    };
  };

  system.activationScripts.webApps.text = ''
    export PATH="${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.sudo
        pkgs.python3
        pkgs.firefoxpwa
        pkgs.shadow
      ]
    }:$PATH"

    if [ -n "$ZENOS_SYNTHESIS" ]; then
      exit 0
    fi

    for user_home in /home/*; do
      [ -d "$user_home" ] || continue
      username=$(basename "$user_home")
      if [[ "$username" =~ ^(lost\+found|nixos|root)$ ]] || ! id "$username" >/dev/null 2>&1; then 
        continue 
      fi

      echo ">>> Configuring PWAs for user: $username"
      ${makePWA "$username" "YouTube" "https://www.youtube.com" "youtube" [
        extensions.ublock
        extensions.sponsorblock
        extensions.keepassxc
        extensions.ua-switcher
      ]}
      ${makePWA "$username" "Select for Figma" "https://www.figma.com" "select-for-figma" [
        extensions.ua-switcher
        extensions.keepassxc
      ]}
      ${makePWA "$username" "Gemini" "https://gemini.google.com" "internet-chat" [
        extensions.keepassxc
      ]}
      ${makePWA "$username" "Twitter" "https://x.com" "twitter" [
        extensions.ublock
        extensions.keepassxc
      ]}
      ${makePWA "$username" "GitHub" "https://github.com" "github" [ extensions.keepassxc ]}
      ${makePWA "$username" "Syncthing" "http://localhost:8384/" "syncthing" [ ]}
    done
  '';
}
