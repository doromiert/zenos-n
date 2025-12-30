{ config, pkgs, inputs, ... }: {
    # Ensure the Nixcord module is imported

    home-manager.users.doromiert = {
        imports = [
            ./shortcuts.nix
            inputs.nixcord.homeModules.nixcord
        ];
        # Regular packages
        home.packages = with pkgs; [
            telegram-desktop
        ];
        
        programs.vscode = {
            enable = true;
            # [P5.1] FOSS Philosophy: Uncomment the line below to use VSCodium instead
            # package = pkgs.vscodium; 
            
            # [P9] Efficiency: Extensions managed here are immutable (cannot install via GUI)
            extensions = with pkgs.vscode-extensions; [
                # Essential for your NixOS/CachyOS workflow
                bbenoist.nix
                jnoortheen.nix-ide
                mkhl.direnv 
                
                # Practical Utilities [P13.9]
                eamodio.gitlens
                esbenp.prettier-vscode
                # ms-vscode.cpptools # [P4.1] Uncomment for C/C++
            ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                # Use this logic ONLY for extensions not found in nixpkgs
                # {
                #    name = "remote-ssh-edit";
                #    publisher = "ms-vscode-remote";
                #    version = "0.47.2";
                #    sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34n1kx";
                # }
            ];

            # Define settings.json here
            userSettings = {
                "editor.fontFamily" = "'Atkinson Hyperlegible Mono', monospace";
                "editor.formatOnSave" = true;
                "nix.enableLanguageServer" = true;
                "nix.serverPath" = "nil";
                "window.menuBarVisibility" = "toggle";
                "workbench.colorTheme" = "Default Dark Modern";
            };
        };

        programs.nixcord = {
            enable = true;
            discord = {
                enable = true;
                vencord.enable = true;
            };

            config = {
                useQuickCss = true;
                
                # Global Vencord Settings
                enabledThemes = [ ];
                
                # Highly Practical Plugin Configuration [p13.9 focus]
                plugins = {
                    # Essentials
                    fakeNitro = {
                        enable = true;
                        transformEmojis = true;
                    };
                    
                    # UI Improvements
                    betterFolders = {
                        enable = true;
                        sidebar = true;
                        sidebarAnim = true;
                    };
                    memberCount.enable = true;
                    showHiddenThings.enable = true;
                    
                    # Privacy & Utility
                    callTimer.enable = true;
                    ClearURLs.enable = true;
                    CopyUserURLs.enable = true;
                    
                    # Performance/Fixes
                    vencordToolbox.enable = true;
                    webKeybinds.enable = true;
                    webScreenShareFixes.enable = true;

                    # Custom RPC
                    CustomRPC = {
                        enable = true;
                        config = {
                            type = 0; # Playing
                            name = "Sex 2";
                            details = "Duos";
                        };
                    };
                };
            };
            
            quickCss = ''

            '';
        };
    };
}
