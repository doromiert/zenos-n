# @file: hosts/doromi-server/main.nix
# @brief: Host configuration for doromi server.
# @context: host configuration
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./placeholder.nix
  ];

  zenos = {
    deviceIcon = "server";
    prettyName = "doromi server";
    users = [
      "doromiert"
      "hubi"

    ];
    isServer = true;
    locale = {
      timeZone = "Europe/Warsaw";
      language = "en_US.UTF-8";
      defaultLocale = "pl_PL.UTF-8";
      kbLayout = "pl";
    };
    admin = "doromiert";
    zenfs = {
      # will be replaced by the installer ↓
      rootUUID = "f3fbcbcc-1063-426b-a0ab-0ddb7ff9dd76";
      bootUUID = "3296-E5E9";
    };

    modules = {
      server = [ "copyparty" ];

    };
    deviceConfigs = {
      qemu-guest.enable = true;
    };
  };
}
