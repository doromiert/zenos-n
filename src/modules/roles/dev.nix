# stuff for devving
{ pkgs, lib, ... }:

{
  environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
  ];

  # -- Flatpak Dev Tools --
  services.flatpak.packages = [
    "me.iepure.devtoolbox" # Dev Toolbox
  ];

  # Essential for mkhl.direnv extension to function properly
  services.envfs.enable = true;
  programs.direnv.enable = true;

  # [P6.2] VS Code Architecture: Switched to Home Manager Shared Module
  # This allows graphical.nix to extend the configuration (e.g. adding Vim) cleanly.
  home-manager.sharedModules = [
    {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;

        # [P13.9] Practical Utilities & Core Workflow
        extensions =
          with pkgs.vscode-extensions;
          [
            # Essential for NixOS/CachyOS workflow
            bbenoist.nix
            jnoortheen.nix-ide
            mkhl.direnv
            piousdeer.adwaita-theme
            ms-vsliveshare.vsliveshare

            # Utilities
            eamodio.gitlens
            esbenp.prettier-vscode
            bierner.github-markdown-preview
            yy0931.vscode-sqlite3-editor

            # [P4.1] C/C++ (Uncomment when needed)
            # ms-vscode.cpptools
          ]
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            # Marketplace logic preserved here
          ];

        # [P5.4] Structural & UI Settings (Moved from graphical.nix)
        userSettings = {
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

          # Git
          "gitlens.codeLens.enabled" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.suggestSmartCommit" = false;
          "git.autofetch" = true;
        };
      };
    }
  ];
}
