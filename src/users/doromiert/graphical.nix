{ config, pkgs, inputs, lib, ... }: {
    # Ensure the Nixcord module is imported

    home-manager.users.doromiert = {
        imports = [
            ./shortcuts.nix
            ./dconf.nix
            inputs.nixcord.homeModules.nixcord
        ];

        # Regular packages
        home.packages = with pkgs; [
            telegram-desktop
        ];
        
        programs.vscode = {
            enable = true;
            userSettings = {
                # Your Requested Overrides
                "editor.fontFamily" = "'Atkinson Hyperlegible Mono', monospace";
                "editor.formatOnSave" = true;
                "nix.enableLanguageServer" = true;
                "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
                "window.menuBarVisibility" = "toggle";
                "workbench.colorTheme" = "Adwaita Dark";

                # Structural/Philosophy Settings [P6.6]
                "editor.tabSize" = 4;
                "editor.insertSpaces" = true;
                "editor.detectIndentation" = false;
                
                # UI/UX Cleanliness [P5.4]
                "window.titleBarStyle" = "custom";
                "editor.fontSize" = 14;
                "gitlens.codeLens.enabled" = true;
                
                # Vim Integration
                "vim.useSystemClipboard" = true;
                "vim.hlsearch" = true;
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
