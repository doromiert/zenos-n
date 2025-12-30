{ config, pkgs, ... }:{
    
    # -------------------------------------------------------------------------
    # Virtualization Configuration (libvirtd + virt-manager)
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
            swtpm.enable = true; # Required for Windows 11 / TPM emulation
        };
    };

    # Enable virt-manager GUI
    programs.virt-manager.enable = true;

    # -------------------------------------------------------------------------
    # Containerization (Docker)
    # -------------------------------------------------------------------------
    virtualisation.docker = {
        enable = true;
        # Use rootless mode if preferred for security, but standard is often 
        # better for server-heavy workflows like yours (Jellyfin, Immich).
        rootless = {
            enable = false;
            setSocketVariable = true;
        };
        # Daemon configuration for storage efficiency
        daemon.settings = {
            "storage-driver" = "overlay2";
        };
    };

    # -------------------------------------------------------------------------
    # User Permissions & Packages
    # -------------------------------------------------------------------------
    # Replace 'user' with your actual username in the main config
    # This adds the user to the required groups to manage VMs and Containers
    users.users.${config.mainUser}.extraGroups = [ 
        "libvirtd" 
        "docker" 
        "kvm" 
    ];

    environment.systemPackages = with pkgs; [
        # CLI Tools
        docker-compose
        bridge-utils
        dnsmasq
        vde2
        
        # Virtualization Helpers
        spice-vdagent # For better guest interaction
    ];

    # Enable Spice for clipboard sharing between Host/Guest
    services.spice-vdagentd.enable = true;
}