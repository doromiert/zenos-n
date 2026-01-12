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
  # --- HOME MANAGER LEVEL (User Specific) ---
  home-manager.sharedModules = [
    {
      # Removed firefoxpwa package as requested

      # --- 1. Standard Firefox Configuration ---
      programs.firefox = {
        enable = true;

        # [P13.D] ENVIRONMENT OVERRIDE
        # Forces Wayland mode at the binary level to match the working profile
        package = pkgs.firefox.overrideAttrs (old: {
          buildCommand = old.buildCommand + ''
            wrapProgram $out/bin/firefox \
              --set MOZ_ENABLE_WAYLAND 1 \
              --set GTK_USE_PORTAL 1
          '';
        });

        # This links the manifest to ~/.mozilla/native-messaging-hosts/
        nativeMessagingHosts = [
          pkgs.keepassxc
        ];

        policies = {
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

          SearchEngines = {
            Default = "DuckDuckGo";
            PreventInstalls = false;
          };

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
            # --- [P13.D] REPLICATED "WORKING PROFILE" CONFIG ---

            # 1. Disable the broken Fractional Scale Protocol
            # (Forces integer scaling which avoids the blur)
            "widget.wayland.fractional-scale.enabled" = lock false;

            # 2. Force Software Rendering
            # (Bypasses the Intel GPU driver bug causing the blur)
            "gfx.webrender.software" = lock true;
            "gfx.webrender.all" = lock true; # Keep enabled as per working profile

            # 3. Force Hardware Surface Export
            # (Ensures correct window buffer transport)
            "widget.dmabuf.force-enabled" = lock true;
            "gfx.webrender.compositor.force-enabled" = lock true;

            # 4. Auto-detect Scale
            # (Working profile uses -1, allowing it to snap to 2x integer scale)
            "layout.css.devPixelsPerPx" = lock (-1.0);

            # 5. Security Check
            # (Ensure this doesn't override scaling)
            "privacy.resistFingerprinting" = lock false;

            # --- END SCALING FIXES ---

            # [P5.4] Force Libadwaita Picker
            "widget.use-xdg-desktop-portal.file-picker" = lock 1;
            "widget.use-xdg-desktop-portal.mime-handler" = lock 1;

            "browser.contentblocking.category" = lock "standard";
            "browser.formfill.enable" = lock false;
            "browser.search.suggest.enabled" = lock false;
            "middlemouse.paste" = lock false;
            "general.autoScroll" = lock true;
            "extensions.autoDisableScopes" = lock 0;
            "extensions.enabledScopes" = lock 15;
            "xpinstall.signatures.required" = lock false;
            "extensions.langpacks.signatures.required" = lock false;
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
            "browser.ctrlTab.sortByRecentlyUsed" = lock true;
          };
        };
      };
    }
  ];
}
