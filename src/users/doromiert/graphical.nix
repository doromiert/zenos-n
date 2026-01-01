{
  inputs,
  ...
}:
{
  # Ensure the Nixcord module is imported

  home-manager.users.doromiert =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # [P5.4] & [P6.6] VS Code Settings Definition
      vscodeSettings = {
        # UI/UX Cleanliness
        "editor.fontFamily" = "'Atkinson Hyperlegible Mono', monospace";
        "editor.fontSize" = 14;
        "window.menuBarVisibility" = "toggle";
        "window.titleBarStyle" = "custom";
        "workbench.colorTheme" = "Adwaita Dark";

        # Structural Settings
        "editor.formatOnSave" = true;
        "editor.tabSize" = 4;
        "editor.insertSpaces" = true;
        "editor.detectIndentation" = false;

        # Nix Integration
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";

        # Extensions Config
        "gitlens.codeLens.enabled" = true;
        "vim.useSystemClipboard" = true;
        "vim.hlsearch" = true;
      };

      # Generate the JSON file in the Nix store
      settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscodeSettings);
    in
    {
      imports = [
        ./shortcuts.nix
        ./dconf.nix
        inputs.nixcord.homeModules.nixcord
      ];
      home.file.".config/forge/windows.json".source = ./resources/windows.json;

      # Regular packages
      home.packages = with pkgs; [
        telegram-desktop
        # [P13.D] Ensure formatter is available for the LSP
        nixfmt-rfc-style
      ];

      # [ ! ] ACTIVATION SCRIPT
      # Copies settings.json from store to config dir and makes it writable (chmod u+w)
      # This replaces xdg.configFile to allow runtime edits by VS Code.
      home.activation.configureVscode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/Code/User
        $DRY_RUN_CMD cp -f "${settingsFile}" "$HOME/.config/Code/User/settings.json"
        $DRY_RUN_CMD chmod u+w "$HOME/.config/Code/User/settings.json"
      '';

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
