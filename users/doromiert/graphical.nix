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
    config.users.${username} = {
      accentColor = "purple";
      colorScheme = "adwaita";
      darkMode = true;
      defaults = {
        shell = pkgs.zsh;
        mail = pkgs.geary;
        terminal = pkgs.kitty;
        music = pkgs.decibels;
        browser = pkgs.firefox;
        fileManager = pkgs.nautilus;
        calendar = pkgs.gnome-calendar;
        photos = pkgs.loupe;
        video = pkgs.showtime;
      };
    };
  };
}
