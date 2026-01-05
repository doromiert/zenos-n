{
  pkgs,
  lib,
  ...
}:

let
  # --- 1. EXTENSION DEFINITIONS ---
  # These are the extensions that will be forced globally for all users and profiles
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

  # Helper to lock preferences
  lock = value: {
    Value = value;
    Status = "locked";
  };
in
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      pkgs.keepassxc
    ];

    # --- 2. GLOBAL POLICIES ---
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableAppUpdate = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisablePocket = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      DontCheckDefaultBrowser = true;
      SearchBar = "unified";
      SearchEnginesDefault = "DuckDuckGo";

      # Force extensions for everyone
      ExtensionSettings = globalExtensions;

      # Comprehensive Privacy & Tracking Protection
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # DNS over HTTPS
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Locked = true;
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        MoreFromMozilla = false;
        SkipOnboarding = true;
        WhatsNew = false;
      };

      # --- 3. DETAILED PREFERENCES ---
      Preferences = {
        # Core Privacy
        "browser.contentblocking.category" = lock "standard";
        "browser.formfill.enable" = lock false;
        "browser.search.suggest.enabled" = lock false;
        "middlemouse.paste" = lock false;
        "general.autoScroll" = lock true;

        # Extension Scopes
        "extensions.autoDisableScopes" = lock 0;
        "extensions.enabledScopes" = lock 15;
        "xpinstall.signatures.required" = lock false;
        "extensions.langpacks.signatures.required" = lock false;

        # Rendering & Performance
        "gfx.webrender.all" = lock true;
        "layers.acceleration.force-enabled" = lock true;

        # Font & Typography
        "font.name.sans-serif.x-western" = lock "Atkinson Hyperlegible Next";
        "font.default.x-western" = lock "sans-serif";
        "font.size.variable.x-western" = lock 15;

        # Anti-Sponsored Features
        "browser.newtabpage.activity-stream.showSponsored" = lock false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
        "browser.newtabpage.activity-stream.feeds.opsouth" = lock false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;
        "browser.topsites.contile.enabled" = lock false;

        # AI Integration
        "browser.ml.enable" = lock true;
        "browser.ml.chat.enabled" = lock true;
        "browser.ml.chat.sidebar" = lock true;

        # GNOME Theme & UI Integration
        "toolkit.legacyUserProfileCustomizations.stylesheets" = lock true;
        "svg.context-properties.content.enabled" = lock true;
        "widget.gtk.rounded-bottom-corners.enabled" = lock true;
        "gnomeTheme.hideSingleTab" = lock true;
        "gnomeTheme.normalWidthTabs" = lock false;
        "gnomeTheme.bookmarksToolbarUnderTabs" = lock true;
        "browser.uidensity" = lock 1;
        "browser.tabs.drawInTitlebar" = lock true;
      };
    };
  };

  # The activation scripts and local path variables for pwamaker.py
  # have been removed as they are now handled by the nixpwamaker module.
}
