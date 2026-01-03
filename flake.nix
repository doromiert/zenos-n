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
        swisstag.url = "github:doromiert/swisstag";
        nixcord.url = "github:kaylorben/nixcord";

        nix-minecraft.url = "github:Infinidoge/nix-minecraft";
        nix-flatpak.url = "github:gmodena/nix-flatpak";
        nur = {
            url = "github:nix-community/NUR";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs:
    let
        system = "x86_64-linux";
        lib = nixpkgs.lib;

        importDir = path: excludes:
            let
                content = builtins.readDir path;
                nixFiles = lib.filterAttrs (
                    name: type:
                    type == "regular"
                    && lib.hasSuffix ".nix" name
                    && name != "default.nix"
                    && !builtins.elem (lib.removeSuffix ".nix" name) excludes
                ) content;
            in
            map (name: path + "/${name}") (builtins.attrNames nixFiles);

        mkHost = { 
            hostName, 
            rootUUID ? "ROOT_UUID_PLACEHOLDER", 
            bootUUID ? "BOOT_UUID_PLACEHOLDER",
            locale ? {
                timeZone = "Europe/Warsaw";
                language = "en_US.UTF-8";
                defaultLocale = "pl_PL.UTF-8";
                kbLayout = "pl";
            },
            mainUser ? "doromiert", 
            extraModules ? [ ], 
            desktop ? null, 
            excludeCoreModules ? [ ],
            users ? [ "doromiert" ], 
            roles ? [ ], 
            serverServices ? [ ] 
        }:
        nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
                inherit inputs self hostName mainUser rootUUID bootUUID locale;
                pkgs-unstable = import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfree = true;
                };
            };
            modules = [
                ({ pkgs, lib, ... }: {
                    options.mainUser = lib.mkOption {
                        type = lib.types.str;
                        description = "The primary human operator of this silicon.";
                    };

                    config = {
                        # Correct NZFS Option Path
                        services.nz-filesystem = {
                            enable = true;
                            mainDrive = rootUUID;
                            bootDrive = bootUUID;
                        };

                        nix.settings.experimental-features = [ "nix-command" "flakes" ];
                        nixpkgs.config.allowUnfree = true;
                        
                        mainUser = lib.mkDefault mainUser; 
                        networking.hostName = hostName;

                        nixpkgs.overlays = [ (final: prev: {
                            unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
                        }) ];
                        
                        system.stateVersion = "25.11";
                        home-manager.useGlobalPkgs = true;
                        home-manager.backupFileExtension = "backup";
                    };
                })

                ./src/modules/core/nzfs.nix
                inputs.home-manager.nixosModules.home-manager
                inputs.nix-flatpak.nixosModules.nix-flatpak
                inputs.nur.modules.nixos.default
            ] 
            ++ (importDir ./src/modules/core excludeCoreModules)
            ++ (if desktop != null then [ ./src/modules/desktop/${desktop}/main.nix ./src/modules/desktop/${desktop}/styling.nix ] else [ ])
            ++ (importDir (./src/hosts + "/${hostName}") excludeCoreModules)
            ++ (map (user: ./src/users + "/${user}/main.nix") users)
            ++ (if desktop != null then (map (user: ./src/users + "/${user}/graphical.nix") users) else [ ])
            ++ (map (role: ./src/modules/roles/${role}.nix) roles)
            ++ (map (service: ./src/server/${service}.nix) serverServices)
            ++ extraModules;
        };
    in
    {
        nixosConfigurations = {
            doromi-tul-2 = mkHost {
                hostName = "doromi-tul-2";
                rootUUID = "cad10bb9-5f29-419b-8be2-4fbfe115a961";
                bootUUID = "7000-8C2C";
                locale = {
                    timeZone = "Europe/Warsaw";
                    language = "en_US.UTF-8";
                    defaultLocale = "pl_PL.UTF-8";
                    kbLayout = "pl";
                };
                users = [ "doromiert" "hubi" ];
                desktop = "gnome";
                roles = [ "web" "gaming" "creative" "virtualization" "dev" "containers" "pipewire" "zbridge" ];
                excludeCoreModules = [ "syncthing" ];
                extraModules = [
                    inputs.nixos-hardware.nixosModules.common-cpu-amd
                    inputs.nixos-hardware.nixosModules.common-gpu-amd
                    inputs.nixos-hardware.nixosModules.common-pc-ssd
                    inputs.nix-gaming.nixosModules.platformOptimizations
                    inputs.jovian.nixosModules.default
                ];
            };
        };
    };
}
