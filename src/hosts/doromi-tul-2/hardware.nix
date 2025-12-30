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
    trustedUsers = [ "doromiert" ]; 
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
    ];

    # -- Filesystems --
    fileSystems."/" = { 
        device = "/dev/disk/by-uuid/892a748c-3cc0-4106-b03d-b7cb21a8eeea";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/D332-20EE";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
    };
    
    # -- Swap & Memory Management --
    
    # 1. Physical Swapfile (Safety Net)
    # Replaced partition-based swap with a flexible file-based approach.
    # Note: If your root is Btrfs, NixOS handles the No_COW attribute automatically.
    swapDevices = [ {
        device = "/var/lib/swapfile";
        size = 16 * 1024; # 16GB
        priority = 0;    # Only used if zram fills up
    } ];

    # 2. zram (Dynamic In-Memory Swap)
    # Uses ZSTD compression to effectively increase available RAM.
    zramSwap = {
        enable = true;
        memoryPercent = 50; 
        priority = 100;    # Higher priority than disk-based swap
        algorithm = "zstd";
    };

    # 3. Kernel Tuning for Swap/zram
    # High swappiness (180) tells the kernel to prefer zram over dropping cache.
    boot.kernel.sysctl = {
        "vm.swappiness" = 180;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "vm.page-cluster" = 0; # Optimized for zram (disables readahead on swap)
    };

    # -- Hardware Specifics --
    networking.useDHCP = lib.mkDefault true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # -- Memory Management (KSM) --
    # Merges identical memory pages. Excellent for shared VM memory.
    hardware.ksm.enable = true;

    # -- Graphics (Mesa/Vulkan) --
    hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
            rocmPackages.clr.icd 
            libva-vdpau-driver
            libvdpau-va-gl
        ];
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
        amdgpu_top
        btop
        nvme-cli
    ];

    # -- Multi-User Environment Variables --
    environment.variables = {
        "DRI_PRIME" = "0"; 
        "WLR_DRM_NO_ATOMIC" = "1";
    };
}