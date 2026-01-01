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

  paths = {
    pwaChrome = ./. + "/../../../resources/firefoxpwa/chrome";
    gnomeTheme = pkgs.fetchFromGitHub {
      owner = "rafaelmardojai";
      repo = "firefox-gnome-theme";
      rev = "v143";
      sha256 = "sha256-0E3TqvXAy81qeM/jZXWWOTZ14Hs1RT7o78UyZM+Jbr4=";
    };
  };

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
    # minimal-twitter = {
    #   id = "{e7476172-097c-4b77-b56e-f56a894adca9}";
    #   url = "https://addons.mozilla.org/firefox/downloads/latest/minimaltwitter/latest.xpi";
    # };
    keepassxc = {
      id = "keepassxc-browser@keepassxc.org";
      url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
    };
  };

  # [P9] Logic: Block all by default, then merge our specific list.
  # This matches the "force_installed" pattern from the reference config.
  globalExtensions = {
  }
  // (builtins.listToAttrs (
    map (ext: {
      name = ext.id; # Sets the Firefox ID as the key
      value = {
        install_url = ext.url;
        installation_mode = "force_installed";
        default_area = "menupanel";
      };
    }) (builtins.attrValues extensions)
  ));

  # Helper to lock preferences
  lock = value: {
    Value = value;
    Status = "locked";
  };

  # --- 3. PWA GENERATOR FUNCTION ---
  makePWA = user: name: url: icon: extraExts: ''
    echo "------------------------------------------------"
    echo "[*] Web.nix: Deploying ${name}..."

    sudo -u ${user} -H ${pkgs.python3}/bin/python3 ${pwamakerScript} \
      --name "${name}" \
      --url "${url}" \
      --icon "${icon}" \
      --template "${templateProfile}" \
      ${lib.concatMapStringsSep " " (e: "--addon '${e.id}:${e.url}'") extraExts}
      
      echo "${lib.concatMapStringsSep " " (e: "--addon '${e.id}:${e.url}'") extraExts}"

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
    pkgs.firefox
    pkgs.firefoxpwa
    pkgs.python3
    delwaPkg
    pkgs.keepassxc
    pkgs.atkinson-hyperlegible
    pkgs.ntfy-sh
    pkgs.libnotify
  ];

  environment.etc =
    if builtins.pathExists paths.pwaChrome then
      {
        "firefox/pwa-custom-chrome".source = paths.pwaChrome;
        "firefox/gnome-theme".source = paths.gnomeTheme;
      }
    else
      builtins.trace "WARNING: PWA Chrome resources not found at ${toString paths.pwaChrome}" { };

  services.flatpak.packages = [
    "app.drey.Blurble"
    "co.logonoff.awakeonlan"
    "com.google.Chrome"
    "de.haeckerfelix.Fragments"
    "dev.geopjr.Tuba"
    "io.github.giantpinkrobots.varia"
    "org.nickvision.tubeconverter"
  ];

  systemd.user.services.ntfy-receiver = {
    enable = true;
    description = "Ntfy.sh Notification Receiver";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      pkgs.libnotify
      pkgs.ntfy-sh
    ];
    serviceConfig = {
      ExecStart = "${pkgs.ntfy-sh}/bin/ntfy sub --cmd 'notify-send \"Ntfy\" \"$m\"' nzserver_status";
      Restart = "always";
      RestartSec = 10;
    };
    wantedBy = [ "default.target" ];
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      pkgs.keepassxc
    ];
    policies = {
      ExtensionSettings = globalExtensions;

      # Privacy & Tracking (from reference)
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # UI Cleanliness (from reference)
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DontCheckDefaultBrowser = true;
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;

      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Locked = true;
      };

      SearchEngines = {
        Default = "DuckDuckGo";
        PreventInstalls = true;
      };

      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        MoreFromMozilla = false;
        SkipOnboarding = true;
        WhatsNew = false;
      };

      HardwareAcceleration = true;

      Preferences = {
        # --- [ ! ] CRITICAL: Enable Sideloading & Policy Installs ---
        "extensions.enabledScopes" = lock 15;
        "extensions.autoDisableScopes" = lock 0;
        "xpinstall.signatures.required" = lock false;
        "extensions.langpacks.signatures.required" = lock false;
        "extensions.quarantinedDomains.enabled" = lock false;

        # --- Strict Privacy (from reference) ---
        "browser.contentblocking.category" = lock "strict";
        "extensions.pocket.enabled" = lock false;
        "extensions.screenshots.disabled" = lock true;
        "browser.topsites.contile.enabled" = lock false;
        "browser.formfill.enable" = lock false;
        "browser.search.suggest.enabled" = lock false;

        # --- UX Tweaks ---
        "browser.ctrlTab.sortByRecentlyUsed" = lock true;
        "middlemouse.paste" = lock false;
        "general.autoScroll" = lock true;

        # --- Hardware Acceleration ---
        "layers.acceleration.force-enabled" = lock true;
        "gfx.webrender.all" = lock true;

        # --- Typography ---
        "font.name.sans-serif.x-western" = lock "Atkinson Hyperlegible";
        "font.name.serif.x-western" = lock "Atkinson Hyperlegible";
        "font.default.x-western" = lock "sans-serif";
        "font.size.variable.x-western" = lock 15;

        # --- Anti-Sponsored ---
        "browser.newtabpage.activity-stream.showSponsored" = lock false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
        "browser.newtabpage.activity-stream.feeds.opsouth" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;

        # --- AI Integration ---
        "browser.ml.enable" = lock true;
        "browser.ml.chat.enabled" = lock true;
        "browser.ml.chat.sidebar" = lock true;

        # --- CSS / Theme Support ---
        "toolkit.legacyUserProfileCustomizations.stylesheets" = lock true;
        "svg.context-properties.content.enabled" = lock true;

        # --- GNOME Theme Integration ---
        "browser.theme.dark-private-windows" = lock false;
        "widget.gtk.rounded-bottom-corners.enabled" = lock true;
        "gnomeTheme.hideSingleTab" = lock true;
        "gnomeTheme.normalWidthTabs" = lock false;
        "gnomeTheme.bookmarksToolbarUnderTabs" = lock true;
        "browser.uidensity" = lock 1;
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
      ]
    }:$PATH"

    for user_home in /home/*; do
      [ -d "$user_home" ] || continue
      username=$(basename "$user_home")
      if [ "$username" == "lost+found" ] || [ "$username" == "root" ]; then continue; fi

      # --- A. Global Browser Theming ---
      for profile in "$user_home"/.mozilla/firefox/*/; do
        [ -d "$profile" ] && [[ "$profile" != *"Pending"* ]] || continue
        mkdir -p "$profile/chrome"
        ln -sfn /etc/firefox/gnome-theme/userChrome.css "$profile/chrome/" || true
        ln -sfn /etc/firefox/gnome-theme/userContent.css "$profile/chrome/" || true
        ln -sfn /etc/firefox/gnome-theme/theme "$profile/chrome/" || true
      done

      # --- B. PWA Installation ---
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
        # extensions.minimal-twitter
      ]}
      
      ${makePWA "$username" "GitHub" "https://github.com" "github" [ extensions.keepassxc ]}
      
      ${makePWA "$username" "Syncthing" "http://localhost:8384/" "syncthing" [ ]}
      
    done
  '';
}
