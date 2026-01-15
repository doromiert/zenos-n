# @file: lib/utils.nix
# @brief: Random utils.
# @context: utils

{ lib, inputs, ... }:

rec {
  # Recursively find all .nix files in a directory and return them as a list of paths
  recursiveImports =
    path:
    let
      # Helper to filter and map directory contents
      contents = builtins.readDir path;

      # Function to process each entry
      processEntry =
        name: type:
        let
          fullPath = path + "/${name}";
        in
        if type == "directory" then
          recursiveImports fullPath
        else if type == "regular" && lib.hasSuffix ".nix" name && name != "structure.nix" then
          [ fullPath ]
        else
          [ ];

      # Apply processEntry to all items in the directory
      entries = lib.mapAttrsToList processEntry contents;
    in
    lib.flatten entries;

  # Helper to check if a module is enabled via the new config syntax
  # Usage in module: enabled = isModuleEnabled config "gaming" "steam";
  isModuleEnabled =
    config: category: name:
    let
      categoryConfig = config.zenos.modules.${category} or [ ];
    in
    (categoryConfig == "*") || (lib.elem name categoryConfig);
}
