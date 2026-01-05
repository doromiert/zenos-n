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
        "extensions.enabledScopes" = lock 15;
        "extensions.autoDisableScopes" = lock 0;
        "xpinstall.signatures.required" = lock false;
        "extensions.langpacks.signatures.required" = lock false;
        "extensions.quarantinedDomains.enabled" = lock false;

        # --- Strict Privacy (from reference) ---
        "browser.contentblocking.category" = lock "standard";
        "extensions.pocket.enabled" = lock false;
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

        # [UPDATED] Font Preferences to match 'Atkinson Hyperlegible Next'
        "font.name.sans-serif.x-western" = lock "Atkinson Hyperlegible Next";
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
        pkgs.shadow
      ]
    }:$PATH"

    if [ -n "$ZENOS_SYNTHESIS" ]; then
      exit 0
    fi

  '';
}
