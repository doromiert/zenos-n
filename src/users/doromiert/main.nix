# kitchen sink for the user
{ config, pkgs, ... }:

{
    users.users.doromiert = {
        isNormalUser = true;
        description = "doromiert";
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
        initialPassword = "setmelater";
    }

    home-manager.users.doromiert = {

        # never touch this
        home.stateVersion = "25.11";        

        home.file = {
            ".config/zsh".source = ./zsh;
            ".local/bin".source = ./bin;
        };

        home.directories = {
            downloads = "${config.home.homeDirectory}/Downloads";
            documents = "${config.home.homeDirectory}/Documents";
            desktop = "${config.home.homeDirectory}/Desktop";
            funny = "${config.home.homeDirectory}/Funny";
            projects = "${config.home.homeDirectory}/Projects";
            threeD = "${config.home.homeDirectory}/3D";
            android = "${config.home.homeDirectory}/Android";
            ai = "${config.home.homeDirectory}/AI";
            appsAndScripts = "${config.home.homeDirectory}/Apps & Scripts";
            doom = "${config.home.homeDirectory}/Doom";
            rift = "${config.home.homeDirectory}/Rift";
            random = "${config.home.homeDirectory}/Random";
            passwords = "${config.home.homeDirectory}/Passwords";
        };

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
                        name  = "";
                        email = "";
                    };
                    init.defaultBranch = "main";
                };
            };
        };
    }
}