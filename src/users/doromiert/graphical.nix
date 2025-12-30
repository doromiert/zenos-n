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