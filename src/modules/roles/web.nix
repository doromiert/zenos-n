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
  fetchExt =
    {
      name,
      url,
      sha256,
    }:
    pkgs.fetchurl {
      name = "${name}.xpi";
      inherit url sha256;
    };

  rawExtensions = {
    ublock = {
      id = "uBlock0@raymondhill.net";
      url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      sha256 = "sha256-XK9KvaSUAYhBIioSFWkZu92MrYKng8OMNrIt1kJwQxU=";
    };
    sponsorblock = {
      id = "sponsorBlocker@ajay.app";
      url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
      sha256 = "sha256-WY9myetrurK9X4c3a2MqWGD0QtNpTiM2EPWzf4tuPxA=";
    };
    ua-switcher = {
      id = "{7ad997b5-227a-4712-bf9e-01200f40243e}";
      url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
      sha256 = "sha256-nB/uKb2JpyH3r412qZeqytAn1PKxQc2wQ+6QJ7iWdZk=";
    };
    minimal-twitter = {
      id = "min-twitter@artem.plus";
      url = "https://addons.mozilla.org/firefox/downloads/latest/minimaltwitter/latest.xpi";
      sha256 = "sha256-dvRw05OqgxkgtvqNedEDl+/LSEXK7EqAJNM8rp02H70=";
    };
    keepassxc = {
      id = "keepassxc-browser@keepassxc.org";
      url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
      sha256 = "sha256-vuUjrI2WjTauOuMXsSsbK76F4sb1ud2w+4IsLZCvYTk=";
    };
  };

  # Processed extensions for PWA usage (local file paths)
  extensions = lib.mapAttrs (
    name: val:
    val
    // {
      src = fetchExt {
        name = name;
        inherit (val) url sha256;
      };
    }
  ) rawExtensions;

  # [P8.2] Task Execution: Transform extensions for Main Browser Policy
  # Maps the rawExtensions to the format Firefox Policy expects (UUID as key)
  globalExtensions = lib.mapAttrs' (name: ext: {
    name = ext.id;
    value = {
      install_url = ext.url;
      installation_mode = "force_installed";
      default_area = "menupanel"; # Install to overflow menu (don't clutter toolbar)
    };
  }) rawExtensions;

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
      ${lib.concatMapStringsSep " " (e: "--addon '${e.id}:${e.src}'") extraExts}
  '';

  delwaPkg = pkgs.writeScriptBin "delwa" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.python3}/bin/python3 ${delwaScript} "$@"
  '';

in
{
  # Set Firefox as default browser system-wide (ENV + XDG)
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
    pkgs.atkinson-hyperlegible # Required for font policy
    pkgs.ntfy-sh # Required for the receiver service
    pkgs.libnotify # Required for the receiver service
  ];

  # Map resources to /etc for clean symlinking
  environment.etc =
    if builtins.pathExists paths.pwaChrome then
      {
        "firefox/pwa-custom-chrome".source = paths.pwaChrome;
        "firefox/gnome-theme".source = paths.gnomeTheme;
      }
    else
      builtins.trace "WARNING: PWA Chrome resources not found at ${toString paths.pwaChrome}" { };

  # -- Flatpak Web & Social Apps --
  services.flatpak.packages = [
    "app.drey.Blurble" # Wordle Clone (Web game)
    "co.logonoff.awakeonlan" # Wake on LAN (Moved from main.nix)
    "com.google.Chrome" # Google Chrome
    "de.haeckerfelix.Fragments" # BitTorrent Client
    "dev.geopjr.Tuba" # Mastodon Client
    "io.github.giantpinkrobots.varia" # Download Manager
    "org.nickvision.tubeconverter" # Parabolic (Video Downloader)
  ];

  # -- Ntfy Receiver Service --
  # Replaces the 'com.ranfdev.Notify' Flatpak with a native system daemon
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
      # ## [ ! ] CRITICAL: Replace 'INSERT_TOPIC_HERE' with your actual topic
      # Listens for messages and pipes them to notify-send
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
      # 1. Install Extensions in Main Browser
      ExtensionSettings = globalExtensions;

      # 2. Basic Policy Enforcement
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;

      # 3. Security & Privacy
      PasswordManagerEnabled = false; # Rely on KeePassXC
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

      # 4. Hardware Acceleration
      HardwareAcceleration = true;

      # 5. Preferences (Theming & Tweaks)
      Preferences = {
        # --- UX Tweaks ---
        "browser.ctrlTab.sortByRecentlyUsed" = lock true;
        "middlemouse.paste" = lock false;
        "general.autoScroll" = lock true;
        "browser.toolbars.bookmarks.visibility" = lock "never";

        # --- Hardware Acceleration ---
        "layers.acceleration.force-enabled" = lock true;
        "gfx.webrender.all" = lock true;

        # --- Typography (Atkinson Hyperlegible) ---
        "font.name.sans-serif.x-western" = lock "Atkinson Hyperlegible";
        "font.name.serif.x-western" = lock "Atkinson Hyperlegible";
        "font.default.x-western" = lock "sans-serif";
        "font.size.variable.x-western" = lock 15;

        # --- Anti-Sponsored Bullshit ---
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

        # --- GNOME Theme Integration (CRITICAL FIXES) ---
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
      ]}
      
      ${makePWA "$username" "Select for Figma" "https://www.figma.com" "select-for-figma" [
        extensions.ua-switcher
      ]}
      
      ${makePWA "$username" "Gemini" "https://gemini.google.com" "internet-chat" [ ]}
      
      ${makePWA "$username" "Twitter" "https://x.com" "twitter" [
        extensions.ublock
        extensions.minimal-twitter
      ]}
      
      ${makePWA "$username" "GitHub" "https://github.com" "github" [ ]}
      
      ${makePWA "$username" "Syncthing" "http://localhost:8384/" "syncthing" [ ]}
      
    done
  '';
}
