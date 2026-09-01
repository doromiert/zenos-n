# stuff for devving
{ pkgs, ... }:

{

  environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
    pkgs.android-tools
    pkgs.meson
    pkgs.ninja
    pkgs.scrcpy
    pkgs.unityhub
    pkgs.unstable.claude-code
    pkgs.unstable.zed-editor
    pkgs.vscode-css-languageserver
    pkgs.clang-tools # provides clangd
    pkgs.rust-analyzer
    pkgs.cargo

    # JS/TS/Svelte/HTML/CSS
    pkgs.nodePackages.typescript-language-server
    pkgs.nodePackages.svelte-language-server
    pkgs.prettierd # faster prettier daemon (or pkgs.nodePackages.prettier)

    # Python
    pkgs.pyright # intellisense/types
    pkgs.ruff # fast linter + formatter
    (pkgs.gnome-builder.overrideAttrs (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.makeWrapper ];
      postInstall = ''
        wrapProgram $out/bin/gnome-builder \
          --prefix PATH : ${
            pkgs.lib.makeBinPath [
              pkgs.python3Packages.python-lsp-server
              pkgs.rust-analyzer
              pkgs.clang-tools # for c/c++
              pkgs.nodePackages.typescript-language-server
            ]
          }
      '';
    }))
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
        package = (
          pkgs.vscode.override {
            commandLineArgs = [
              # 1. Force Native Wayland
              "--ozone-platform=wayland"
              "--enable-features=WaylandWindowDecorations"

              # 2. THE FIX: Force it to ignore System 1.25x and render at 1:1
              "--force-device-scale-factor=1"

              "--force-renderer-accessibility"

              # Optional: If you need to expose the tree to external tools via bus
              "--enable-caret-browsing"
            ];
          }
        );
        # [P13.9] Practical Utilities & Core Workflow
        extensions =
          with pkgs.vscode-extensions;
          [
            # Essential for NixOS/CachyOS workflow
            bbenoist.nix
            piousdeer.adwaita-theme
            ms-vsliveshare.vsliveshare

            # c#
            #ms-dotnettools.vscode-dotnet-runtime
            #ms-dotnettools.csharp

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
          "editor.fontFamily" = "'AtkynsonMono NF', monospace";
          "editor.fontSize" = 14;
          "window.menuBarVisibility" = "toggle";
          "window.titleBarStyle" = "custom";
          "workbench.colorTheme" = "Adwaita Dark";

          # Structural Settings
          "editor.formatOnSave" = true;
          "editor.insertSpaces" = true;
          "editor.detectIndentation" = false;

          # Nix Integration
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";

          # Git
          "gitlens.codeLens.enabled" = true;
          "git.confirmSync" = false;
          "git.autofetch" = false;
        };
      };
    }
  ];
}
