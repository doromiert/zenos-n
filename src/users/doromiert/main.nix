# kitchen sink for the user
{ config, pkgs, ... }:

{
  users.users.doromiert = {
    isNormalUser = true;
    description = "doromiert";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    initialPassword = "setmelater";
  };

  home-manager.users.doromiert = {

    # never touch this
    home.stateVersion = "25.11";

    home.file = {
      ".config/zsh".source = ./resources/p10k.zsh;
      # ".local/bin".source = ./bin;
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;

      # Standard XDG paths
      download = "${config.users.users.doromiert.home}/Downloads";
      documents = "${config.users.users.doromiert.home}/Documents";
      desktop = "${config.users.users.doromiert.home}/Desktop";

      # Custom paths go into extraConfig
      extraConfig = {
        XDG_FUNNY_DIR = "${config.users.users.doromiert.home}/Funny";
        XDG_PROJECTS_DIR = "${config.users.users.doromiert.home}/Projects";
        XDG_THREED_DIR = "${config.users.users.doromiert.home}/3D";
        XDG_ANDROID_DIR = "${config.users.users.doromiert.home}/Android";
        XDG_AI_DIR = "${config.users.users.doromiert.home}/AI";
        XDG_APPS_SCRIPTS_DIR = "${config.users.users.doromiert.home}/Apps & Scripts";
        XDG_DOOM_DIR = "${config.users.users.doromiert.home}/Doom";
        XDG_RIFT_DIR = "${config.users.users.doromiert.home}/Rift";
        XDG_RANDOM_DIR = "${config.users.users.doromiert.home}/Random";
        XDG_PASSWORDS_DIR = "${config.users.users.doromiert.home}/Passwords";
      };
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
            name = "doromiert";
            email = "doromiert@gmail.com";
          };
          init.defaultBranch = "main";
        };
      };
    };
  };
}
