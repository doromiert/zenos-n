# will contain the -0 ZenOS N boot config
{ config, pkgs, ... }:

let
	# Path to your custom python script relative to this file
	refindScript = ../scripts/refind.py;
in
{
	boot.loader = {
		# 1. Standard systemd-boot for generation management
		systemd-boot = {
			enable = true;
			configurationLimit = 10; # Keep the menu small
		};
		
		# 2. Prevent NixOS from fighting rEFInd for the #1 Boot Order slot
		# This ensures rEFInd stays as the primary EFI boot entry.
		efi = {
			canTouchEfiVariables = false;
			efiSysMountPoint = "/boot"; # Adjust to "/boot/efi" if necessary
		};
	};

	# Activation Scripts: These run every time you 'nixos-rebuild switch'
	system.activationScripts = {
	
		# Unattended rEFInd Installation
		# Idempotent: Only runs if the refind binary isn't already in the ESP
		installRefind = {
			supportsDryRun = true;
			text = ''
				if [ ! -f /boot/EFI/refind/refind_x64.efi ]; then
					echo "rEFInd not found. Performing unattended installation..."
					# --yes assumes default answers to all prompts (unattended)
					${pkgs.refind}/bin/refind-install --yes
				fi
			'';
		};

		# The Python "Mesh" Sync
		# Runs after every rebuild to link NixOS generations to the rEFInd submenu
		syncRefindGenerations = {
			supportsDryRun = true;
			# Ensures the install script runs before the sync script
			deps = [ "installRefind" ]; 
			text = ''
				echo "Syncing NixOS generations with rEFInd via Python script..."
				${pkgs.python3}/bin/python3 ${refindScript}
			'';
		};
	};

	# Required packages for the scripts to function
	environment.systemPackages = with pkgs; [
		refind
		efibootmgr
		python3
	];
}