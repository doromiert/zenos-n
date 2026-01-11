{
  inputs,
  ...
}:

let
  # Helper to define extensions using the new structured format
  mkExt = id: url: { inherit id url; };

  exts = {
    ublock = mkExt "uBlock0@raymondhill.net" "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    sponsorblock = mkExt "sponsorBlocker@ajay.app" "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
    keepass = mkExt "keepassxc-browser@keepassxc.org" "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
    uaswitcher = mkExt "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
  };

in
{
  programs.pwamaker = {
    enable = true;
    firefoxGnomeTheme = inputs.firefox-gnome-theme;

    # [NEW] Enable the internal Dispatcher
    dispatcher = {
      enable = true;
      fallbackBrowser = "firefox"; # Matches your global firefox binary name
    };

    apps = {
      youtube = {
        id = "youtube";
        name = "YouTube";
        url = "https://www.youtube.com";
        icon = "youtube";

        # Custom Search Engine
        search = {
          name = "YouTube";
          url = "https://www.youtube.com/results?search_query={searchTerms}";
        };

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
        # Optional: Force YouTube links to open here too
        openUrls = [
          "youtube.com"
          "youtu.be"
        ];
      };

      github = {
        id = "github";
        name = "GitHub";
        url = "https://github.com";
        icon = "github";

        # Custom Search Engine
        search = {
          name = "GitHub";
          url = "https://github.com/search?q={searchTerms}";
        };
        layoutStart = [
          "home"
          "back"
          "forward"
          "reload"
        ];

        extensions = [
          exts.ublock
          exts.keepass
        ];
        categories = [
          "Network"
          "Development"
        ];
        keywords = [
          "git"
          "github"
          "gh"
          "code"
        ];
        openUrls = [
          "github.com"
        ];
      };

      figma = {
        id = "figma";
        name = "Select for Figma";
        url = "https://www.figma.com";
        icon = "select-for-figma";

        # Custom Search Engine (Community)
        search = {
          name = "Figma Community";
          url = "https://www.figma.com/community/search?query={searchTerms}&resource_type=mixed&editor_type=all&price=all&sort_by=relevancy&creators=all";
        };

        extensions = [
          exts.uaswitcher
          exts.keepass
        ];
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
        # Split layout around the tabs (which are now implicit in the center)
        layoutStart = [
          "home"
          "reload"
        ];
        layoutEnd = [
          "addons"
        ];
        openUrls = [
          "figma.com"
        ];
      };

      twitter = {
        id = "twitter";
        name = "Twitter";
        url = "https://x.com";
        icon = "twitter";

        # Custom Search Engine
        search = {
          name = "Twitter";
          url = "https://x.com/search?q={searchTerms}&src=typed_query";
        };

        extensions = [
          exts.ublock
          exts.keepass
        ];
        categories = [
          "Network"
          "Chat"
        ];
        keywords = [
          "social"
          "media"
          "x"
        ];
        # [NEW] This captures x.com and twitter.com links!
        openUrls = [
          "x.com"
          "twitter.com"
        ];
        # Split layout around the tabs
        layoutStart = [
          "home"
          "back"
          "forward"
          "reload"
        ];
        layoutEnd = [
          "addons"
        ];
      };

      gemini = {
        id = "gemini";
        name = "Gemini";
        url = "https://gemini.google.com";
        icon = "internet-chat";
        # templateProfile = baseProfile;
        extensions = [
          exts.keepass
        ];
        categories = [
          "Network"
          "Office"
          "X-ArtificialIntelligence"
        ];
        keywords = [
          "ai"
          "chat"
          "llm"
          "google"
        ];
        openUrls = [
          "gemini.google.com"
          "aistudio.google.com"
        ];
      };

      syncthing = {
        id = "syncthing";
        name = "Syncthing";
        url = "http://localhost:8384";
        icon = "syncthing";
        # templateProfile = baseProfile;
        categories = [
          "System"
          "FileTransfer"
        ];
        keywords = [
          "sync"
          "backup"
          "p2p"
        ];
        openUrls = [
          "localhost:8384"
          "127.0.0.1:8384"
        ];
      };
    };
  };
}
