# web stuff (browser, webapps etc)
{ pkgs, lib, ... }:

let
  # --- 1. RESOURCES & THEME ---
  paths = {
    pwaChrome = ./. + "/../../../resources/firefoxpwa/chrome";
    gnomeTheme = pkgs.fetchFromGitHub {
      owner = "rafaelmardojai";
      repo = "firefox-gnome-theme";
      rev = "v143"; 
      hash = lib.fakeHash; 
    };
  };

  # --- 2. EXTENSION REGISTRY ---
  # Centralized store for all XPIs and their IDs
  extStore = {
    ublock          = { id = "uBlock0@raymondhill.net";           url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"; };
    sponsorblock    = { id = "sponsorBlocker@ajay.app";           url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi"; };
    ua-switcher     = { id = "{7ad997b5-227a-4712-bf9e-01200f40243e}"; url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi"; };
    minimal-twitter = { id = "min-twitter@artem.plus";            url = "https://addons.mozilla.org/firefox/downloads/latest/minimaltwitter/latest.xpi"; };
    keepassxc       = { id = "keepassxc-browser@keepassxc.org";   url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi"; };
    violentmonkey   = { id = "{aecec67f-09e0-40ae-818e-8392128f6838}"; url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi"; };
    cssoverride     = { id = "cssoverride@m-m.in";                url = "https://addons.mozilla.org/firefox/downloads/latest/cssoverride/latest.xpi"; };
    js-disabler     = { id = "{0f99479b-22d7-4009-9065-985f401f80f1}"; url = "https://addons.mozilla.org/firefox/downloads/latest/javascript-restricter/latest.xpi"; };
  };

  # Helper to fetch XPIs
  fetchExt = ext: pkgs.fetchurl { 
    inherit (ext) url; 
    sha256 = lib.fakeHash; 
  };

  # Processed extensions for easier mapping
  extensions = builtins.mapAttrs (name: value: value // { src = fetchExt value; }) extStore;

  # --- 3. PWA FACTORY ---
  # Logic to install a PWA and inject its specific extensions
  makePWA = name: url: icon: extraExts: ''
    if ! firefoxpwa app list | grep -q "${name}"; then
      firefoxpwa app install --name "${name}" --icon "${icon}" "${url}"
    fi
    APP_ID=$(firefoxpwa app list | grep "${name}" | awk '{print $1}')
    PROF_DIR="/home/negzero/.local/share/firefoxpwa/profiles/$APP_ID"
    mkdir -p "$PROF_DIR/extensions"
    ${lib.concatMapStringsSep "\n" (e: "ln -sf ${e.src} $PROF_DIR/extensions/${e.id}.xpi") (extraExts ++ [ extensions.keepassxc ])}
  '';

in {
  environment.systemPackages = [ pkgs.firefoxpwa pkgs.keepassxc ];

  environment.etc = {
    "firefox/pwa-custom-chrome".source = paths.pwaChrome;
    "firefox/gnome-theme".source = paths.gnomeTheme;
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa pkgs.keepassxc ];
    
    policies = {
      # Use the Registry to populate main browser extensions
      ExtensionSettings = lib.mapAttrs (name: ext: {
        installation_mode = "normal_installed";
        install_url = "file://${ext.src}";
      }) (with extensions; { inherit ublock ua-switcher violentmonkey cssoverride js-disabler keepassxc; });

      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.drawInTitlebar" = true;
        "svg.context-properties.content.enabled" = true;
        "gnomeTheme.hideSingleTab" = true;
      };
    };
  };

  system.activationScripts.firefoxSetup.text = ''
    # A. Global Browser Theming
    for profile in /home/*/.mozilla/firefox/*/; do
      [ -d "$profile" ] && [[ "$profile" != *"Pending"* ]] || continue
      mkdir -p "$profile/chrome"
      ln -sf /etc/firefox/gnome-theme/userChrome.css "$profile/chrome/"
      ln -sf /etc/firefox/gnome-theme/userContent.css "$profile/chrome/"
      ln -sfN /etc/firefox/gnome-theme/theme "$profile/chrome/"
    done

    # B. PWA Installation
    sudo -u negzero -H firefoxpwa runtime install || true
    ${makePWA "YouTube" "https://www.youtube.com" "youtube" [ extensions.ublock extensions.sponsorblock ]}
    ${makePWA "Figma" "https://www.figma.com" "select-for-figma" [ extensions.ua-switcher ]}
    ${makePWA "Gemini" "https://gemini.google.com" "internet-chat" [ ]}
    ${makePWA "Twitter" "https://x.com" "twitter" [ extensions.ublock extensions.minimal-twitter ]}
    ${makePWA "GitHub" "https://github.com" "github" [ ]}
    ${makePWA "Syncthing" "http://localhost:8384/" "syncthing" [ ]}

    # C. PWA Customization Loop
    for p_dir in /home/negzero/.local/share/firefoxpwa/profiles/*/; do
      [ -d "$p_dir" ] || continue
      mkdir -p "$p_dir/chrome"
      ln -sf /etc/firefox/pwa-custom-chrome/userChrome.css "$p_dir/chrome/"
      ln -sf /etc/firefox/pwa-custom-chrome/userContent.css "$p_dir/chrome/"
      [ -d /etc/firefox/pwa-custom-chrome/theme ] && ln -sfN /etc/firefox/pwa-custom-chrome/theme "$p_dir/chrome/"

      cat > "$p_dir/user.js" <<EOF
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("extensions.autoDisableScopes", 0);
        user_pref("browser.tabs.drawInTitlebar", true);
        user_pref("svg.context-properties.content.enabled", true);
        user_pref("gnomeTheme.hideSingleTab", true);
      EOF
    done
  '';
}