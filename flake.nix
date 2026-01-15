{
  description = "ZenOS N (NixOS-based ZenOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-gaming.url = "github:fufexan/nix-gaming";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";

    vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixcord.url = "github:kaylorben/nixcord";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zenpkgs = {
      url = "github:doromiert/zenpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;

      version = {
        type = "beta";
        majorVer = "1.0";
        variant = "N";
      };

      utils = import ./lib/utils.nix { inherit lib inputs; };
      zenOverlay = inputs.zenpkgs.overlays.default;

      mkHost =
        hostName:
        lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              outputs
              utils
              version
              ;
          };
          modules = [
            (./hosts + "/${hostName}/main.nix")
            ./modules/structure.nix
            { nixpkgs.overlays = [ zenOverlay ]; }
            inputs.zenpkgs.nixosModules.zenfs
          ]
          # Auto-import everything
          ++ (utils.recursiveImports ./modules)
          ++ (utils.recursiveImports ./deviceConfigs)
          ++ (utils.recursiveImports ./coremodules)
          ++ (utils.recursiveImports ./users);
        };

      hostList = builtins.attrNames (builtins.readDir ./hosts);
    in
    {
      overlays.default = zenOverlay;
      nixosConfigurations = lib.genAttrs hostList (host: mkHost host);
    };
}
