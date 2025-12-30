# kitchen sink for the user
{ config, pkgs, ... }:

{
    users.users.doromiert = {
        isNormalUser = true;
        description = "doromiert";
        extraGroups = [ "wheel" "networkmanager" ];
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
            download = "/home/doromiert/Downloads";
            documents = "/home/doromiert/Documents";
            desktop = "/home/doromiert/Desktop";

            # Custom paths go into extraConfig
            extraConfig = {
                XDG_FUNNY_DIR = "/home/doromiert/Funny";
                XDG_PROJECTS_DIR = "/home/doromiert/Projects";
                XDG_THREED_DIR = "/home/doromiert/3D";
                XDG_ANDROID_DIR = "/home/doromiert/Android";
                XDG_AI_DIR = "/home/doromiert/AI";
                XDG_APPS_SCRIPTS_DIR = "/home/doromiert/Apps & Scripts";
                XDG_DOOM_DIR = "/home/doromiert/Doom";
                XDG_RIFT_DIR = "/home/doromiert/Rift";
                XDG_RANDOM_DIR = "/home/doromiert/Random";
                XDG_PASSWORDS_DIR = "/home/doromiert/Passwords";
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

                shellAliases = {

                };

                history.size = 10000;

                zplug = {
                    enable = true;
                    plugins = [
                        { name = "zsh-users/zsh-autosuggestions"; } 
                        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; }
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
                        name  = "doromiert";
                        email = "doromiert@gmail.com";
                    };
                    init.defaultBranch = "main";
                };
            };
        };
    };
}