{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------------
  # Docker Configuration
  # -------------------------------------------------------------------------
  virtualisation.docker = {
    enable = true;
    # The module still defaults to docker_28, which nixpkgs marked insecure in
    # November 2025 (unmaintained). Pin forward rather than permitting it.
    package = pkgs.docker_29;
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
