# dev.nix
{ pkgs, ... }:

let
  # Define the specialized VS Code package with extensions
  vscode-with-exts = pkgs.vscode-with-extensions.override {
    vscodeExtensions =
      with pkgs.vscode-extensions;
      [
        # Essential for NixOS/CachyOS workflow
        bbenoist.nix
        jnoortheen.nix-ide
        mkhl.direnv
        piousdeer.adwaita-theme

        # Practical Utilities [P13.9]
        eamodio.gitlens
        esbenp.prettier-vscode
        vscodevim.vim
        bierner.github-markdown-preview

        # [P4.1] Uncomment when moving into C/C++ OS Dev
        # ms-vscode.cpptools
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # Logic for marketplace extensions not in nixpkgs
        /*
          {
              name = "example";
              publisher = "publisher";
              version = "1.0.0";
              sha256 = "0000000000000000000000000000000000000000000000000000";
          }
        */
      ];
  };
in
{
  environment.systemPackages = [
    vscode-with-exts
    pkgs.nixd
    pkgs.nixfmt-rfc-style
  ];

  # Essential for mkhl.direnv extension to function properly
  services.envfs.enable = true;
  programs.direnv.enable = true;
}
