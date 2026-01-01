# kitchen sink for the user
{ config, pkgs, ... }:

{
  users.users.cat = {
    isNormalUser = true;
    description = "";
    extraGroups = [ ];
    shell = pkgs.zsh;
    initialPassword = "setmelater";
  };
  # btw id rather not use nix for configuring hyprland,
  # i did the repalcement for you :3
  # oh about that
  # you can use fucking anything
  # and just use nix as the glue that does cp file somewhere lol NEI GE
  home-manager.users.cat = {

    # never touch this
    stateVersion = "25.11";

    programs = {

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      zsh = {

        enable = true;
        enableCompletions = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {

        };

        history.size = 10000;

        zplug = {
          enable = true;
          plugins = [
            { name = "zsh-users/zsh-autosuggestions"; }
            {
              name = "romkatv/powerlevel10k";
              tags = [
                "as:theme"
                "depth:1"
              ];
            }
          ];
        };

        initContent = ''
          bindkey "''${key[Up]}" up-line-or-search
          bindkey "''${key[Down]}" down-line-or-search
        '';
      };

      zoxide = {

        enable = true;
        enableZshIntegration = true;
      };

      git = {
        enable = true;
        settings = {
          user = {
            name = "";
            email = "";
          };
          init.defaultBranch = "main";
        };
      };
    };
  };
}
