# kitchen sink for the user
{ config, pkgs, ... }:

{
  users.users.aether = {
    isNormalUser = true;
    description = "aether";
    extraGroups = [
      "wheel"
      "networkmanager"
      "zenos-rebuild"
    ];
    shell = pkgs.zsh;
    initialPassword = "setmelater";
  };

  home-manager.users.aether = {

    # never touch this
    home.stateVersion = "25.11";

    home.file = {
      ".p10k.zsh".source = ./resources/p10k.zsh;
      # ".local/bin".source = ./bin;
    };

    programs = {

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      zsh = {

        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        # [P13.9] User-Specific Tools
        # Removed CD shortcuts as Zoxide handles navigation
        shellAliases = {
          # Git Rapid-Fire
          g = "git";
          ga = "git add";
          gaa = "git add .";
          gc = "git commit -m";
          gs = "git status";
          gp = "git push";
          gl = "git log --oneline --graph --decorate";

          # Nix / Direnv
          da = "direnv allow";
          dr = "direnv reload";

          # Networking
          myip = "curl ifconfig.me";
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
            name = "aether";
            email = "aether@gmail.com";
          };
          pull.rebase = false;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
