{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------------
  # Libvirt & QEMU Configuration
  # -------------------------------------------------------------------------
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
    };
  };

  boot.kernelModules = [
    "bridge"
    "tap"
  ];

  programs.virt-manager.enable = true;
  virtualisation.libvirtd.qemu.swtpm.enable = true;

  # -------------------------------------------------------------------------
  # Guest Interaction
  # -------------------------------------------------------------------------
  services.spice-vdagentd.enable = true;

  # -------------------------------------------------------------------------
  # Permissions & Packages
  # -------------------------------------------------------------------------
  users.users.${config.mainUser}.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  environment.systemPackages = with pkgs; [
    bridge-utils
    dnsmasq
    vde2
    spice-vdagent
  ];
}
