# kitty-laptop-specific syncthing settings
{
  services.syncthing = {
    dataDir = "/home/cat/.local/share/syncthing";
    configDir = "/home/cat/.config/syncthing";

    folders = {
      "placeholder" = {
        path = "";
        devices = [ ];
        ignorePerms = false;
      };
    };
  };
}
# and this is just for syncthing folders
# there's a global syncthing file fyi
