{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "sr_mod"
        "virtio_blk"
      ];
    };
    kernelModules = [ "kvm-intel" ];
  };
}
