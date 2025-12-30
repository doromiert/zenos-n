{ config, pkgs, ... }:

{
    # -------------------------------------------------------------------------
    # Libvirt & QEMU Configuration
    # -------------------------------------------------------------------------
    virtualisation.libvirtd = {
        enable = true;
        qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = true;
            # High-performance settings for Ryzen 9 7900
            ovmf = {
                enable = true;
                packages = [ pkgs.OVMFFull.fd ];
            };
            swtpm.enable = true; # TPM emulation for Windows 11
        };
    };

    programs.virt-manager.enable = true;

    # -------------------------------------------------------------------------
    # Guest Interaction
    # -------------------------------------------------------------------------
    services.spice-vdagentd.enable = true;

    # -------------------------------------------------------------------------
    # Permissions & Packages
    # -------------------------------------------------------------------------
    users.users.${config.mainUser}.extraGroups = [ "libvirtd" "kvm" ];

    environment.systemPackages = with pkgs; [
        bridge-utils
        dnsmasq
        vde2
        spice-vdagent
    ];
}