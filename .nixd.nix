# .nixd.nix
# Place this file in the ROOT of your ZenOS directory (next to flake.nix)
# It tells the LSP exactly how to read your Flake.

{
  # 1. Evaluation Settings
  eval = {
    # This targets your flake inputs specifically.
    # It allows "Go to Definition" on pkgs.* and lib.*
    target = {
      args = [
        "--expr"
        "with import (builtins.getFlake (toString ./.)) { }; pkgs"
      ];
      installable = "";
    };
    depth = 10;
  };

  # 2. Formatting
  formatting = {
    command = [ "nixfmt" ];
  };

  # 3. Option Completion (NixOS + Home Manager)
  # This maps the "options" keyword to your actual system configuration.
  options = {
    # Autocomplete for: networking.*, services.*, etc.
    nixos = {
      expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.doromi-tul-2.options";
    };

    # Autocomplete for: home-manager.users.doromiert.*
    # We access HM options via the NixOS module to ensure they are synced.
    home-manager = {
      expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.doromi-tul-2.options.home-manager.users.type.getSubOptions []";
    };
  };
}
