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
        
        xdg.configFile."Code/User/settings.json".text = builtins.toJSON {
            # [P5.4] UI/UX Cleanliness
            "editor.fontFamily" = "'Atkinson Hyperlegible Mono', monospace";
            "editor.fontSize" = 14;
            "window.menuBarVisibility" = "toggle";
            "window.titleBarStyle" = "custom";
            "workbench.colorTheme" = "Adwaita Dark";
            
            # [P6.6] Structural Settings
            "editor.formatOnSave" = true;
            "editor.tabSize" = 4;
            "editor.insertSpaces" = true;
            "editor.detectIndentation" = false;
            
            # Nix Integration
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
            
            # Extensions Config (These will work because the System binary has the exts)
            "gitlens.codeLens.enabled" = true;
            "vim.useSystemClipboard" = true;
            "vim.hlsearch" = true;
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
