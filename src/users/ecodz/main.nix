# kitchen sink for the user
{ config, pkgs, ... }:

{
  users.users.ecodz = {
    isNormalUser = true;
    description = "";
    extraGroups = [ ];
    shell = pkgs.zsh;
    initialPassword = "setmelater";
  };

  home-manager.users.ecodz = {

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
