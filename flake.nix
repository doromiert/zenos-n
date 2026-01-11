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
    illogical-impulse.url = "github:soymou/illogical-flake";

    swisstag.url = "github:doromiert/swisstag";
    zbridge = {
      url = "github:doromiert/zerobridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # [ ZenFS ] Local Input
    zenfs = {
      url = "github:doromiert/zenfs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # [ ZenOS Maintenance ]
    zenos-maintenance = {
      url = "github:doromiert/zenos-maintenance";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpwamaker = {
      url = "github:doromiert/nixpwamaker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # helper to import all .nix files in a directory
      importDir =
        path: excludes:
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

      # ==============================================================================
      # [ HOST BUILDER ]
      # Supports Pretty Names and Automatic Folder Inference
      # ==============================================================================
      mkHost =
        {
          prettyName, # Input: "Doromi Tul 2" or "Doromi Tul II"
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
          serverServices ? [ ],
        }:
        let
          # [LOGIC] Convert "Doromi Tul 2" -> "doromi-tul-2"
          # 1. Lowercase
          # 2. Replace spaces with hyphens
          hostName = lib.strings.toLower (builtins.replaceStrings [ " " ] [ "-" ] prettyName);
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              self
              hostName # Used for networking.hostName
              prettyName # Used via 'devicePrettyName' in branding.nix
              mainUser
              rootUUID
              bootUUID
              locale
              ;
            # Alias prettyName to devicePrettyName for module compatibility
            devicePrettyName = prettyName;

            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = [
            (
              {
                lib,
                inputs,
                ...
              }:
              {
                options.mainUser = lib.mkOption {
                  type = lib.types.str;
                  description = "The primary human operator of this silicon.";
                };

                config = {
                  # [ HARDWARE ] Universal Firmware Enable
                  # Enforces redistributable firmware (linux-firmware) for all hosts.
                  hardware.enableRedistributableFirmware = true;

                  # [ ZenFS ] Core Configuration
                  services.zenfs = {
                    enable = true;
                    roaming.enable = true;
                    janitor = {
                      offloader = {
                        enable = true;
                        threshold = 80;
                      };
                    };
                    mainDrive = rootUUID;
                    bootDrive = bootUUID;
                  };

                  # [ ZenOS Maintenance ] Default Enable
                  # This ensures all hosts (laptop, PC, VM) get auto-updates & cleanup.
                  zenos.maintenance = {
                    enable = true;
                    flakePath = "/home/doromiert/Projects/zenos-n";
                  };

                  # [LOGIC] Set the system hostname automatically
                  networking.hostName = hostName;

                  nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                  nixpkgs.config.allowUnfree = true;

                  mainUser = lib.mkDefault mainUser;

                  nixpkgs.overlays = [
                    (final: prev: {
                      unstable = import nixpkgs-unstable {
                        inherit system;
                        config.allowUnfree = true;
                      };
                    })
                  ];

                  system.stateVersion = "25.11";
                  home-manager.useGlobalPkgs = true;
                  home-manager.backupFileExtension = "backup";

                  home-manager.extraSpecialArgs = { inherit inputs; };
                  home-manager.sharedModules = [
                    inputs.nixpwamaker.homeManagerModules.pwamaker
                    inputs.zbridge.homeManagerModules.default
                  ];
                };
              }
            )

            # [ ZenFS ] Module Import
            inputs.zenfs.nixosModules.default

            # [ ZenOS Maintenance ] Module Import
            inputs.zenos-maintenance.nixosModules.default

            inputs.home-manager.nixosModules.home-manager
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.nur.modules.nixos.default

          ]
          ++ (importDir ./src/modules/core excludeCoreModules)
          ++ (
            if desktop != null then
              [
                ./src/modules/desktop/${desktop}/main.nix
                ./src/modules/desktop/${desktop}/styling.nix
              ]
            else
              [ ]
          )
          # [UPDATED] Import logic uses the sanitized hostName (e.g. src/hosts/doromi-tul-2)
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
          prettyName = "doromi tul 2";

          rootUUID = "8e1e39fe-becf-40f7-bf3e-447ecdfef32d";
          bootUUID = "E4BC-AD87";
          locale = {
            timeZone = "Europe/Warsaw";
            language = "en_US.UTF-8";
            defaultLocale = "pl_PL.UTF-8";
            kbLayout = "pl";
          };
          users = [
            "doromiert"
            "hubi"
          ];
          desktop = "gnome";
          roles = [
            "web"
            "gaming"
            "creative/audio"
            "creative/graphics"
            "creative/video"
            "creative/misc"
            "dev"
            "pipewire"
            "zbridge"
          ];
          # ill change this once i install it for more than testing
          excludeCoreModules = [
            "syncthing"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-amd
            inputs.nixos-hardware.nixosModules.common-gpu-amd
            inputs.nixos-hardware.nixosModules.common-pc-ssd
            inputs.nix-gaming.nixosModules.platformOptimizations
            inputs.jovian.nixosModules.default
          ];
        };

        doromipad = mkHost {
          prettyName = "doromipad";

          rootUUID = "8e1e39fe-becf-40f7-bf3e-447ecdfef32d";
          bootUUID = "E4BC-AD87";
          locale = {
            timeZone = "Europe/Warsaw";
            language = "en_US.UTF-8";
            defaultLocale = "pl_PL.UTF-8";
            kbLayout = "pl";
          };
          users = [
            "doromiert"
            "hubi"
          ];
          desktop = "gnome";
          roles = [
            "web"
            "creative/audio"
            "creative/graphics"
            "creative/misc"
            "dev"
            "pipewire"
            "zbridge"
            "tablet"
          ];
          # ill change this once i install it for more than testing
          # excludeCoreModules = [
          #   "syncthing"
          # ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l13
            inputs.nixos-hardware.nixosModules.common-cpu-intel
            inputs.nixos-hardware.nixosModules.common-gpu-intel
            inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
          ];
        };

        test-vm = mkHost {
          prettyName = "Bob's test VM";

          rootUUID = "8e1e39fe-becf-40f7-bf3e-447ecdfef32d";
          bootUUID = "E4BC-AD87";
          locale = {
            timeZone = "Europe/Dublin";
            language = "en_US.UTF-8";
            defaultLocale = "en_GB.UTF-8";
            kbLayout = "gb";
          };
          users = [
            "blade0"
          ];
          desktop = "gnome";
          roles = [
            "web"
            "dev"
            "pipewire"
            "zbridge"
          ];
          # ill change this once i install it for more than testing
          excludeCoreModules = [
            "syncthing"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-intel
            inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd

            # Virtualization Guest Support
            # This enables SPICE/QEMU agents or VMware/VirtualBox tools automatically
            (
              { modulesPath, ... }:
              {
                imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
                services.qemuGuest.enable = true;
                services.spice-vdagentd.enable = true; # Essential for GNOME copy/paste in VM
              }
            )
          ];
        };
      };
    };
}
