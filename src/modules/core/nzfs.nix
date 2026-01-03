{ config, lib, pkgs, ... }:

let
  cfg = config.services.nz-filesystem;

  # [ LOGIC ] Helper to bind directories (Still uses Bind Mounts)
  bindDir = category: source: {
    name = "/Config/${category}";
    value = { device = "/etc/${source}"; options = [ "bind" ]; };
  };

  # [ LOGIC ] Helper to create symlinks for files (Replaces bindFiles)
  # Syntax: L+ /Config/Category/File - - - - /etc/File
  linkFiles = category: files:
    map (file: "L+ /Config/${category}/${file} - - - - /etc/${file}") files;

  # [ DATA ] File Lists
  networkFiles = [ 
    "hosts" "resolv.conf" "resolvconf.conf" "hostname" "ethertypes" 
    "host.conf" "ipsec.secrets" "netgroup" "protocols" "rpc" "services" 
  ];
  
  securityFiles = [ "sudoers" ];
  
  systemFiles = [ 
    "fstab" "os-release" "profile" "locale.conf" "vconsole.conf" "machine-id" 
    "localtime" "inputrc" "issue" "kbd" "login.defs" "lsb-release" "man_db.conf" 
    "nanorc" "nscd.conf" "nsswitch.conf" "terminfo" "zoneinfo" 
  ];
  
  userFiles = [ 
    "passwd" "group" "shadow" "shells" "subgid" "subuid" 
    "bashrc" "bash_logout" "zshrc" "zshenv" "zprofile" "zinputrc" 
  ];

in
{
  options.services.nz-filesystem = {
    enable = lib.mkEnableOption "Negative Zero Custom Filesystem Hierarchy";

    mainDrive = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the main system drive.";
    };

    bootDrive = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the boot partition.";
    };

    fsType = lib.mkOption {
      type = lib.types.str;
      default = "btrfs";
      description = "Filesystem type for the main drive (e.g., btrfs, ext4).";
    };

    swapSize = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Size of the swapfile in MB.";
    };
  };

  config = lib.mkIf cfg.enable {
    documentation.enable = false;
    documentation.nixos.enable = false;
    documentation.man.enable = false;
    
    # [ ACTION ] Create the NZFS Directory Structure
    
    # --- BIND MOUNTS (The NZFS Layer) ---
    
    # [ 1. Config Arrays ]
    fileSystems = 
      # 1.1 Directories (Bulk Binds)
      builtins.listToAttrs [
        # Audio
        (bindDir "Audio/Pipewire" "pipewire")
        (bindDir "Audio/Alsa" "alsa")
        
        # Bluetooth
        (bindDir "Bluetooth" "bluetooth")
        
        # Desktop
        (bindDir "Desktop/XDG" "xdg")
        (bindDir "Desktop/GDM" "gdm")
        (bindDir "Desktop/Plymouth" "plymouth")
        (bindDir "Desktop/Remote" "gnome-remote-desktop")
        (bindDir "Desktop/DConf" "dconf")
        
        # Display
        (bindDir "Display/X11" "X11")
        
        # Fonts
        (bindDir "Fonts" "fonts")
        
        # Hardware
        (bindDir "Hardware/Udev" "udev")
        (bindDir "Hardware/LVM" "lvm")
        (bindDir "Hardware/Modprobe" "modprobe.d")
        (bindDir "Hardware/Modules" "modules-load.d")
        (bindDir "Hardware/BlockDev" "libblockdev")
        (bindDir "Hardware/UDisks" "udisks2")
        (bindDir "Hardware/UPower" "UPower")
        (bindDir "Hardware/Qemu" "qemu")
        
        # Network
        (bindDir "Network/Manager" "NetworkManager")
        
        # Nix/Zero
        (bindDir "Nix" "nix")
        (bindDir "Zero/NixOS" "nixos")
        (bindDir "Zero/Scripts" "zenos")
        
        # Services
        (bindDir "Services/Systemd" "systemd")
        (bindDir "Services/DBus" "dbus-1")
        (bindDir "Services/Avahi" "avahi")
        (bindDir "Services/Geoclue" "geoclue")
        
        # Security
        (bindDir "Security/PAM" "pam.d")
        (bindDir "Security/SSH" "ssh")
        (bindDir "Security/SSL" "ssl")
        (bindDir "Security/Polkit" "polkit-1")
        
        # Misc (The Safety Valve)
        (bindDir "Misc" "") 
      ]
      
      # 1.2 Static System Binds (Including Physical Drives)
      // {
        # [ Physical Drives ]
        "/" = {
          device = "/dev/disk/by-uuid/${cfg.mainDrive}";
          fsType = cfg.fsType;
          neededForBoot = true; # <--- PREVENTS STAGE 1 PANIC
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/${cfg.bootDrive}";
          fsType = "vfat";
          neededForBoot = true; # <--- PREVENTS STAGE 1 PANIC
        };

        # [ CRITICAL ] The Core NZFS Bind
        # This maps the physical storage /System/nix to the system requirement /nix
        "/System/nix" = {
          device = "/nix";
          fsType = "none";
          options = [ "bind" ];
          neededForBoot = true; # <--- PREVENTS STAGE 1 PANIC
        };

        # [ NZFS Binds ]
        "/System/Boot"      = { device = "/boot"; options = [ "bind" ]; };
        "/System/Store"     = { device = "/nix/store"; options = [ "bind" ]; };
        "/System/Current"   = { device = "/run/current-system"; options = [ "bind" ]; };
        "/System/Booted"    = { device = "/run/booted-system"; options = [ "bind" ]; };
        "/System/Binaries"  = { device = "/run/current-system/sw/bin"; options = [ "bind" ]; };
        "/System/Modules"   = { device = "/run/current-system/kernel-modules"; options = [ "bind" ]; };
        "/System/Firmware"  = { device = "/run/current-system/firmware"; options = [ "bind" ]; };
        "/System/Graphics"  = { device = "/run/opengl-driver"; options = [ "bind" ]; };
        "/System/Wrappers"  = { device = "/run/wrappers"; options = [ "bind" ]; };
        
        "/System/State"     = { device = "/var/lib"; options = [ "bind" ]; };
        "/System/History"   = { device = "/nix/var/nix/profiles"; options = [ "bind" ]; };
        "/System/Logs"      = { device = "/var/log"; options = [ "bind" ]; };

        "/Live/dev"    = { device = "/dev"; options = [ "bind" ]; };
        "/Live/proc"   = { device = "/proc"; options = [ "bind" ]; };
        "/Live/sys"    = { device = "/sys"; options = [ "bind" ]; };
        "/Live/run"    = { device = "/run"; options = [ "bind" ]; };
        "/Live/Temp"   = { device = "/tmp"; options = [ "bind" ]; };
        "/Live/Memory" = { device = "/dev/shm"; options = [ "bind" ]; };

        "/Live/Services" = { device = "/run/systemd"; options = [ "bind" ]; };
        "/Live/Network"  = { device = "/run/NetworkManager"; options = [ "bind" ]; };
        "/Live/Sessions" = { device = "/run/user"; options = [ "bind" ]; };

        "/Live/Input"  = { device = "/dev/input"; options = [ "bind" ]; };
        "/Live/Video"  = { device = "/dev/dri"; options = [ "bind" ]; };
        "/Live/Sound"  = { device = "/dev/snd"; options = [ "bind" ]; };

        "/Live/Drives/ID"         = { device = "/dev/disk/by-id"; options = [ "bind" ]; };
        "/Live/Drives/Label"      = { device = "/dev/disk/by-label"; options = [ "bind" ]; };
        "/Live/Drives/Partitions" = { device = "/dev/disk/by-partlabel"; options = [ "bind" ]; };
        "/Live/Drives/Physical"   = { device = "/dev/disk/by-path"; options = [ "bind" ]; };

        # [ FIX ] Updated Mount Names
        "/Mount/Drives"    = { device = "/mnt"; options = [ "bind" ]; };
        "/Mount/Removable" = { device = "/run/media"; options = [ "bind" ]; };
      };

    # [ ACTION ] Swap Configuration
    swapDevices = [ {
      device = "/Live/swapfile";
      size = cfg.swapSize;
    } ];

    # [ ACTION ] Activation Script for Dynamic User BIND MOUNTS
    system.activationScripts.nzfsUsers = {
      text = ''
        echo "NZFS: Binding users to /Users..."
        mkdir -p /Users
        
        # Function to safe-bind a directory
        bind_user() {
            local src=$1
            local dest=$2
            
            # Ensure destination exists
            if [ ! -d "$dest" ]; then
                mkdir -p "$dest"
            fi
            
            # Check if already mounted to avoid stacking
            if ! mountpoint -q "$dest"; then
                mount --bind "$src" "$dest"
            fi
        }

        # 1. Bind standard users
        for user_dir in /home/*; do
          if [ -d "$user_dir" ]; then
            user_name=$(basename "$user_dir")
            bind_user "$user_dir" "/Users/$user_name"
          fi
        done
        
        # 2. Bind Admin (Root)
        bind_user "/root" "/Users/Admin"
      '';
      deps = [];
    };

    # [ ACTION ] Drive Linker Daemon
    # Dynamically links /dev/sd* and /dev/nvme* to /Live/Drives/Nodes
    systemd.services.nzfs-drive-daemon = {
      description = "NZFS Dynamic Drive Linker";
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ util-linux coreutils systemd findutils gnugrep ];
      script = ''
        TARGET_DIR="/Live/Drives/Nodes"
        mkdir -p "$TARGET_DIR"

        # Logic to sync current /dev state to /Live/Drives/Nodes
        sync_drives() {
            # Clean broken/stale links
            find "$TARGET_DIR" -type l -delete
            
            # Link SATA/SCSI Drives
            for dev in /dev/sd*; do
                [ -e "$dev" ] || continue
                ln -sf "$dev" "$TARGET_DIR/$(basename "$dev")"
            done
            
            # Link NVMe Drives
            for dev in /dev/nvme*; do
                [ -e "$dev" ] || continue
                ln -sf "$dev" "$TARGET_DIR/$(basename "$dev")"
            done
        }

        # Initial Sync
        sync_drives
        
        # Monitor Loop (Blocking)
        # Listens for udev block device events and resyncs
        udevadm monitor --subsystem-match=block --udev | while read -r line; do
            if echo "$line" | grep -qE "add|remove|change"; then
                # Tiny sleep to ensure /dev is populated by udev before we link
                sleep 0.2
                sync_drives
            fi
        done
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # [ ACTION ] Create the NZFS Directory Structure
    systemd.tmpfiles.rules = [
      # 0. HIDING FHS
      "f+ /.hidden 0644 root root - bin\\nboot\\ndev\\netc\\nhome\\nlib\\nlib64\\nmnt\\nnix\\nopt\\nproc\\nroot\\nrun\\nsrv\\nsys\\ntmp\\nusr\\nvar"

      # 1. SYSTEM BASE (Physical Store Location)
      "d /System 0755 root root -"
      "d /System/nix 0755 root root -"

      # 2. CONFIG - Base Dirs
      "d /Config 0755 root root -"
      "d /Config/Misc 0755 root root -" 
      "d /Config/Audio 0755 root root -"
      "d /Config/Audio/Pipewire 0755 root root -"
      "d /Config/Audio/Alsa 0755 root root -"
      "d /Config/Bluetooth 0755 root root -"
      "d /Config/Desktop 0755 root root -"
      "d /Config/Desktop/XDG 0755 root root -"
      "d /Config/Desktop/GDM 0755 root root -"
      "d /Config/Desktop/Plymouth 0755 root root -"
      "d /Config/Desktop/Remote 0755 root root -"
      "d /Config/Desktop/DConf 0755 root root -"
      "d /Config/Display 0755 root root -"
      "d /Config/Display/X11 0755 root root -"
      "d /Config/Fonts 0755 root root -"
      "d /Config/Hardware 0755 root root -"
      "d /Config/Hardware/Udev 0755 root root -"
      "d /Config/Hardware/LVM 0755 root root -"
      "d /Config/Hardware/Modprobe 0755 root root -"
      "d /Config/Hardware/Modules 0755 root root -"
      "d /Config/Hardware/BlockDev 0755 root root -"
      "d /Config/Hardware/UDisks 0755 root root -"
      "d /Config/Hardware/UPower 0755 root root -"
      "d /Config/Hardware/Qemu 0755 root root -"
      "d /Config/Network 0755 root root -"
      "d /Config/Network/Manager 0755 root root -"
      "d /Config/Nix 0755 root root -"
      "d /Config/Zero 0755 root root -"
      "d /Config/Zero/NixOS 0755 root root -"
      "d /Config/Zero/Scripts 0755 root root -"
      "d /Config/Services 0755 root root -"
      "d /Config/Services/Systemd 0755 root root -"
      "d /Config/Services/DBus 0755 root root -"
      "d /Config/Services/Avahi 0755 root root -"
      "d /Config/Services/Geoclue 0755 root root -"
      "d /Config/Security 0755 root root -"
      "d /Config/Security/PAM 0755 root root -"
      "d /Config/Security/SSH 0755 root root -"
      "d /Config/Security/SSL 0755 root root -"
      "d /Config/Security/Polkit 0755 root root -"
      "d /Config/System 0755 root root -"
      "d /Config/User 0755 root root -"
    ]
    
    # 2.1 CONFIG - Files (Generated Symlinks)
    ++ (linkFiles "Network" networkFiles)
    ++ (linkFiles "Security" securityFiles)
    ++ (linkFiles "System" systemFiles)
    ++ (linkFiles "User" userFiles)
    
    ++ [
      # 3. MOUNT
      "d /Mount 0755 root root -"
      "L+ /Mount/Drives - - - - /mnt"
      "L+ /Mount/Removable - - - - /run/media"

      # 4. APPS
      "d /Apps 0755 root root -"
      "L+ /Apps/System - - - - /run/current-system/sw/bin"
      
      # 5. LIVE
      "d /Live 0755 root root -"
      "d /Live/Temp 1777 root root -"
      "d /Live/Memory 1777 root root -"
      "d /Live/Services 0755 root root -"
      "d /Live/Network 0755 root root -"
      "d /Live/Sessions 0755 root root -"
      "d /Live/Input 0755 root root -"
      "d /Live/Video 0755 root root -"
      "d /Live/Sound 0755 root root -"
      
      "d /Live/Drives 0755 root root -"
      "d /Live/Drives/Nodes 0755 root root -" # New directory for the daemon
      "d /Live/Drives/ID 0755 root root -"
      "d /Live/Drives/Label 0755 root root -"
      "d /Live/Drives/Partitions 0755 root root -"
      "d /Live/Drives/Physical 0755 root root -"

      # 6. USERS
      "d /Users 0755 root root -"
    ];

    environment.variables = {
      NZFS_ROOT = "/System"; 
      NZFS_CONFIG = "/Config";
      NZFS_SYSTEM = "/System";
    };
  };
}