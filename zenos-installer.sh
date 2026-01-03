#!/usr/bin/env bash

# Negative Zero - ZeroInstaller [v5.22.0]
# Features: Flat NZFS 2.3 (System-Root) + UUID Guard
# Filesystem: Btrfs (Zstd + Commit=120)
# Optimization: Core-Relative Parallelism + Pre-Populated NZFS + .hidden
# UX: User Selection Menu + Notifications + Verification Protocol

set -e

# --- Colors ---
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# [ UX ] Logging with Notify-Send support
log() {
    local timestamp=$(date +'%H:%M:%S')
    echo -e "${BLUE}[$timestamp] $1${NC}"
    
    if command -v notify-send &> /dev/null; then
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
             notify-send -u normal -a "ZenOS Installer" "Phase Update" "$1" 2>/dev/null || true
        fi
    fi
}

echo -e "${BLUE}## [ -0 ] ZENOS ZEROINSTALLER v5.22.0 (System-Root Edition)${NC}"

# --- Phase 0.1: Live Environment Cleanup ---
echo -e "\n${YELLOW}## [ ? ] LIVE ENV PREP ##${NC}"
read -p "Run Live ISO Cleanup & Expand /tmp? [Y/n] " CLEAN_CHOICE
if [[ "$CLEAN_CHOICE" =~ ^[Yy]$ || -z "$CLEAN_CHOICE" ]]; then
    log "Garbage collecting Nix Store..."
    nix-collect-garbage -d 2>/dev/null || true
    log "Expanding /tmp..."
    sudo mount -o remount,size=12G /tmp 2>/dev/null || sudo mount -o remount,size=80% /tmp 2>/dev/null || true
    echo -e "${GREEN}-> Live Environment Optimized.${NC}"
fi

# --- Phase 0.2: Safety & Cleanup Logic ---
cleanup() {
    local exit_code=$?
    echo -e "\n${YELLOW}-> Signal caught or error detected. Cleaning up environment...${NC}"
    sudo umount /tmp/zerocache 2>/dev/null || true
    if swapon --show | grep -q "swapfile"; then sudo swapoff -a || true; fi
    if mountpoint -q /mnt; then
        sudo fuser -km /mnt 2>/dev/null || true
        sudo umount -R /mnt 2>/dev/null || sudo umount -l /mnt 2>/dev/null || true
    fi
    
    if [ $exit_code -ne 0 ]; then 
        echo -e "${RED}## [ ! ] SYNTHESIS HALTED (Code: $exit_code)${NC}"
        if command -v notify-send &> /dev/null; then
             notify-send -u critical -a "ZenOS Installer" "INSTALLATION FAILED" "Check terminal for errors." 2>/dev/null || true
        fi
    else 
        echo -e "${GREEN}## [ DONE ] Environment Clear.${NC}"
    fi
}

trap cleanup ERR SIGINT

# --- Phase 0.3: DNS Turbo (Latency Benchmark) ---
echo -e "\n${YELLOW}## [ ? ] DNS TURBO ##${NC}"

# Benchmark Function
measure_dns() {
    local ip=$1
    local name=$2
    local avg=$(ping -c 3 -W 1 $ip 2>/dev/null | grep 'min/avg/max' | awk -F'/' '{print $5}')
    if [ -n "$avg" ]; then
        echo -e "  > $name ($ip): ${GREEN}${avg}ms${NC}"
    else
        echo -e "  > $name ($ip): ${RED}Timeout${NC}"
    fi
}

echo "Benchmarking Resolvers..."
measure_dns 1.1.1.1 "Cloudflare"
measure_dns 8.8.8.8 "Google"

read -p "Overwrite /etc/resolv.conf with Cloudflare DNS (1.1.1.1)? [Y/n] " DNS_CHOICE
if [[ "$DNS_CHOICE" =~ ^[Yy]$ || -z "$DNS_CHOICE" ]]; then
    log "Injecting 1.1.1.1 into resolver..."
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null
fi

# --- Phase 1: Environment Setup ---
export NIXPKGS_ALLOW_UNFREE=1

mount_target() {
    local root_p=$1
    local boot_p=$2
    local resume=$3
    
    if mountpoint -q /mnt; then 
        sudo fuser -km /mnt 2>/dev/null || true
        sudo umount -R /mnt || true 
    fi

    log "Establishing Flat NZFS 2.3 Peer Hierarchy (Btrfs)..."
    mkdir -p /mnt
    
    # [ ACTION ] Mount Root with ZSTD + Commit=120 (Speed Hack)
    mount -o compress=zstd,noatime,commit=120 "$root_p" /mnt
    
    # [ ACTION ] Pre-Populate NZFS Structure & .hidden
    log "Pre-populating NZFS structure..."
    # [ REMOVED ] Persist directory
    mkdir -p /mnt/{System,Users,Live,Apps,Mount,boot,Config}
    mkdir -p /mnt/System/nix
    
    # [ UPDATE ] Create Directories for future Bind Mounts
    
    # 1. System
    mkdir -p /mnt/System/{Boot,Store,Current,Booted,Binaries,Modules,Firmware,Graphics,Wrappers,State,History,Logs}
    
    # 2. Live
    mkdir -p /mnt/Live/{dev,proc,sys,run,Temp,Memory,Services,Network,Sessions,Input,Video,Sound}
    mkdir -p /mnt/Live/Drives/{ID,Label,Partitions,Physical}
    
    # 3. Config Structure
    mkdir -p /mnt/Config/{Misc,Audio,Bluetooth,Desktop,Display,Fonts,Hardware,Network,Nix,Zero,Services,Security,System,User}
    mkdir -p /mnt/Config/Security/{PAM,SSH,SSL,Polkit}
    mkdir -p /mnt/Config/Audio/{Pipewire,Alsa}
    mkdir -p /mnt/Config/Desktop/{XDG,GDM,Plymouth,Remote,DConf}
    mkdir -p /mnt/Config/Display/X11
    mkdir -p /mnt/Config/Hardware/{Udev,LVM,Modprobe,Modules,BlockDev,UDisks,UPower,Qemu}
    mkdir -p /mnt/Config/Network/Manager
    mkdir -p /mnt/Config/Zero/{NixOS,Scripts}
    mkdir -p /mnt/Config/Services/{Systemd,DBus,Avahi,Geoclue}
    
    # 4. Config Files (Touch for Bind Mounts - Expanded Arrays)
    touch /mnt/Config/Network/{hosts,resolv.conf,resolvconf.conf,hostname,ethertypes,host.conf,ipsec.secrets,netgroup,protocols,rpc,services}
    touch /mnt/Config/Security/sudoers
    touch /mnt/Config/System/{fstab,os-release,profile,locale.conf,vconsole.conf,machine-id,localtime,inputrc,issue,kbd,login.defs,lsb-release,man_db.conf,nanorc,nscd.conf,nsswitch.conf,terminfo,zoneinfo}
    touch /mnt/Config/User/{passwd,group,shadow,shells,subgid,subuid,bashrc,bash_logout,zshrc,zshenv,zprofile,zinputrc}
    
    # 5. Users
    mkdir -p /mnt/Users/Admin
    
    printf "bin\nboot\ndev\netc\nhome\nlib\nlib64\nmnt\nnix\nopt\nproc\nroot\nrun\nsrv\nsys\ntmp\nusr\nvar" > /mnt/.hidden
    chmod 644 /mnt/.hidden

    # Mount Boot
    mount "$boot_p" /mnt/boot
    
    # We bind /boot to /System/Boot for the installer session so verification works
    mount --bind /mnt/boot /mnt/System/Boot

    # [ CRITICAL ] Bind Mount the Store from /System/nix to /nix
    mkdir -p /mnt/nix
    mount --bind /mnt/nix /mnt/System/nix

    # --- SWAP INITIALIZATION (64GB - RAM) ---
    local PHYSICAL_SWAP="/mnt/Live/swapfile"
    if [ ! -f "$PHYSICAL_SWAP" ]; then
        local TOTAL_RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
        local TARGET_SWAP_GB=$((64 - TOTAL_RAM_GB))
        if [ "$TARGET_SWAP_GB" -lt 4 ]; then TARGET_SWAP_GB=4; fi

        log "Synthesizing Dynamic Swap Buffer (${TARGET_SWAP_GB}GB) in /Live..."
        truncate -s 0 "$PHYSICAL_SWAP"
        chattr +C "$PHYSICAL_SWAP"
        fallocate -l "${TARGET_SWAP_GB}G" "$PHYSICAL_SWAP" || dd if=/dev/zero of="$PHYSICAL_SWAP" bs=1M count=$((TARGET_SWAP_GB * 1024)) status=progress
        chmod 600 "$PHYSICAL_SWAP"
        mkswap "$PHYSICAL_SWAP"
    fi
    if ! swapon --show | grep -q "$(readlink -f $PHYSICAL_SWAP)"; then swapon "$PHYSICAL_SWAP"; fi
}

# --- Phase 2: Hardware Discovery ---
echo -e "${CYAN}Available Silicon:${NC}"
lsblk -dno NAME,SIZE,MODEL,SERIAL | grep -v "loop"
read -p "Enter target drive (e.g., sdb): " DRIVE_NAME
TARGET_DEV="/dev/$DRIVE_NAME"

if [[ $TARGET_DEV == *"nvme"* ]]; then BOOT_PART="${TARGET_DEV}p1"; ROOT_PART="${TARGET_DEV}p2"
else BOOT_PART="${TARGET_DEV}1"; ROOT_PART="${TARGET_DEV}2"; fi

# --- Phase 3: Silicon Wipe ---
echo -e "\n${RED}## [ ! ] CRITICAL DECISION ##${NC}"
echo -e "Select ${GREEN}'n'${NC} to RESUME an interrupted install."
read -p "Format Drive? [y/N]: " FORMAT_CHOICE
RESUME_MODE="false"

if [[ "$FORMAT_CHOICE" =~ ^[Yy]$ ]]; then
    echo -e "\n${RED}!! WARNING: ERASING $TARGET_DEV !!${NC}"
    read -p "Type '$DRIVE_NAME' to confirm nuke: " CONFIRM_NAME
    if [ "$DRIVE_NAME" != "$CONFIRM_NAME" ]; then echo "Mismatch. Aborting."; exit 1; fi

    log "Nuking target silicon: $TARGET_DEV"
    sudo swapoff -a || true
    sudo wipefs -af "$TARGET_DEV"
    sgdisk -Z "$TARGET_DEV"
    sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"BOOT" "$TARGET_DEV"
    sgdisk -n 2:0:0 -t 2:8300 -c 2:"ZenOS-N" "$TARGET_DEV"
    sudo partprobe "$TARGET_DEV" && sleep 2
    mkfs.vfat -F 32 -n BOOT "$BOOT_PART"
    mkfs.btrfs -f -L ZenOS-N "$ROOT_PART"
else
    log "Resume Mode Active."
    RESUME_MODE="true"
fi

BOOT_UUID=$(lsblk -dno UUID "$BOOT_PART")
ROOT_UUID=$(lsblk -dno UUID "$ROOT_PART")
echo $ROOT_PART
echo $BOOT_PART
echo $ROOT_UUID
echo $BOOT_UUID
mount_target "$ROOT_PART" "$BOOT_PART" "$RESUME_MODE"

# --- Phase 4: Host Picker ---
mapfile -t HOST_LIST < <(grep -P '^\s+[a-zA-Z0-9_-]+\s+=\s+mkHost' flake.nix | awk '{print $1}')
HOST_COUNT=${#HOST_LIST[@]}
if [ "$HOST_COUNT" -eq 1 ]; then SELECTED_HOST="${HOST_LIST[0]}"; else
    for i in "${!HOST_LIST[@]}"; do echo -e "  $((i+1))) ${CYAN}${HOST_LIST[$i]}${NC}"; done
    while true; do
        read -p "Select Host [1-$HOST_COUNT]: " HOST_CHOICE
        if [[ "$HOST_CHOICE" =~ ^[0-9]+$ ]] && [ "$HOST_CHOICE" -ge 1 ]; then SELECTED_HOST="${HOST_LIST[$((HOST_CHOICE-1))]}"; break; fi
    done
fi

log "Patching flake for $SELECTED_HOST..."
# Apply UUIDs
BOOT_UUID=$(lsblk -dno UUID "$BOOT_PART")
ROOT_UUID=$(lsblk -dno UUID "$ROOT_PART")
echo $ROOT_PART
echo $BOOT_PART
echo $ROOT_UUID
echo $BOOT_UUID
sed -i "/$SELECTED_HOST = mkHost {/,/};/s/rootUUID = \".*\"/rootUUID = \"$ROOT_UUID\"/" flake.nix
sed -i "/$SELECTED_HOST = mkHost {/,/};/s/bootUUID = \".*\"/bootUUID = \"$BOOT_UUID\"/" flake.nix

# [ FIX ] UUID Verification Guard
FLAKE_ROOT_UUID=$(grep -A 5 "$SELECTED_HOST = mkHost {" flake.nix | grep "rootUUID" | awk -F'"' '{print $2}')

if [ "$FLAKE_ROOT_UUID" != "$ROOT_UUID" ]; then
    echo -e "${RED}## [ ! ] CRITICAL ERROR: UUID Mismatch detected! ##${NC}"
    echo -e "  Disk UUID:  $ROOT_UUID"
    echo -e "  Flake UUID: $FLAKE_ROOT_UUID"
    echo -e "The 'sed' command failed to patch flake.nix correctly."
    echo -e "Please edit flake.nix manually to match the Disk UUID before proceeding."
    exit 1
else
    echo -e "${GREEN}## [ OK ] UUID Verification Passed. ##${NC}"
fi

# --- Phase 5: Synthesis ---
echo -e "\n${YELLOW}## [ ? ] CORE-AWARE PARALLELISM ##${NC}"

# [ NEW ] Core-Relative Calculation
CORE_COUNT=$(nproc)
echo "Detected Cores: $CORE_COUNT"

PARALLEL_JOBS="$CORE_COUNT"
read -p "Enable Hyper-Parallel Downloads (max-jobs = Cores * 4)? [Y/n] " PARA_CHOICE
if [[ "$PARA_CHOICE" =~ ^[Yy]$ || -z "$PARA_CHOICE" ]]; then
    PARALLEL_JOBS=$((CORE_COUNT * 4))
    echo -e "${GREEN}-> Hyper-Threading Enabled ($PARALLEL_JOBS Jobs).${NC}"
fi

read -p "Enable Ultra-Speed Mode (Disable Docs)? [Y/n] " SPEED_CHOICE
if [[ "$SPEED_CHOICE" =~ ^[Yy]$ || -z "$SPEED_CHOICE" ]]; then
    if [ -f "src/modules/core/nzfs.nix" ]; then NZFS_FILE="src/modules/core/nzfs.nix"; elif [ -f "nzfs.nix" ]; then NZFS_FILE="nzfs.nix"; fi
    if [ -n "$NZFS_FILE" ] && ! grep -q "documentation.enable = false;" "$NZFS_FILE"; then
         log "Disabling documentation in NZFS module..."
         sed -i '/config = lib.mkIf cfg.enable {/a \    documentation.enable = false;\n    documentation.nixos.enable = false;\n    documentation.man.enable = false;' "$NZFS_FILE"
    fi
fi

BINARY_CACHES="https://cache.nixos.org https://nyx.chaotic.cx https://nix-gaming.cachix.org https://nix-community.cachix.org"
TRUSTED_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= chaotic-nyx.cx:htPHGL5kRgd89+O9TV+n0n+jD3v5Z20D5e7z7aM3Q0Q= nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

# ZeroCache (USB)
CACHE_PART=$(lsblk -o NAME,LABEL,PATH -nr | grep "ZEROCACHE" | head -n1 | awk '{print $3}')
if [ -n "$CACHE_PART" ]; then mkdir -p /tmp/zerocache; mount "$CACHE_PART" /tmp/zerocache; BINARY_CACHES="file:///tmp/zerocache $BINARY_CACHES"; fi

read -p "Add Local LAN Cache? [Enter to skip]: " LOCAL_CACHE
if [ -n "$LOCAL_CACHE" ]; then BINARY_CACHES="$LOCAL_CACHE $BINARY_CACHES"; fi

echo -e "\n${BLUE}-> Phase 5: Synthesis Initiated...${NC}"

nixos-install \
    --flake ".#$SELECTED_HOST" \
    --no-root-passwd \
    --option substituters "$BINARY_CACHES" \
    --option trusted-public-keys "$TRUSTED_KEYS" \
    --option builders-use-substitutes true \
    --option max-jobs $PARALLEL_JOBS \
    --option cores 0 \
    --option http-connections 128 \
    --option download-buffer-size 67108864 \
    --option connect-timeout 5 \
    --option stalled-download-timeout 90 \
    --option keep-going true

# --- Phase 6: Finalizer ---
log "Entering final configuration phase..."

# [ UX ] Default Password Fallback
sudo -E nixos-enter --root /mnt -- sh -c 'echo "root:zenos" | chpasswd' 2>/dev/null || true

# [ UX ] Interactive Password Menu
echo -e "\n${YELLOW}## [ ? ] SECURITY SETTINGS ##${NC}"
read -p "Do you want to interactively set passwords for users? (Default: 'zenos') [y/N] " PASS_CHOICE

if [[ "$PASS_CHOICE" =~ ^[Yy]$ ]]; then
    log "Starting interactive password manager..."
    
    # 1. Gather Users
    mapfile -t HUMAN_USERS < <(grep -E ':1[0-9]{3}:' /mnt/etc/passwd | cut -d: -f1)
    ALL_USERS=("root" "${HUMAN_USERS[@]}")
    
    while true; do
        echo -e "\n${CYAN}Available Users:${NC}"
        for i in "${!ALL_USERS[@]}"; do
            echo -e "  $((i+1))) ${ALL_USERS[$i]}"
        done
        echo -e "  d) Done"
        
        read -p "Select user to modify [1-${#ALL_USERS[@]} or 'd']: " USER_SEL
        
        if [[ "$USER_SEL" == "d" || "$USER_SEL" == "D" ]]; then
            break
        elif [[ "$USER_SEL" =~ ^[0-9]+$ ]] && [ "$USER_SEL" -ge 1 ] && [ "$USER_SEL" -le "${#ALL_USERS[@]}" ]; then
            TARGET_USER="${ALL_USERS[$((USER_SEL-1))]}"
            echo -e "\n${YELLOW}>> Changing password for: ${RED}$TARGET_USER${NC}"
            if sudo -E nixos-enter --root /mnt -- passwd "$TARGET_USER"; then
                echo -e "${GREEN}>> Password updated successfully.${NC}"
            else
                echo -e "${RED}>> Failed to update password.${NC}"
            fi
        else
            echo -e "${RED}Invalid selection.${NC}"
        fi
    done
    log "Password configuration completed."
else
    log "Skipping custom passwords. Default 'root:zenos' set."
fi

# [ ACTION ] Final Boot Loader Install
sudo -E nixos-enter --root /mnt <<'EOF'
    echo "Finalizing Boot Mesh..."
    /nix/var/nix/profiles/system/bin/switch-to-configuration boot
EOF

# --- Phase 7: Verification Protocol ---
echo -e "\n${BLUE}## [ -0 ] POST-INSTALL VERIFICATION ##${NC}"

# [ FIX ] Use eval to properly parse complex conditionals like "&&"
check() {
    if eval "$1"; then 
        echo -e "  [${GREEN}OK${NC}] $2"
    else 
        echo -e "  [${RED}FAIL${NC}] $2"
    fi
}

log "Running integrity checks..."

# 1. Mount Check
check "[ -d /mnt/nix/store ]" "Nix Store Populated"
check "[ -d /mnt/boot/EFI ]" "ESP Mounted & Populated"

# 2. Bootloader Check
check "[ -f /mnt/boot/EFI/refind/refind_x64.efi ]" "rEFInd Binary Present"
check "[ -f /mnt/boot/EFI/refind/zenos-entries.conf ]" "ZenOS Boot Entries Generated"

# 3. User Check
# [ FIX ] Relaxed check to find ANY user with UID >= 1000
check "grep -E -q ':1[0-9]{3}:' /mnt/etc/passwd" "Primary User Created"

# 4. NZFS Check
# [ FIX ] Eval inside check() now handles the && properly
check "[ -d /mnt/System/nix ] && [ -d /mnt/Config ]" "NZFS Hierarchy (Bind Mount Ready)"

trap - ERR SIGINT
echo -e "\n${GREEN}## [ SUCCESS ] ZENOS SYNTHESIZED (v1.14 - Final Guard)${NC}"
if command -v notify-send &> /dev/null; then notify-send -u normal -a "ZenOS Installer" "Success" "Installation Complete."; fi
