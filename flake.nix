{
    description = "ZenOS N (NixOS-based ZenOS) - Codename Cacao";

    # Vanity Metadata
    metadata = {
        name = "ZenOS N";
        version = "1.0";
        codename = "Cacao";
        maintainer = "doromiert";
    };

    inputs = {
        # --- Package Sources ---
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

        # --- System Utilities & Optimization ---
        chaotic.url = "github:chaotic-cx/nyx";
        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        stylix = {
            url = "github:danth/stylix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # --- Hardware & Gaming ---
        nixos-hardware.url = "github:nixos/nixos-hardware";
        nix-gaming = {
            url = "github:fufexan/nix-gaming";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # --- Development & Custom Tools ---
        vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
        swisstag.url = "github:doromiert/swisstag";

        # --- Experimental/Lab ---
        nix-experimental = {
            url = "github:rirolab/nyx";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs:
    let
        system = "x86_64-linux";
        
        # Centralized configuration for ease of maintenance
        # This function generates a host configuration with common defaults
        mkHost = { hostName, extraModules ? [], isServer ? false }: 
            nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = { 
                    inherit inputs self hostName;
                    # Define unstable pkgs here so it's consistent across all hosts
                    pkgs-unstable = import nixpkgs-unstable {
                        inherit system;
                        config.allowUnfree = true;
                    };
                };
                modules = [
                    # 1. Base Logic & Overlays
                    ({ config, pkgs, ... }: { 
                        nixpkgs.overlays = [ 
                            (final: prev: {
                                unstable = import nixpkgs-unstable {
                                    inherit system;
                                    config.allowUnfree = true;
                                };
                            })
                        ]; 
                        system.configurationRevision = self.rev or "dirty";
                        system.stateVersion = "25.11";
                        networking.hostName = hostName;
                    })

                    # 2. Universal ZenOS Foundation (Core)
                    ./src/modules/core/branding.nix
                    ./src/modules/core/misc-services.nix
                    ./src/modules/core/security.nix
                    ./src/modules/core/shell.nix
                    ./src/modules/core/syncthing.nix

                    # 3. Desktop Environment (If not a server)
                    (if !isServer then ./src/modules/desktop/gnome.nix else {})
                    (if !isServer then ./src/modules/desktop/styling.nix else {})

                    # 4. Global External Modules
                    inputs.home-manager.nixosModules.home-manager
                    inputs.stylix.nixosModules.stylix

                ] ++ extraModules;
            };
    in {
        nixosConfigurations = {
            # --- Main PC: doromi tul II ---
            # Ryzen 9 7900 + RX 6900XT
            doromitul2 = mkHost {
                hostName = "doromitul2";
                extraModules = [
                    ./src/hosts/doromi-tul-2/main.nix
                    ./src/hosts/doromi-tul-2/hardware.nix
                    ./src/hosts/doromi-tul-2/syncthing.nix
                    
                    ./src/modules/roles/creative.nix
                    ./src/modules/roles/gaming.nix
                    ./src/modules/roles/dev.nix
                    ./src/modules/roles/virtualization.nix
                    ./src/modules/roles/web.nix

                    ./src/users/doromiert/main.nix
                    ./src/users/doromiert/graphical.nix

                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                    inputs.nixos-hardware.nixosModules.common-pc-ssd
                    inputs.nix-gaming.nixosModules.platformOptimizations
                ];
            };

            # --- Laptop: ThinkPad L13 (doromipad) ---
            doromipad = mkHost {
                hostName = "doromipad";
                extraModules = [
                    ./src/hosts/doromipad/main.nix
                    ./src/hosts/doromipad/hardware.nix
                    ./src/hosts/doromipad/syncthing.nix

                    ./src/modules/roles/creative.nix
                    ./src/modules/roles/tablet.nix
                    ./src/modules/roles/dev.nix
                    ./src/modules/roles/virtualization.nix
                    ./src/modules/roles/web.nix

                    ./src/users/doromiert/main.nix
                    ./src/users/doromiert/graphical.nix

                    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l13-yoga
                    inputs.nixos-hardware.nixosModules.common-cpu-intel
                    inputs.nixos-hardware.nixosModules.common-pc-ssd
                ];
            };

            # --- Home Server: doromi-server ---
            doromi-server = mkHost {
                hostName = "doromi-server";
                isServer = true;
                extraModules = [
                    ./src/hosts/doromi-server/main.nix
                    ./src/hosts/doromi-server/hardware.nix
                    ./src/hosts/doromi-server/syncthing.nix

                    # Server Services
                    ./src/server/cloudflare.nix
                    ./src/server/copyparty.nix
                    ./src/server/forgejo.nix
                    ./src/server/immich.nix
                    ./src/server/jellyfin.nix
                    ./src/server/minecraft.nix

                    # Multi-user Configuration
                    ./src/users/aether/main.nix
                    ./src/users/blade0/main.nix
                    ./src/users/cnb/main.nix
                    ./src/users/doromiert/main.nix
                    ./src/users/ecodz/main.nix
                    ./src/users/hubi/main.nix
                    ./src/users/jeyphr/main.nix
                    ./src/users/lenni/main.nix
                    ./src/users/meowster/main.nix
                    ./src/users/saphhie/main.nix
                    ./src/users/saxum/main.nix
                    ./src/users/shareduser/main.nix
                    ./src/users/xen/main.nix

                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                ];
            };
        };
    };
}