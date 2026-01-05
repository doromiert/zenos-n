{ pkgs, inputs, ... }:

let
  exts = {
    ublock = "uBlock0@raymondhill.net:https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    sponsorblock = "sponsorBlocker@ajay.app:https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
    keepass = "keepassxc-browser@keepassxc.org:https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
    uaswitcher = "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}:https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
  };

  baseProfile = ../../../resources/firefoxpwa/templateprofile;

  standardLayout = "home,refresh,spring,extensions";
in
{
  programs.nixpwamaker = {
    enable = true;

    apps = {
      "YouTube" = {
        url = "https://www.youtube.com";
        icon = "youtube";
        templateProfile = baseProfile;
        extensions = [
          exts.ublock
          exts.sponsorblock
          exts.keepass
          exts.uaswitcher
        ];
        categories = [
          "Network"
          "Video"
          "AudioVideo"
        ];
        keywords = [
          "video"
          "music"
          "google"
          "stream"
        ];
        layout = standardLayout;
        extraPolicies = {
          DisableTelemetry = true;
          DisablePocket = true;
        };
      };

      "Select for Figma" = {
        url = "https://www.figma.com";
        icon = "select-for-figma";
        templateProfile = baseProfile;
        extensions = [
          exts.uaswitcher
          exts.keepass
        ];
        mimeTypes = [ "x-scheme-handler/figma" ];
        categories = [
          "Graphics"
          "Development"
        ];
        keywords = [
          "design"
          "ui"
          "ux"
          "vector"
        ];
        layout = standardLayout;
      };

      "Twitter" = {
        url = "https://x.com";
        icon = "twitter";
        templateProfile = baseProfile;
        extensions = [
          exts.ublock
          exts.keepass
        ];
        categories = [
          "Network"
          "Social"
        ];
        keywords = [
          "social"
          "media"
          "x"
        ];
        # Back and Forward arrows before refresh icon
        layout = "home,back,forward,refresh,spring,extensions";
      };

      "Gemini" = {
        url = "https://gemini.google.com";
        icon = "internet-chat";
        templateProfile = baseProfile;
        categories = [
          "Network"
          "Office"
          "ArtificialIntelligence"
        ];
        keywords = [
          "ai"
          "chat"
          "llm"
          "google"
        ];
        layout = standardLayout;
      };

      "Syncthing" = {
        url = "http://localhost:8384";
        icon = "syncthing";
        templateProfile = baseProfile;
        categories = [
          "System"
          "FileTransfer"
        ];
        keywords = [
          "sync"
          "backup"
          "p2p"
        ];
        layout = standardLayout;
      };
    };
  };
}
