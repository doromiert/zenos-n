# LOCATION: This file belongs in your 'ZenOS' system repository (flake.nix).
# DESCRIPTION: Imports 'utils' from 'zenpkgs.lib' instead of a local file.

{
  description = "ZenOS N (NixOS-based ZenOS)";

  inputs = {
    # core packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Import your separate package flake
    zenpkgs = {
      url = "github:zenos-n/zenpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # misc packages
    nix-gaming.url = "github:fufexan/nix-gaming";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixcord.url = "github:kaylorben/nixcord";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zenpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;

      version = {
        type = "beta";
        majorVer = "1.0";
        variant = "N";
        full = utils.osVersionString;
      };

      # Use the utility builder exported by zenpkgs
      utils = zenpkgs.lib.mkUtils { inherit lib inputs self; };

      zenOverlay = zenpkgs.overlays.default;

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
