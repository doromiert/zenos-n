{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = "doromiert";
  cfg = config.zenos;

  # Condition: User is enabled AND (Desktops list is not empty OR isServer is false)
  # You can customize the logic for "what counts as graphical"
  userEnabled = lib.elem username cfg.users;
  hasDesktop = (cfg.modules.desktops or [ ]) != [ ];

  # Enable only if both are true
  enableGraphical = userEnabled && hasDesktop;
in
{
  config = lib.mkIf enableGraphical {
    # Graphical-only settings for this user
    # e.g. Home Manager graphical apps

    # users.users.${username}.packages = with pkgs; [
    #   firefox
    #   vscode
    # ];
  };
}
