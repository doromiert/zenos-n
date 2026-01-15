# kitchen sink for the user
{ config, pkgs, ... }:

{
  users.users.cat = {
    isNormalUser = true;
    description = "cat";
    extraGroups = [
      "wheel"
      "networkmanager"
      "zenos-rebuild"
    ];
    shell = pkgs.zsh;
    initialPassword = "setmelater";
  };

  home-manager.users.cat = {

    # never touch this
    home.stateVersion = "25.11";

    home.file = {
      ".p10k.zsh".source = ./resources/p10k.zsh;
      # ".local/bin".source = ./bin;
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;

      # Standard XDG paths
      download = "${config.users.users.cat.home}/Downloads";
      documents = "${config.users.users.cat.home}/Documents";
      desktop = "${config.users.users.cat.home}/Desktop";

      # Custom paths go into extraConfig
      extraConfig = {
        XDG_FUNNY_DIR = "${config.users.users.cat.home}/Funny";
        XDG_PROJECTS_DIR = "${config.users.users.cat.home}/Projects";
        XDG_THREED_DIR = "${config.users.users.cat.home}/3D";
        XDG_ANDROID_DIR = "${config.users.users.cat.home}/Android";
        XDG_AI_DIR = "${config.users.users.cat.home}/AI";
        XDG_APPS_SCRIPTS_DIR = "${config.users.users.cat.home}/Apps & Scripts";
        XDG_DOOM_DIR = "${config.users.users.cat.home}/Doom";
        XDG_RIFT_DIR = "${config.users.users.cat.home}/Rift";
        XDG_RANDOM_DIR = "${config.users.users.cat.home}/Random";
        XDG_PASSWORDS_DIR = "${config.users.users.cat.home}/Passwords";
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
            name = "cat";
            email = "cat@gmail.com";
          };
          pull.rebase = false;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
