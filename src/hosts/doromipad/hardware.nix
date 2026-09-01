{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc" # Realtek SD card reader often found in L13
  ];
  boot.initrd.kernelModules = [ ];

  # Kernel modules for ThinkPad
  boot.kernelModules = [
    "kvm-intel"
    "i915"
    # "acpi_call" # Sometimes useful for TLP / ThinkPad specific calls
  ];

  boot.extraModulePackages = [ ];

  # [ Networking ]
  networking.useDHCP = lib.mkDefault true;

  # [ Power Management ]
  # This option is usually set by nixos-hardware, but explicitly setting it
  # here ensures CPU microcode updates are applied.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
