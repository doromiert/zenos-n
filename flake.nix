{
  # o
  # alr so flakes work like this: you have inputs (think of it as nix-channel but declarative) and outputs (which will be your ready configs)
  description = "ZenOS N (NixOS-based ZenOS)";

  inputs = {
    # for example here's my system packages link GODDAMMIT VIM
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
    # tf is jovian
    # nigga don't put if you didn't test it
    jovian = {

      url = "github:Jovian-Experiments/Jovian-NixOS";
    };

    vsc-extensions.url = "github:nix-community/nix-vscode-extensions";
    swisstag.url = "github:doromiert/swisstag";
    # btw declarative discord, how cool
    nixcord.url = "github:kaylorben/nixcord";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      # anyways this is the outputs section
      # here i basically have a definition all configs will inherit
      # and the stuff in this {} section is the arguments
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-flatpak,
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
      # ↑ clanker magic i dont understand
      # but it does what i want so im not gonna touch it

      mkHost =
        {
          # host settings (used a bit lower, this is specifically for my flake)
          # because i wanted to make my life easier lol
          # ill use it in my vm
          # ill make a 1.0 release once it's ready
          # follow me agin
          # ill show you how ill do that in a sec
          # just follow me
          # o btw when lite edition
          # (and whoever decides to use this flake in the future)
          # :3
          hostName,
          mainUser ? "doromiert",
          extraModules ? [ ],
          desktop ? null,
          excludeCoreModules ? [ ],
          users ? [ "doromiert" ],
          roles ? [ ],
          serverServices ? [ ],
        # because of this part
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
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.nur.modules.nixos.default
            # oh and here are external modules all hosts will inherit
            # defined in the inputs

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
      # plus fucker
      # clanker-made config maker helper lol
    in
    {
      # --- FLAKE OUTPUTS ---

      metadata = {
        name = "ZenOS N";
        version = "1.0";
        codename = "Cacao";
        maintainer = "doromiert";
      };
      # ↑ this does fuck all

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
        # nonono you clearly havent experienced flake-flavored devving
        # you can use flakes to define a shell for one dir in particular instead of having to make a thousand dotfiles lmfao
        # anyways let's move on i want to show you smth really cool
        # nigga i don't have long beards enough to understand thi
        # ↑ i decided to stop using this because it was spamming my cli lol
        # yes
        # runs a hook every time i input a command basically
      };

      # now the meaty part ↓
      # the hosts

      nixosConfigurations = {
        doromi-tul-2 = mkHost {
          hostName = "doromi-tul-2";
          mainUser = "doromiert";
          users = [
            "doromiert" # (this will import) src/users/doromiert/main.nix (and graphical.nix when a desktop is enabled btw)
            "hubi"
            # now how does this work?
            # you define an mkHost, the users you want to use
          ]; # now this, this is how you define hosts in my flakes
          desktop = "gnome"; # this is a bit different from how it works by default because of
          excludeCoreModules = [ "syncthing" ];
          roles = [
            # thats cool
            "creative" # this will import src/modules/roles/(strings in here).nix
            "gaming"
            "web"
            "dev"
            "virtualization"
            "containers"
            "pipewire"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-amd
            inputs.nixos-hardware.nixosModules.common-gpu-amd
            inputs.nixos-hardware.nixosModules.common-pc-ssd
            inputs.nix-gaming.nixosModules.platformOptimizations
            inputs.jovian.nixosModules.default
          ];
        };

        # and the best part is you can have multiple configs in one flake
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

        kitty-laptop = mkHost {
          hostName = "kitty-laptop"; # this has to match what's before "= mkHost" fyi
          mainUser = "cat";
          users = [
            # now how would we define a config for you? simple
            "cat"
          ];
          desktop = "hyprland"; # i think it'd be a better idea to name yourf1 specific hyprland config smth else tbh
          roles = [
            # "kittyland", lol
            "creative"
            "tablet"
            "dev"
            "virtualization"
            "containers"
            "web"
          ];
          extraModules = [
            inputs.nixos-hardware.nixosModules.common-cpu-intel
            inputs.nixos-hardware.nixosModules.common-pc-laptop
            inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
          ];
        };
      };
    };
}
