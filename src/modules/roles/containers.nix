{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------------
  # Docker Configuration
  # -------------------------------------------------------------------------
  virtualisation.docker = {
    enable = true;
    # Standard mode preferred for server-heavy workflows (Jellyfin, Immich)
    rootless = {
      enable = false;
      setSocketVariable = true;
    };
    daemon.settings = {
      "storage-driver" = "overlay2";
    };
  };

  # -------------------------------------------------------------------------
  # Permissions & Packages
  # -------------------------------------------------------------------------
  users.users.${config.mainUser}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
