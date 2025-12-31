{
  pkgs,
  lib,
  config,
  ...
}:

let
  # --- 1. SHARED RESOURCES ---
  # These use relative paths from this .nix file's location.
  # Nix will resolve these to /nix/store paths during the build.
  resourcePath = ./. + "/../../../resources/firefoxpwa/chrome";
  templateProfile = ./. + "/../../../resources/firefoxpwa/testprofile";
  pwamaker = ../../scripts/pwamaker.py;

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
      sha256 = "sha256-h6r9hA2U2froAHU8x5hExwHgtU9010Cc/nHrLPW0kFo=";
    };
    keepassxc = {
      id = "keepassxc-browser@keepassxc.org";
      url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
      sha256 = "sha256-vuUjrI2WjTauOuMXsSsbK76F4sb1ud2w+4IsLZCvYTk=";
    };
  };

  fetchExt =
    name: ext:
    pkgs.fetchurl {
      name = "${name}.xpi";
      inherit (ext) url;
      inherit (ext) sha256;
    };

  extensions = builtins.mapAttrs (name: value: value // { src = fetchExt name value; }) extStore;

  # --- 3. PWA DEPLOYMENT LOGIC ---
  makePWA = user: name: url: icon: extraExts: ''
    echo "[*] Deploying PWA: ${name} via pwamaker.py"
    sudo -u ${user} -H ${pkgs.python3}/bin/python3 ${pwamaker} \
      --name "${name}" \
      --url "${url}" \
      --icon "${icon}" \
      --template "${templateProfile}" \
      ${lib.concatMapStringsSep " " (e: "--addon '${e.id}:${e.src}'") (
        extraExts ++ [ extensions.keepassxc ]
      )}
  '';

in
{
  environment.systemPackages = [
    pkgs.firefoxpwa
    pkgs.python3
    pkgs.keepassxc
  ];

  environment.etc =
    if builtins.pathExists paths.pwaChrome then
      {
        "firefox/pwa-custom-chrome".source = paths.pwaChrome;
        "firefox/gnome-theme".source = paths.gnomeTheme;
      }
    else
      builtins.trace "WARNING: PWA Chrome resources not found at ${toString paths.pwaChrome}" { };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      pkgs.keepassxc
    ];
    policies = {
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.drawInTitlebar" = true;
        "svg.context-properties.content.enabled" = true;
        "gnomeTheme.hideSingleTab" = true;
      };
    };
  };

  system.activationScripts.firefoxSetup.text = ''
    # Path setup
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

      # --- B. PWA Installation via python script ---
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

      # --- C. Custom Chrome Styling ---
      for p_dir in "$user_home"/.local/share/firefoxpwa/profiles/*/; do
        [ -d "$p_dir" ] || continue
        mkdir -p "$p_dir/chrome"
        ln -sfn /etc/firefox/pwa-custom-chrome/userChrome.css "$p_dir/chrome/" || true
        ln -sfn /etc/firefox/pwa-custom-chrome/userContent.css "$p_dir/chrome/" || true
        [ -d /etc/firefox/pwa-custom-chrome/theme ] && ln -sfn /etc/firefox/pwa-custom-chrome/theme "$p_dir/chrome/" || true
      done
      
      # Fix permissions
      if [ -d "$user_home/.local/share/firefoxpwa" ]; then
        chown -R "$username":users "$user_home"/.local/share/firefoxpwa || true
      fi
    done
  '';
}
