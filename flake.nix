{
    description = "ZenOS N (NixOS-based ZenOS)";

    # Vanity Metadata (Custom attributes for organizational clarity)
    # These can be accessed via self.metadata within your system
    metadata = {
        name = "ZenOS N";
        version = "1.0";
        codename = "Cacao";
        maintainer = "doromiert";
    };

    inputs = {
        # Primary System Provider (Stable 25.11)
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
        
        # Unstable branch for bleeding edge tools/games
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Styling engine for consistent UI/UX across ZenOS
        stylix = {
            url = "github:danth/stylix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nix-gaming = {
            url = "github:fufexan/nix-gaming";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        vsc-extensions = {
            url = "github:nix-community/nix-vscode-extensions";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixos-hardware.url = "github:nixos/nixos-hardware";
        
        swisstag.url = "github:doromiert/swisstag";

        # Experimental lab inputs
        nix-experimental = {
            url = "github:rirolab/nyx";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: 
    let
        system = "x86_64-linux";
        
        # Helper to allow using unstable packages in stable modules
        # Usage: environment.systemPackages = [ pkgs.unstable.steam ];
        overlay-unstable = final: prev: {
            unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
            };
        };
    in {
        nixosConfigurations.doromitul2 = nixpkgs.lib.nixosSystem {
            inherit system;
            
            # specialArgs passes variables into every .nix file in your config
            specialArgs = { 
                inherit inputs;
                # Pass self so modules can access self.metadata
                inherit self;
                # Alternative to overlay: direct access to unstable
                pkgs-unstable = import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfree = true;
                };
            };
            
            modules = [
                # 1. Global Nix Settings & Overlays
                ({ config, pkgs, ... }: { 
                    nixpkgs.overlays = [ overlay-unstable ]; 
                    # Set custom ZenOS versioning in the system state
                    system.configurationRevision = self.rev or "dirty";
                    system.stateVersion = "25.11";
                })

                # 2. Device Specific (Main PC: doromi tul II)
                ./src/hosts/doromi-tul-2/main.nix
                ./src/hosts/doromi-tul-2/hardware.nix
                ./src/hosts/doromi-tul-2/syncthing.nix

                # 3. Core Modules (The ZenOS Foundation)
                ./src/modules/core/branding.nix
                ./src/modules/core/misc-services.nix
                ./src/modules/core/security.nix
                ./src/modules/core/shell.nix
                ./src/modules/core/syncthing.nix

                # 4. Roles (Workflows)
                ./src/modules/roles/creative.nix
                ./src/modules/roles/gaming.nix
                ./src/modules/roles/dev.nix
                ./src/modules/roles/virtualization.nix
                ./src/modules/roles/web.nix

                # 5. Desktop Environment & UX
                ./src/modules/desktop/gnome.nix
                ./src/modules/desktop/styling.nix

                # 6. User Configurations
                ./src/users/doromiert/main.nix
                ./src/users/doromiert/graphical.nix

                # 7. Hardware & Community Optimizations
                inputs.nixos-hardware.nixosModules.common-cpu-amd
                inputs.nixos-hardware.nixosModules.common-gpu-amd
                inputs.nixos-hardware.nixosModules.common-pc-ssd
                inputs.nix-gaming.nixosModules.platformOptimizations
                
                # 8. External Module Activation
                inputs.home-manager.nixosModules.home-manager
                inputs.stylix.nixosModules.stylix
            ];
        };
    };
}