# vm-desktop-test-specific syncthing settings
{
  services.syncthing = {
    dataDir = "${config.users.users.doromiert.home}/.local/share/syncthing";
    configDir = "${config.users.users.doromiert.home}/.config/syncthing";

    folders = {
      "placeholder" = {
        path = "";
        devices = [ ];
        ignorePerms = false;
      };
    };
  };
}
