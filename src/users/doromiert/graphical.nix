{
  inputs,
  ...
}:
{
  # Ensure the Nixcord module is imported

  home-manager.users.doromiert =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        ./shortcuts.nix
        ./dconf.nix
        ./pwa.nix
        ./keepass.nix
        inputs.nixcord.homeModules.nixcord
      ];
      #home.file.".config/forge/config/windows.json".source = ./resources/windows.json;

      # Regular packages
      home.packages = with pkgs; [
        telegram-desktop
        # [P13.D] Ensure formatter is available for the LSP
        nixfmt-rfc-style
      ];

      # [USER SPECIFIC] VS Code Overrides
      # This extends the base configuration defined in dev.nix
      programs.vscode = {
        # The Vim Addon (User Preference)
        extensions = [ pkgs.vscode-extensions.vscodevim.vim ];

        userSettings = {
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
