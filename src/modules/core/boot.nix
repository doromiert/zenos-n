# src/modules/core/boot.nix
{
  pkgs,
  lib,
  ...
}:

let
  # Path to your custom python script relative to this file
  refindScript = ../../scripts/refind.py;
  # Path to resources (Theme, icons, etc.)
  # Nix will copy this directory to the store, ensuring reproducibility.
  refindResources = ../../../resources/Refind;
in
{
  boot.loader = {
    # 1. Standard systemd-boot for generation management
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    # 2. Prevent NixOS from fighting rEFInd for the #1 Boot Order slot
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };
  };

  # Activation Scripts
  system.activationScripts = {

    # A. Unattended rEFInd Installation
    installRefind = {
      supportsDryActivation = true;
      text = ''
        export PATH="${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gptfdisk
            pkgs.gnused
            pkgs.gnugrep
          ]
        }:$PATH"

        # [ FIX ] Use /boot instead of /Boot to avoid race conditions with NZFS symlinks
        if [ ! -f /boot/EFI/refind/refind_x64.efi ]; then
            echo "rEFInd not found. Performing unattended installation..."
            ${pkgs.refind}/bin/refind-install --yes
        fi
      '';
    };

    # B. Copy Resources (Themes/Icons)
    # Copies local resources/Refind/* to the ESP, overwriting conflicts.
    copyRefindResources = {
      supportsDryActivation = true;
      deps = [ "installRefind" ];
      text = ''
        echo "Deploying rEFInd resources..."

        # Check if the store path exists (it always should if Nix builds successfully)
        if [ -d "${refindResources}" ]; then
            # -L: Dereference symlinks (copy actual file content)
            # -f: Force overwrite of existing files
            # -r: Recursive
            # --no-preserve=mode: Ensures files on target are writable (fixes Read-Only Store issues)
            cp -Lrf --no-preserve=mode ${refindResources}/. /boot/EFI/refind/
        else
            echo "## [ ! ] WARNING: Resource path ${refindResources} implies empty or missing source."
        fi
      '';
    };

    # C. The Python "Mesh" Sync
    syncRefindGenerations = {
      supportsDryActivation = true;
      # Runs after resources are copied to ensure config references exist
      deps = [ "copyRefindResources" ];
      text = ''
        echo "Syncing NixOS generations with rEFInd via Python script..."
        ${pkgs.python3}/bin/python3 ${refindScript}
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    refind
    efibootmgr
    python3
    gptfdisk
    gnused
  ];
}
