# doromipad-specific syncthing settings
{
  services.syncthing = {
    dataDir = "${config.users.users.doromiert.home}/.local/share/syncthing";
    configDir = "${config.users.users.doromiert.home}/.config/syncthing";

    folders = {

      # 1. Books
      "books" = {
        id = "6dovv-1tpo9";
        path = "${config.users.users.doromiert.home}/Documents/books";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
        ];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15552000";
          };
        };
      };

      # 2. Obsidian (Rondomix)
      "obsidian-rondomix" = {
        id = "75ycc-ar6pj";
        path = "${config.users.users.doromiert.home}/Documents/rondomix";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
        ];
        versioning = {
          type = "simple";
          params = {
            keep = "10";
          };
        };
      };

      # 3. Obsidian (-0)
      "obsidian-negative-zero" = {
        id = "Negative Zero";
        path = "${config.users.users.doromiert.home}/Documents/obsidian/-0";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
        ];
        versioning = {
          type = "simple";
          params = {
            keep = "10";
          };
        };
      };

      # 4. Obsidian (School)
      "obsidian-school" = {
        id = "o2qk0-vgpjz";
        path = "${config.users.users.doromiert.home}/Documents/obsidian/school";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
        ];
        versioning = {
          type = "simple";
          params = {
            keep = "10";
          };
        };
      };

      # 5. Obsidian (Ixni)
      "obsidian-ixni" = {
        id = "dlebo-khhal";
        path = "${config.users.users.doromiert.home}/Documents/obsidian/ixni";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
        ];
        versioning = {
          type = "simple";
          params = {
            keep = "10";
          };
        };
      };

      # 6. Passwords (KeePass)
      "passwords" = {
        id = "passwords";
        path = "${config.users.users.doromiert.home}/Passwords";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
          "i8"
        ];
        versioning = {
          type = "simple";
          params = {
            keep = "5";
          };
        };
      };

      # 7. Music (Receive Only from Main PC)
      "Music" = {
        id = "Music";
        path = "${config.users.users.doromiert.home}/Music";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
          "np2"
          "quest"
        ];
        type = "receiveonly";
      };

      # 8. rnote
      "rnote" = {
        id = "rnote";
        path = "${config.users.users.doromiert.home}/Documents/rnote";
        devices = [
          "doromi-tul-2"
          "doromi-server"
          "doromipad"
        ];
        versioning = {
          type = "simple";
          params = {
            keep = "5";
          };
        };
      };
    };
  };
}
