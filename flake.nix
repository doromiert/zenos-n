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
            pkgs = utils.mkUserPkgs inputs.nixpkgs.legacyPackages.x86_64-linux;
            inherit
              inputs
              self
              utils
              version
              ;
          };
          modules = [
            # 1. Structure
            inputs.zenpkgs.nixosModules.default

            # 2. Overlays
            { nixpkgs.overlays = [ zenOverlay ]; }

            # 3. [CRITICAL] SANDBOX LOADER
            # Instead of importing the file at the root (which allows global access),
            # we import the file and assign its result to 'zenos.config'.
            # This forces the user configuration into the strict sandbox.
            (
              { config, pkgs, ... }@args:
              {
                zenos.config = import (./hosts + "/${hostName}/main.nix") args;
              }
            )
          ]
          # 4. Optional: Recursive imports (Make sure these modules support the sandbox!)
          # If these modules try to set 'networking.hostName' directly, they will work
          # because they are root modules. Only the USER config (main.nix) is sandboxed above.
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
