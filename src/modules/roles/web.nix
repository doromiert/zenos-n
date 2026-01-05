{
  pkgs,
  ...
}:

let
  # --- 1. EXTENSION DEFINITIONS ---
  # These are the extensions that will be forced for every Home Manager user's main profile.
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

  # Helper to lock preferences in the NixOS global policy
  lock = value: {
    Value = value;
    Status = "locked";
  };
in
{
  # --- NIXOS LEVEL CONFIG ---
  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      pkgs.keepassxc
    ];

    # --- GLOBAL POLICIES (System-Wide) ---
    # These apply to ALL Firefox instances (Main + PWAs).
    # We only keep non-conflicting settings here.
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

      # [!] ExtensionSettings are MOVED to the Home Manager module below.
      # This allows PWAs to define their own isolated extension sets.

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

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

  # --- HOME MANAGER SHARED MODULE ---
  # This injects the extensions into every Home Manager user's main profile.
  # This is "safe" because it doesn't force these extensions globally via /etc/,
  # ensuring your PWAs can finally have their own unique extension lists.
  home-manager.sharedModules = [
    {
      programs.firefox.policies.ExtensionSettings = builtins.listToAttrs (
        map (ext: {
          name = ext.id;
          value = {
            install_url = ext.url;
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
        }) (builtins.attrValues extensions)
      );
    }
  ];

  # [!] Obsolete variables and activation scripts for pwamaker.py have been removed.
}
