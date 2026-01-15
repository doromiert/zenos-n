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

    # ... keep your other inputs here ...
    vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixcord.url = "github:kaylorben/nixcord";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NEW: Your separate overlay repository
    zenpkgs = {
      url = "path:/home/doromiert/Projects/zenpkgs"; # dev env
      # url = "github:doromiert/zenpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;

      # --- 1. Centralized Version Logic ---
      version = {
        type = "beta";
        majorVer = "1.0";
        variant = "N";
      };

      # Import our custom helper functions
      utils = import ./lib/utils.nix { inherit lib inputs; };

      # Define the overlay (Now pulled from the flake input)
      zenOverlay = inputs.zenpkgs.overlays.default;

      # Function to simplify host creation
      mkHost =
        hostName:
        lib.nixosSystem {
          # We pass 'version' here so it's available in every module's args
          specialArgs = {
            inherit
              inputs
              outputs
              utils
              version
              ;
          };
          modules = [
            # 1. The Host Configuration
            (./hosts + "/${hostName}/main.nix")

            # 2. The Module Structure Logic
            ./modules/structure.nix

            # 3. Import overlays
            { nixpkgs.overlays = [ zenOverlay ]; }
          ]
          # Auto-import modules, deviceConfigs, and coremodules
          ++ (utils.recursiveImports ./modules)
          ++ (utils.recursiveImports ./deviceConfigs)
          ++ (utils.recursiveImports ./coremodules);
        };

      hostList = builtins.attrNames (builtins.readDir ./hosts);
    in
    {
      # Export the overlay so it can be used elsewhere if needed
      overlays.default = zenOverlay;

      # Automatically generate nixosConfigurations for every folder in ./hosts
      nixosConfigurations = lib.genAttrs hostList (host: mkHost host);
    };
}
