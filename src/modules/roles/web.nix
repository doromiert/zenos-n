{
  pkgs,
  ...
}:

let
  # --- 1. EXTENSION DEFINITIONS ---
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

  # Helper to lock preferences
  lock = value: {
    Value = value;
    Status = "locked";
  };
in
{
  # --- SYSTEM CLEANUP ---
  # We REMOVED the system-level programs.firefox block.
  # This prevents NixOS from installing a "clean" Firefox that shadows
  # the Home Manager "wrapped" Firefox (which has the policies).
  #
  # Since nixpwamaker uses pkgs.firefox directly (unwrapped), it doesn't need
  # Firefox installed in the system profile to work.

  # --- HOME MANAGER LEVEL (User Specific) ---
  # This configures the "Main" browser instance for all HM users.
  home-manager.sharedModules = [
    {
      # Add necessary packages for PWA management command line usage
      home.packages = [ pkgs.firefoxpwa ];

      programs.firefox = {
        enable = true;

        # [CRITICAL] This package definition ensures HM builds a wrapped binary
        # that includes the policies defined below.
        package = pkgs.firefox;

        # Define Native Messaging Hosts here so they work with the user wrapper
        nativeMessagingHosts = [
          pkgs.firefoxpwa
          pkgs.keepassxc
        ];

        policies = {
          # --- EXTENSIONS ---
          ExtensionSettings = builtins.listToAttrs (
            map (ext: {
              name = ext.id;
              value = {
                install_url = ext.url;
                installation_mode = "force_installed";
                default_area = "menupanel";
              };
            }) (builtins.attrValues extensions)
          );

          # --- SEARCH ENGINES ---
          SearchEngines = {
            Default = "DuckDuckGo";
            PreventInstalls = false;
          };

          # --- PRIVACY & SETTINGS ---
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
            "browser.contentblocking.category" = lock "standard";
            "browser.formfill.enable" = lock false;
            "browser.search.suggest.enabled" = lock false;
            "middlemouse.paste" = lock false;
            "general.autoScroll" = lock true;
            "extensions.autoDisableScopes" = lock 0;
            "extensions.enabledScopes" = lock 15;
            "xpinstall.signatures.required" = lock false;
            "extensions.langpacks.signatures.required" = lock false;
            "gfx.webrender.all" = lock true;
            "layers.acceleration.force-enabled" = lock true;
            "font.name.sans-serif.x-western" = lock "Atkinson Hyperlegible Next";
            "font.default.x-western" = lock "sans-serif";
            "font.size.variable.x-western" = lock 15;
            "browser.newtabpage.activity-stream.showSponsored" = lock false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
            "browser.newtabpage.activity-stream.feeds.opsouth" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;
            "browser.topsites.contile.enabled" = lock false;
            "browser.ml.enable" = lock true;
            "browser.ml.chat.enabled" = lock true;
            "browser.ml.chat.sidebar" = lock true;
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
    }
  ];
}
