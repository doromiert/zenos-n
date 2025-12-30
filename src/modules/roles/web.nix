# web stuff (browser, webapps etc)
{ pkgs, lib, config, ... }:

let
  # --- 1. SHARED RESOURCES ---
  resourcePath = ./. + "/../../../resources/firefoxpwa/chrome";
  
  paths = {
    pwaChrome = resourcePath;
    gnomeTheme = pkgs.fetchFromGitHub {
      owner = "rafaelmardojai";
      repo = "firefox-gnome-theme";
      rev = "v143"; 
      sha256 = "sha256-0E3TqvXAy81qeM/jZXWWOTZ14Hs1RT7o78UyZM+Jbr4="; 
    };
  };

  # --- 2. EXTENSION REGISTRY ---
  extStore = {
    ublock          = { id = "uBlock0@raymondhill.net";           url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"; sha256 = "sha256-XK9KvaSUAYhBIioSFWkZu92MrYKng8OMNrIt1kJwQxU="; };
    sponsorblock    = { id = "sponsorBlocker@ajay.app";           url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi"; sha256 = "sha256-WY9myetrurK9X4c3a2MqWGD0QtNpTiM2EPWzf4tuPxA="; };
    ua-switcher     = { id = "{7ad997b5-227a-4712-bf9e-01200f40243e}"; url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi"; sha256 = "sha256-nB/uKb2JpyH3r412qZeqytAn1PKxQc2wQ+6QJ7iWdZk="; };
    minimal-twitter = { id = "min-twitter@artem.plus";            url = "https://addons.mozilla.org/firefox/downloads/latest/minimaltwitter/latest.xpi"; sha256 = "sha256-h6r9hA2U2froAHU8x5hExwHgtU9010Cc/nHrLPW0kFo="; };
    keepassxc       = { id = "keepassxc-browser@keepassxc.org";   url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi"; sha256 = "sha256-vuUjrI2WjTauOuMXsSsbK76F4sb1ud2w+4IsLZCvYTk="; };
    violentmonkey   = { id = "{aecec67f-09e0-40ae-818e-8392128f6838}"; url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi"; sha256 = "sha256-iIARSjrDCl8668cUQ/hqH3/dHskpje8i3C4lBQLszO4="; };
    cssoverride     = { id = "cssoverride@m-m.in";                url = "https://addons.mozilla.org/firefox/downloads/latest/css-override/latest.xpi"; sha256 = "sha256-Qv9cI00XJxMEeBmq7a5fR2Px4sZymOGt+YSXEepAR9w="; };
    js-disabler     = { id = "{0f99479b-22d7-4009-9065-985f401f80f1}"; url = "https://addons.mozilla.org/firefox/downloads/latest/script-blocker-ultimate/latest.xpi"; sha256 = "sha256-Y/gzE/hYhDxPzDUWUOmU7F1kNJfx0eGSDiGwaYKo2Gs="; };
  };

  fetchExt = name: ext: pkgs.fetchurl { 
    name = "${name}.xpi"; 
    inherit (ext) url; 
    inherit (ext) sha256; 
  };
  
  extensions = builtins.mapAttrs (name: value: value // { src = fetchExt name value; }) extStore;

  # --- 3. PWA DEPLOYMENT LOGIC (UPDATED FOR 2.0+) ---
  # [FIX] Logic rewritten to handle blocked sites and local icons via "Manifest Injection"
  makePWA = user: name: url: icon: extraExts: ''
    # 1. Prepare
    echo "Processing PWA: ${name}..."
    MANIFEST="/tmp/manifest-${lib.strings.sanitizeDerivationName name}.json"
    USE_FALLBACK=0
    
    # If icon is a local path (starts with /), skip network install to avoid CLI errors
    if [[ "${icon}" == /* ]]; then
        echo "Local icon detected. Skipping network fetch."
        USE_FALLBACK=1
    else
        # Try standard network install
        # We capture output. If it fails (exit code != 0), we trigger fallback.
        if ! SITE_OUT=$(sudo -u ${user} -H ${lib.getExe pkgs.firefoxpwa} site install "${url}" --name "${name}" ${if icon != "" then "--icon-url '${icon}'" else ""} 2>&1); then
            echo "Network install failed for ${name} (likely blocked). Using manifest fallback."
            echo "Debug: $SITE_OUT"
            USE_FALLBACK=1
        else
            # Pass success output to ID extraction
            FINAL_OUT="$SITE_OUT"
        fi
    fi

    # 2. Fallback: Generate Local Manifest
    if [ "$USE_FALLBACK" -eq 1 ]; then
        # Prepare Icon JSON
        if [ -n "${icon}" ]; then
            # If local path, prepend file://, otherwise keep http://
            if [[ "${icon}" == /* ]]; then ICON_SRC="file://${icon}"; else ICON_SRC="${icon}"; fi
            ICON_JSON="[{\"src\": \"$ICON_SRC\", \"sizes\": \"512x512\", \"type\": \"image/png\"}]"
        else
            ICON_JSON="[]"
        fi

        # Generate valid JSON manifest using jq
        jq -n \
          --arg name "${name}" \
          --arg url "${url}" \
          --argjson icons "$ICON_JSON" \
          '{name: $name, short_name: $name, start_url: $url, display: "standalone", background_color: "#ffffff", theme_color: "#ffffff", icons: $icons}' \
          > "$MANIFEST"
        
        # Install from local manifest file
        FINAL_OUT=$(sudo -u ${user} -H ${lib.getExe pkgs.firefoxpwa} site install "$MANIFEST" 2>&1 || true)
    fi
    
    # 3. Extract ULID from the successful output
    SITE_ID=$(echo "$FINAL_OUT" | grep -oE '[0-9A-Z]{26}' | head -n 1)
    
    # 4. Install profile for the site ID
    if [ -n "$SITE_ID" ]; then
       sudo -u ${user} -H ${lib.getExe pkgs.firefoxpwa} profile install "$SITE_ID" > /dev/null 2>&1

       # 5. Link Extensions
       PROF_DIR="/home/${user}/.local/share/firefoxpwa/profiles/$SITE_ID"
       if [ -d "$PROF_DIR" ]; then
         mkdir -p "$PROF_DIR/extensions"
         ${lib.concatMapStringsSep "\n" (e: "ln -sfn '${e.src}' \"$PROF_DIR/extensions/${e.id}.xpi\"") (extraExts ++ [ extensions.keepassxc ])}
       fi
    else
       echo "WARNING: Failed to determine Site ID for ${name}. Skipping."
    fi
  '';

in {
  environment.systemPackages = [ pkgs.firefoxpwa pkgs.keepassxc pkgs.chromium ];

  environment.etc = if builtins.pathExists paths.pwaChrome then {
    "firefox/pwa-custom-chrome".source = paths.pwaChrome;
    "firefox/gnome-theme".source = paths.gnomeTheme;
  } else builtins.trace "WARNING: PWA Chrome resources not found at ${toString paths.pwaChrome}" {};

  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa pkgs.keepassxc ];
    
    policies = {
      ExtensionSettings = lib.mapAttrs' (name: ext: lib.nameValuePair ext.id {
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
    # [FIX] Add required tools to PATH: jq for JSON generation
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.sudo pkgs.gawk pkgs.gnugrep pkgs.jq ]}:$PATH"

    # Get all real users
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
      # Logic: Try network install -> If fail, use local manifest.
      # Local icons (Syncthing) force local manifest path immediately.
      
      ${makePWA "$username" "YouTube" "https://www.youtube.com" "" [ extensions.ublock extensions.sponsorblock ]}
      ${makePWA "$username" "Select for Figma" "https://www.figma.com" "" [ extensions.ua-switcher ]}
      ${makePWA "$username" "Gemini" "https://gemini.google.com" "" [ ]}
      ${makePWA "$username" "Twitter" "https://x.com" "" [ extensions.ublock extensions.minimal-twitter ]}
      ${makePWA "$username" "GitHub" "https://github.com" "" [ ]}
      
      ${makePWA "$username" "Syncthing" "http://localhost:8384/" "${pkgs.syncthing}/share/icons/hicolor/512x512/apps/syncthing.png" [ ]}

      # --- C. PWA Profile Customization ---
      for p_dir in "$user_home"/.local/share/firefoxpwa/profiles/*/; do
        [ -d "$p_dir" ] || continue
        mkdir -p "$p_dir/chrome"
        ln -sfn /etc/firefox/pwa-custom-chrome/userChrome.css "$p_dir/chrome/" || true
        ln -sfn /etc/firefox/pwa-custom-chrome/userContent.css "$p_dir/chrome/" || true
        [ -d /etc/firefox/pwa-custom-chrome/theme ] && ln -sfn /etc/firefox/pwa-custom-chrome/theme "$p_dir/chrome/" || true

        echo '
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("extensions.autoDisableScopes", 0);
user_pref("browser.tabs.drawInTitlebar", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("gnomeTheme.hideSingleTab", true);
        ' > "$p_dir/user.js"

      done
      
      # Fix permissions (Fail gracefully)
      if [ -d "$user_home/.local/share/firefoxpwa" ]; then
        chown -R "$username":users "$user_home"/.local/share/firefoxpwa || true
      fi
      if [ -d "$user_home/.mozilla/firefox" ]; then
        chown -R "$username":users "$user_home"/.mozilla/firefox || true
      fi
    done
  '';
}
