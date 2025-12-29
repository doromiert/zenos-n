# doromi-tul-2-specific hardware, boot and kernel config
# Optimized for: Monitors on dGPU + iGPU Host + RX 6900 XT VM Passthrough
# Dynamic Resource Management: No static hugepages, KSM enabled for server VM
{ config, lib, pkgs, modulesPath, ... }:

let
    # PCI ID for RX 6900 XT (Navi 21)
    # Verification: `lspci -nn | grep -i navi`
    gpuIds = [
        "1002:73bf" # Graphics
        "1002:ab28" # Audio
    ];

    # List of users allowed to use Virtualization and the dGPU
    trustedUsers = [ "doromiert" "hubi" ]; 
in
{
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    # -- Kernel --
    boot.kernelPackages = pkgs.linuxPackages_zen;
    
    # -- Boot & Initrd --
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ "amdgpu" "vfio_pci" "vfio" "vfio_iommu_type1" ]; 

    boot.kernelModules = [ "kvm-amd" "msr" ]; 
    
    # -- Kernel Parameters --
    boot.kernelParams = [ 
        "amd_iommu=on"   
        "iommu=pt"       
        # Performance/Latency
        "preempt=full"
        "threadirqs"
        "amd_pstate=active"
        # REMOVED: static hugepages to keep RAM available for host/server
    ];

    # -- Filesystems --
    fileSystems."/" = { 
        device = "/dev/disk/by-uuid/REPLACE_WITH_ROOT_UUID";
        fsType = "ext4"; 
    };

    fileSystems."/boot" = { 
        device = "/dev/disk/by-uuid/REPLACE_WITH_BOOT_UUID";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
    };
    
    swapDevices = [ { device = "/dev/disk/by-uuid/REPLACE_WITH_SWAP_UUID"; } ];

    # -- Hardware Specifics --
    networking.useDHCP = lib.mkDefault true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # -- Memory Management (KSM) --
    # Kernel Samepage Merging: Identifies identical memory pages and merges them.
    # Very useful for running multiple VMs (Server + Gaming) simultaneously.
    hardware.ksm.enable = true;

    # -- Graphics (Mesa/Vulkan) --
    hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
            rocmPackages.clr.icd 
            vaapiVdpau
            libvdpau-va-gl
            amdvlk 
        ];
    };

    # -- Virtualization Support (Libvirt/QEMU) --
    virtualisation.libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
            package = pkgs.qemu_kvm;
            ovmf.enable = true;
            runAsRoot = true;
            verbatimConfig = ''
                user = "${builtins.head trustedUsers}"
                group = "libvirtd"
            '';
        };
    };

    # -- Multi-User Hardware Access --
    systemd.tmpfiles.rules = [
        "f /dev/shm/looking-glass 0660 ${builtins.head trustedUsers} libvirtd -"
    ];
    
    users.users = lib.genAttrs trustedUsers (name: {
        extraGroups = [ "libvirtd" "kvm" "render" "video" "input" ];
    });

    # -- Environment Tools --
    environment.systemPackages = with pkgs; [
        virt-manager
        pciutils    
        looking-glass-client 
        glxinfo
        amdgpu_top
        btop
    ];

    # -- Multi-User Environment Variables --
    environment.variables = {
        "DRI_PRIME" = "0"; 
        "WLR_DRM_NO_ATOMIC" = "1";
    };
}