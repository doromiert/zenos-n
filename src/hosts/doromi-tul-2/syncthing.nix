# doromi-tul-2-specific syncthing settings
{ config, pkgs, lib, ... }:

{
  services.syncthing = {
    enable = true;
    user = config.mainUser; # Dynamically use the mainUser defined in flake.nix
    group = "users";
    
    # Using config.users.users.${config.mainUser}.home is safe here as long as config is in scope
    dataDir = "${config.users.users.${config.mainUser}.home}/.local/share/syncthing";
    configDir = "${config.users.users.${config.mainUser}.home}/.config/syncthing";

    settings.folders = {

      # 1. Books
      "books" = {
        id = "6dovv-1tpo9";
        path = "${config.users.users.${config.mainUser}.home}/Documents/books";
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
        path = "${config.users.users.${config.mainUser}.home}/Documents/rondomix";
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
        path = "${config.users.users.${config.mainUser}.home}/Documents/obsidian/-0";
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
        path = "${config.users.users.${config.mainUser}.home}/Documents/obsidian/school";
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
        path = "${config.users.users.${config.mainUser}.home}/Documents/obsidian/ixni";
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
        path = "${config.users.users.${config.mainUser}.home}/Passwords";
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
        path = "${config.users.users.${config.mainUser}.home}/Music";
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
        path = "${config.users.users.${config.mainUser}.home}/Documents/rnote";
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
