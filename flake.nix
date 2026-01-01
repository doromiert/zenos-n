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
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
    };

    vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
    swisstag.url = "github:doromiert/swisstag";
    nixcord.url = "github:kaylorben/nixcord";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixcord,
      nix-gaming,
      vsc-extensions,
      swisstag,
      home-manager,
      chaotic,
      nix-minecraft,
      jovian,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # [1] We define 'pkgs' here to use in the devShells output below
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Generic directory importer with exclude support
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

      mkHost =
        {
          hostName,
          mainUser ? "doromiert",
          extraModules ? [ ],
          desktop ? null,
          excludeCoreModules ? [ ],
          users ? [ "doromiert" ],
          roles ? [ ],
          serverServices ? [ ],
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
            (
              {
                pkgs,
                lib,
                ...
              }:
              {
                options.mainUser = lib.mkOption {
                  type = lib.types.str;
                  default = mainUser;
                  description = "The primary user of the system.";
                };

                config = {
                  nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                  environment.systemPackages = [
                    inputs.swisstag.packages.${pkgs.system}.default
                  ];
                  nixpkgs.config.allowUnfree = true;
                  mainUser = mainUser;
                  networking.hostName = hostName;
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
                  home-manager.useGlobalPkgs = true;
                  home-manager.backupFileExtension = "backup";
                };
              }
            )

            # 2. External Modules
            inputs.home-manager.nixosModules.home-manager

            # 3. Universal ZenOS Foundation (Dynamic Import)
          ]
          ++ (importDir ./src/modules/core excludeCoreModules)
          ++ [
            # 4. Desktop Environment
          ]
          ++ (
            if desktop != null then
              [
                ./src/modules/desktop/${desktop}/main.nix
                ./src/modules/desktop/${desktop}/styling.nix
              ]
            else
              [ ]
          )
          ++ [
            # 5. Host Directory
          ]
          ++ (importDir (./src/hosts + "/${hostName}") [ ])
          ++ [
            # 6. User Import
          ]
          ++ (map (user: ./src/users + "/${user}/main.nix") users)
          ++ [
            # 7. Graphical User Modules
          ]
          ++ (if desktop != null then (map (user: ./src/users + "/${user}/graphical.nix") users) else [ ])
          ++ [
            # 8. Role Import
          ]
          ++ (map (role: ./src/modules/roles/${role}.nix) roles)
          ++ [
            # 9. Server Service Import
          ]
          ++ (map (service: ./src/server/${service}.nix) serverServices)
          ++ [ ]
          ++ extraModules;
        };
    in
    {
      # --- FLAKE OUTPUTS ---

      metadata = {
        name = "ZenOS N";
        version = "1.0";
        codename = "Cacao";
        maintainer = "doromiert";
      };

      # [2] Development Environment (direnv)
      # This provides the tools needed to work ON this repo (scripts, lsp, etc)
      devShells.${system}.default = pkgs.mkShell {
        name = "zenos-dev";

        nativeBuildInputs = [
          # Tools for 'pwamaker.py' and web scripts
          pkgs.python3
          pkgs.firefoxpwa

          # Nix Development Tools (LSP + Formatter)
          pkgs.nil # Nix Language Server (Essential for VS Code)
          pkgs.nixfmt-rfc-style # Standard formatter

          # Useful Utilities
          pkgs.git
        ];

        shellHook = ''
          echo "Start SAM [ZenOS N DevShell]"
          echo "   > Python & FirefoxPWA loaded."
          echo "   > Nix LSP (nil) & Formatter loaded."
        '';
      };

      nixosConfigurations = {
        doromi-tul-2 = mkHost {
          hostName = "doromi-tul-2";
          mainUser = "doromiert";
          users = [
            "doromiert"
            "hubi"
          ];
          desktop = "gnome";
          excludeCoreModules = [ "syncthing" ];
          roles = [
            "creative"
            "gaming"
            "web"
            "dev"
            "virtualization"
            "containers"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-amd
            inputs.nixos-hardware.nixosModules.common-gpu-amd
            inputs.nixos-hardware.nixosModules.common-pc-ssd
            inputs.nix-gaming.nixosModules.platformOptimizations
            inputs.jovian.nixosModules.default
          ];
        };

        vm-desktop-test = mkHost {
          hostName = "vm-desktop-test";
          mainUser = "doromiert";
          desktop = "gnome";
          excludeCoreModules = [ "syncthing" ];
          roles = [
            "creative"
            "gaming"
            "dev"
            "virtualization"
            "containers"
            "web"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-amd
            inputs.nixos-hardware.nixosModules.common-gpu-amd
          ];
        };

        doromipad = mkHost {
          hostName = "doromipad";
          mainUser = "doromiert";
          users = [
            "doromiert"
            "hubi"
          ];
          desktop = "gnome";
          roles = [
            "creative"
            "tablet"
            "dev"
            "virtualization"
            "containers"
            "web"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l13-yoga
            inputs.nixos-hardware.nixosModules.common-cpu-intel
            inputs.nixos-hardware.nixosModules.common-pc-ssd
          ];
        };

        doromi-server = mkHost {
          hostName = "doromi-server";
          mainUser = "doromiert";
          users = [
            "aether"
            "blade0"
            "cnb"
            "doromiert"
            "ecodz"
            "hubi"
            "jeyphr"
            "lenni"
            "meowster"
            "saphhie"
            "saxum"
            "shareduser"
            "xen"
          ];
          roles = [ "containers" ];
          serverServices = [
            "cloudflare"
            "copyparty"
            "forgejo"
            "immich"
            "jellyfin"
            "minecraft"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-amd
            inputs.nixos-hardware.nixosModules.common-gpu-amd
          ];
        };
      };
    };
}
