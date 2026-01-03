# doromi-tul-2: Hardware Synthesis & Kernel Optimization
# Optimized for: Ryzen 9 7900 (iGPU Host) + RX 6900 XT (VM Passthrough)
{
  config,
  lib,
  pkgs,
  modulesPath,
  rootUUID,   # Injected via flake.nix specialArgs
  bootUUID,   # Injected via flake.nix specialArgs
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # --- NZFS Synthesis Activation ---
  # Enabling NZFS v2: Volatile RAM root with persistent Silicon anchor.
  # Drive paths are now dynamically pulled from the Flake's physical discovery.

  # Forces NZFS logic to override the persistent defaults in flake.nix


  # --- Kernel & Silicon Optimization ---
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  # Ensure amdgpu is loaded early for the host iGPU
  boot.initrd.kernelModules = [
    "amdgpu"
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  boot.kernelModules = [ "kvm-amd" "msr" ];

  # GPU Passthrough & IOMMU Logic
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "preempt=full"
    "threadirqs"
    "amd_pstate=active"
  ];

  # --- Power & Thermal Management ---
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # --- Memory Synthesis (ZRAM) ---
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
    algorithm = "zstd";
  };

  # Sysctl optimizations for high-speed SSD and gaming
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.max_map_count" = 2147483642;
  };

  # --- Graphics & Display ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # --- Host-Specific User Groups ---
  users.users.${config.mainUser} = {
    extraGroups = [
      "libvirtd"
      "kvm"
      "render"
      "video"
      "input"
    ];
  };

  # --- Hardware Tooling ---
  environment.systemPackages = with pkgs; [
    virt-manager
    pciutils
    looking-glass-client
    amdgpu_top
    btop
    nvme-cli
  ];

  # --- Multi-Monitor & Wayland Logic ---
  environment.variables = {
    "WLR_DRM_NO_ATOMIC" = "1";
    "AMD_VULKAN_ICD" = "RADV";
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
