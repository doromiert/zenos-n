{
  pkgs,
  lib,
  config,
  ...
}:

let
  # --- 1. SETUP & RESOURCES ---
  pwamakerScript = ../../scripts/pwamaker.py;
  delwaScript = ../../scripts/delwa.py;

  templateProfile = ./. + "/../../../resources/firefoxpwa/testprofile";

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
  };

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

  # [New] Delwa script wrapper for global access
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
    pkgs.firefox # Ensure base Firefox is installed
    pkgs.firefoxpwa
    pkgs.python3
    delwaPkg
  ];

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
