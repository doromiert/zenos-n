# kitchen sink for doromi-tul-2
{ lib, ... }:
{
  systemd.services.plymouth-quit-wait.enable = lib.mkForce false;

  # [3] Bonus: Kill Network Wait (2.4s saved)
  # Your blame logs showed this was also a major blocker.
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.ModemManager.enable = lib.mkForce false;
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
}
