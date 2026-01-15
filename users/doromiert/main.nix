# @file: users/doromiert/main.nix
# @brief: User configuration for doromiert. This config is supposed to be useful for both server and desktop environments. But it isn't specific to either.
# @context: user configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = "doromiert";
  cfg = config.zenos;

  # Check if this user is in the enabled list
  isEnabled = lib.elem username cfg.users;
  isAdmin = cfg.admin == username;
in
{
  config = lib.mkIf isEnabled {
    users.users.${username} = {
      isNormalUser = true;
      description = "Doromiert";
      extraGroups = [
        "networkmanager"
        "video"
        "audio"
      ]
      ++ (lib.optional isAdmin "wheel");
      shell = pkgs.fish;

      # You can add authorized keys here
      # openssh.authorizedKeys.keys = [ ... ];
    };

    # Optional: Home Manager import if you use it directly
    # home-manager.users.${username} = import ./home.nix;
  };
}
