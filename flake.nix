{
    description = "ZenOS N (NixOS-based ZenOS)";

    # Flake metadata
    metadata = {
        name = "ZenOS N";
        version = "1.0";
        codename = "Cacao";
        maintainer = "doromiert";
    };

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
        chaotic.url = "github:chaotic-cx/nyx";

        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        stylix = {
            url = "github:danth/stylix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixos-hardware.url = "github:nixos/nixos-hardware";
        nix-gaming = {
            url = "github:fufexan/nix-gaming";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
        swisstag.url = "github:doromiert/swisstag";
    };

    outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs:
    let
        system = "x86_64-linux";
        lib = nixpkgs.lib;

        # Generic directory importer with exclude support
        # Scans a directory for .nix files, ignores subdirectories (like 'resources')
        # and files specified in the excludes list (by filename without extension).
        importDir = path: excludes:
            let
                content = builtins.readDir path;
                nixFiles = lib.filterAttrs (name: type: 
                    type == "regular" && 
                    lib.hasSuffix ".nix" name && 
                    name != "default.nix" &&
                    !builtins.elem (lib.removeSuffix ".nix" name) excludes
                ) content;
            in
            map (name: path + "/${name}") (builtins.attrNames nixFiles);

        mkHost = { 
            hostName, 
            mainUser ? "doromiert", # Added mainUser argument
            extraModules ? [], 
            desktop ? null, # Logic now relies solely on this
            excludeCoreModules ? [],
            users ? [ "doromiert" ],
            roles ? [],
            serverServices ? []
        }: 
            nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = { 
                    inherit inputs self hostName;
                    pkgs-unstable = import nixpkgs-unstable {
                        inherit system;
                        config.allowUnfree = true;
                    };
                };
                modules = [
                    # 1. Base Logic & Overlays
                    ({ config, pkgs, ... }: { 
                        # Define the mainUser option and set it
                        options.mainUser = lib.mkOption {
                            type = lib.types.str;
                            default = mainUser;
                            description = "The primary user of the system.";
                        };
                        config.mainUser = mainUser;

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

                    # 2. External Modules
                    inputs.home-manager.nixosModules.home-manager
                    inputs.stylix.nixosModules.stylix

                    # 3. Universal ZenOS Foundation (Dynamic Import)
                    # Automatically imports all modules in src/modules/core unless excluded
                    ] ++ (importDir ./src/modules/core excludeCoreModules) ++ [

                    # 4. Desktop Environment (Programmatic Selection)
                    # Imports src/modules/desktop/${desktop}/main.nix if 'desktop' is set
                    ] ++ (if desktop != null then [
                        ./src/modules/desktop/${desktop}/main.nix
                        ./src/modules/desktop/styling.nix
                    ] else []) ++ [

                    # 5. Automatic Host Directory Import (Excluding resources)
                    ] ++ (importDir (./src/hosts + "/${hostName}") []) ++ [

                    # 6. Automatic User Import based on array
                    ] ++ (map (user: ./src/users + "/${user}/main.nix") users) ++ [
                    
                    # 7. Conditional Graphical User Modules
                    # If a desktop is selected, we assume users need their graphical configs
                    ] ++ (if desktop != null then (map (user: ./src/users + "/${user}/graphical.nix") users) else []) ++ [

                    # 8. Automatic Role Import
                    ] ++ (map (role: ./src/modules/roles/${role}.nix) roles) ++ [

                    # 9. Automatic Server Service Import
                    ] ++ (map (service: ./src/server/${service}.nix) serverServices) ++ [

                ] ++ extraModules;
            };
    in {
        nixosConfigurations = {
            doromitul2 = mkHost {
                hostName = "doromitul2";
                mainUser = "doromiert";
                users = [ "doromiert", "hubi" ];
                desktop = "gnome";
                roles = [ "creative" "gaming" "dev" "virtualization" "containers" "web" ];
                extraModules = [
                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                    inputs.nixos-hardware.nixosModules.common-pc-ssd
                    inputs.nix-gaming.nixosModules.platformOptimizations
                ];
            };

            vm-desktop = mkHost {
                hostName = "vm-desktop-test";
                mainUser = "doromiert";
                desktop = "gnome";
                excludeCoreModules = [ "syncthing" ];
                roles = [ "creative" "gaming" "dev" "virtualization" "containers" "web" ];
                extraModules = [
                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                ];
            };

            doromipad = mkHost {
                hostName = "doromipad";
                mainUser = "doromiert";
                users = [ "doromiert", "hubi" ];
                desktop = "gnome";
                roles = [ "creative" "tablet" "dev" "virtualization" "containers" "web" ];
                extraModules = [
                    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l13-yoga
                    inputs.nixos-hardware.nixosModules.common-cpu-intel
                    inputs.nixos-hardware.nixosModules.common-pc-ssd
                ];
            };

            doromi-server = mkHost {
                hostName = "doromi-server";
                mainUser = "doromiert";
                # desktop omitted (defaults to null), so graphical modules are skipped
                users = [ 
                    "aether" "blade0" "cnb" "doromiert" "ecodz" 
                    "hubi" "jeyphr" "lenni" "meowster" "saphhie" 
                    "saxum" "shareduser" "xen" 
                ];
                roles = [ "containers" ];
                serverServices = [
                    "cloudflare" "copyparty" "forgejo" 
                    "immich" "jellyfin" "minecraft"
                ];
                extraModules = [
                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                ];
            };
        };
    };
}