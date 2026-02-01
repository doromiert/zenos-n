{
  description = "ZenOS N (NixOS-based ZenOS)";

  inputs = {
    # The Single Point of Truth
    zenpkgs.url = "github:zenos-n/zenpkgs";
  };

  outputs =
    { self, zenpkgs, ... }:
    let
      # [CRITICAL] Rehydrate the inputs set from zenpkgs
      # This makes inputs.nixpkgs, inputs.home-manager, etc. available to modules
      inputs = zenpkgs.inputs // {
        inherit zenpkgs self;
      };

      # Extract core libraries
      nixpkgs = inputs.nixpkgs;
      lib = nixpkgs.lib;

      # Utils from ZenPkgs
      utils = zenpkgs.lib.mkUtils { inherit lib inputs self; };
      zenOverlay = zenpkgs.overlays.default;

      version = {
        type = "beta";
        majorVer = "1.0";
        variant = "N";
        full = utils.osVersionString;
      };

      mkHost =
        hostName:
        lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              self
              utils
              version
              ;
          };
          modules = [
            (./hosts + "/${hostName}/main.nix")
            ./modules/structure.nix

            { nixpkgs.overlays = [ zenOverlay ]; }

            # Import modules directly from zenpkgs if needed
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
