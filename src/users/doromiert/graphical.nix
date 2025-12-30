{ config, pkgs, inputs, ... }: {
    # Ensure the Nixcord module is imported
    imports = [
        ./shortcuts.nix
        inputs.nixcord.homeModules.nixcord
    ];

    home-manager.users.doromiert = {
        # Regular packages
        packages = with pkgs; [
            telegram-desktop
        ];

        programs.nixcord = {
            enable = true;
            discord = {
                enable = true;
                vencord = true;
            };

            config = {
                useQuickCss = true;
                
                # Global Vencord Settings
                enabledThemes = [ ];
                
                # Highly Practical Plugin Configuration [p13.9 focus]
                plugins = {
                    # Essentials
                    fakeNitro.enable = {
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
                    clearURLs.enable = true;
                    copyUserURLs.enable = true;
                    
                    # Performance/Fixes
                    vencordToolbox.enable = true;
                    webKeybinds.enable = true;
                    webScreenShareFixes.enable = true;

                    # Custom RPC
                    customRPC = {
                        enable = true;
                        type = 0; # Playing
                        name = "Sex 2";
                        details = "Duos";
                    };
                };
            };
            
            quickCss = ''

            '';
        };
    };
}