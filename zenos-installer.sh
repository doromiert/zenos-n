#!/usr/bin/env bash

# Negative Zero - ZeroInstaller [v6.1.0]
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

echo -e "${BLUE}## [ -0 ] ZENOS ZEROINSTALLER v6.1.0 (System-Root Edition)${NC}"

# --- Configuration: Mount Point ---
echo -e "\n${YELLOW}## [ ? ] CONFIGURATION ##${NC}"
read -p "Target Mount Point (Default: /mnt): " MOUNT_POINT
MOUNT_POINT=${MOUNT_POINT:-/mnt}
echo -e "${GREEN}-> Install Root set to: $MOUNT_POINT${NC}"

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
    sudo umount "$MOUNT_POINT/Live/swapfile" 2>/dev/null || true
    sudo umount /tmp/zerocache 2>/dev/null || true
    if swapon --show | grep -q "swapfile"; then sudo swapoff -a || true; fi
    
    if mountpoint -q "$MOUNT_POINT"; then
        sudo fuser -km "$MOUNT_POINT" 2>/dev/null || true
        sudo umount -R "$MOUNT_POINT" 2>/dev/null || sudo umount -l "$MOUNT_POINT" 2>/dev/null || true
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

# --- Phase 1: Host Picker (Moved from P4) ---
echo -e "\n${YELLOW}## [ 1 ] HOST SELECTION ##${NC}"
mapfile -t HOST_LIST < <(grep -P '^\s+[a-zA-Z0-9_-]+\s+=\s+mkHost' flake.nix | awk '{print $1}')
HOST_COUNT=${#HOST_LIST[@]}
if [ "$HOST_COUNT" -eq 1 ]; then SELECTED_HOST="${HOST_LIST[0]}"; else
    for i in "${!HOST_LIST[@]}"; do echo -e "  $((i+1))) ${CYAN}${HOST_LIST[$i]}${NC}"; done
    while true; do
        read -p "Select Host [1-$HOST_COUNT]: " HOST_CHOICE
        if [[ "$HOST_CHOICE" =~ ^[0-9]+$ ]] && [ "$HOST_CHOICE" -ge 1 ]; then SELECTED_HOST="${HOST_LIST[$((HOST_CHOICE-1))]}"; break; fi
    done
fi
echo -e "${GREEN}-> Selected Host: $SELECTED_HOST${NC}"

# --- Phase 2: Hardware Discovery & Unmount ---
echo -e "\n${YELLOW}## [ 2 ] HARDWARE DISCOVERY ##${NC}"
echo -e "${CYAN}Available Silicon:${NC}"
lsblk -dno NAME,SIZE,MODEL,SERIAL | grep -v "loop"
read -p "Enter target drive (e.g., sdb): " DRIVE_NAME
TARGET_DEV="/dev/$DRIVE_NAME"

# [ NEW ] Auto-Unmount Logic
log "Checking for active mounts on $TARGET_DEV..."
for mount in $(lsblk -n -o MOUNTPOINT "$TARGET_DEV" | grep -v "^$"); do
    log "Unmounting active partition: $mount"
    sudo umount "$mount" || sudo umount -l "$mount" || true
done
# Double check with grep to catch anything lsblk missed or sub-mounts
if grep -qs "$TARGET_DEV" /proc/mounts; then
    log "Force unmounting remaining references to $TARGET_DEV..."
    sudo umount -R "$TARGET_DEV"* 2>/dev/null || true
fi
sudo swapoff -a || true

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

# --- Phase 3.5: Flake Patching ---
log "Patching flake for $SELECTED_HOST..."
sed -i "/$SELECTED_HOST = mkHost {/,/};/s/rootUUID = \".*\"/rootUUID = \"$ROOT_UUID\"/" flake.nix
sed -i "/$SELECTED_HOST = mkHost {/,/};/s/bootUUID = \".*\"/bootUUID = \"$BOOT_UUID\"/" flake.nix

# [ FIX ] UUID Verification Guard
FLAKE_ROOT_UUID=$(grep -A 5 "$SELECTED_HOST = mkHost {" flake.nix | grep "rootUUID" | awk -F'"' '{print $2}')

if [ "$FLAKE_ROOT_UUID" != "$ROOT_UUID" ]; then
    echo -e "${RED}## [ ! ] CRITICAL ERROR: UUID Mismatch detected! ##${NC}"
    echo -e "  Disk UUID:  $ROOT_UUID"
    echo -e "  Flake UUID: $FLAKE_ROOT_UUID"
    exit 1
else
    echo -e "${GREEN}## [ OK ] UUID Verification Passed. ##${NC}"
fi

# --- Phase 4: Environment Setup ---
export NIXPKGS_ALLOW_UNFREE=1

mount_target() {
    local root_p=$1
    local boot_p=$2
    local resume=$3
    
    if mountpoint -q "$MOUNT_POINT"; then 
        sudo fuser -km "$MOUNT_POINT" 2>/dev/null || true
        sudo umount -R "$MOUNT_POINT" || true 
    fi

    log "Establishing Flat NZFS 2.3 Peer Hierarchy (Btrfs) at $MOUNT_POINT..."
    mkdir -p "$MOUNT_POINT"
    
    # [ ACTION ] Mount Root with ZSTD + Commit=120 (Speed Hack)
    mount -o compress=zstd,noatime,commit=120 "$root_p" "$MOUNT_POINT"
    
    # [ ACTION ] Pre-Populate NZFS Structure & .hidden
    log "Pre-populating NZFS structure..."
    mkdir -p "$MOUNT_POINT"/{System,Users,Live,Apps,Mount,boot,Config}
    mkdir -p "$MOUNT_POINT"/System/nix
    
    # 1. System
    mkdir -p "$MOUNT_POINT"/System/{Boot,Store,Current,Booted,Binaries,Modules,Firmware,Graphics,Wrappers,State,History,Logs}
    
    # 2. Live
    mkdir -p "$MOUNT_POINT"/Live/{dev,proc,sys,run,Temp,Memory,Services,Network,Sessions,Input,Video,Sound}
    mkdir -p "$MOUNT_POINT"/Live/Drives/{ID,Label,Partitions,Physical}
    
    # 3. Config Structure
    mkdir -p "$MOUNT_POINT"/Config/{Misc,Audio,Bluetooth,Desktop,Display,Fonts,Hardware,Network,Nix,Zero,Services,Security,System,User}
    mkdir -p "$MOUNT_POINT"/Config/Security/{PAM,SSH,SSL,Polkit}
    mkdir -p "$MOUNT_POINT"/Config/Audio/{Pipewire,Alsa}
    mkdir -p "$MOUNT_POINT"/Config/Desktop/{XDG,GDM,Plymouth,Remote,DConf}
    mkdir -p "$MOUNT_POINT"/Config/Display/X11
    mkdir -p "$MOUNT_POINT"/Config/Hardware/{Udev,LVM,Modprobe,Modules,BlockDev,UDisks,UPower,Qemu}
    mkdir -p "$MOUNT_POINT"/Config/Network/Manager
    mkdir -p "$MOUNT_POINT"/Config/Zero/{NixOS,Scripts}
    mkdir -p "$MOUNT_POINT"/Config/Services/{Systemd,DBus,Avahi,Geoclue}
    
    # 4. Config Files
    touch "$MOUNT_POINT"/Config/Network/{hosts,resolv.conf,resolvconf.conf,hostname,ethertypes,host.conf,ipsec.secrets,netgroup,protocols,rpc,services}
    touch "$MOUNT_POINT"/Config/Security/sudoers
    touch "$MOUNT_POINT"/Config/System/{fstab,os-release,profile,locale.conf,vconsole.conf,machine-id,localtime,inputrc,issue,kbd,login.defs,lsb-release,man_db.conf,nanorc,nscd.conf,nsswitch.conf,terminfo,zoneinfo}
    touch "$MOUNT_POINT"/Config/User/{passwd,group,shadow,shells,subgid,subuid,bashrc,bash_logout,zshrc,zshenv,zprofile,zinputrc}
    
    # 5. Users
    mkdir -p "$MOUNT_POINT"/Users/Admin
    
    printf "bin\nboot\ndev\netc\nhome\nlib\nlib64\nmnt\nnix\nopt\nproc\nroot\nrun\nsrv\nsys\ntmp\nusr\nvar" > "$MOUNT_POINT"/.hidden
    chmod 644 "$MOUNT_POINT"/.hidden

    # Mount Boot
    mount "$boot_p" "$MOUNT_POINT"/boot
    
    # We bind /boot to /System/Boot for the installer session so verification works
    mount --bind "$MOUNT_POINT"/boot "$MOUNT_POINT"/System/Boot

    # [ CRITICAL ] Bind Mount the Store from /System/nix to /nix
    mkdir -p "$MOUNT_POINT"/nix
    mount --bind "$MOUNT_POINT"/nix "$MOUNT_POINT"/System/nix

    # --- SWAP INITIALIZATION (DYNAMIC MODE) ---
    local PHYSICAL_SWAP="$MOUNT_POINT/Live/swapfile"
    if [ ! -f "$PHYSICAL_SWAP" ]; then
        # Check actual RAM and Disk Space
        local TOTAL_RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
        local FREE_DISK_GB=$(df -BG --output=avail "$MOUNT_POINT" | tail -n1 | tr -dc '0-9')
        
        # 1. Base Target: 8GB ideal for Nix builds
        local TARGET_SWAP_GB=8
        
        # 2. Safety Limit: Max 50% of free space
        local MAX_SAFE_SWAP=$((FREE_DISK_GB / 2))
        
        if [ "$TARGET_SWAP_GB" -gt "$MAX_SAFE_SWAP" ]; then
            log "Disk constrained ($FREE_DISK_GB GB free). Throttling swap to ${MAX_SAFE_SWAP}GB..."
            TARGET_SWAP_GB=$MAX_SAFE_SWAP
        fi
        
        # 3. Absolute Floor: 2GB (Unless disk is completely full, then 0)
        if [ "$TARGET_SWAP_GB" -lt 2 ] && [ "$MAX_SAFE_SWAP" -ge 2 ]; then TARGET_SWAP_GB=2; fi

        if [ "$TARGET_SWAP_GB" -ge 1 ]; then
            log "Synthesizing Dynamic Swap Buffer (${TARGET_SWAP_GB}GB) in /Live..."
            truncate -s 0 "$PHYSICAL_SWAP"
            chattr +C "$PHYSICAL_SWAP"
            # Using dd instead of fallocate for btrfs swapfile compatibility safety
            dd if=/dev/zero of="$PHYSICAL_SWAP" bs=1M count=$((TARGET_SWAP_GB * 1024)) status=progress
            chmod 600 "$PHYSICAL_SWAP"
            mkswap "$PHYSICAL_SWAP"
        else
            log "WARNING: Not enough disk space for Swap. Skipping."
        fi
    fi
    if [ -f "$PHYSICAL_SWAP" ] && ! swapon --show | grep -q "$(readlink -f $PHYSICAL_SWAP)"; then swapon "$PHYSICAL_SWAP"; fi
}

mount_target "$ROOT_PART" "$BOOT_PART" "$RESUME_MODE"

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

# --- [ NEW ] GitHub Token Injection ---
echo -e "\n${YELLOW}## [ ? ] GITHUB RATE LIMIT BYPASS ##${NC}"
echo "Enter your GitHub Personal Access Token to avoid HTTP 429 errors."
echo "Leave empty to skip."
read -s -p "GitHub Token (Hidden): " GH_TOKEN
echo ""
if [ -n "$GH_TOKEN" ]; then
    export NIX_CONFIG="access-tokens = github.com=$GH_TOKEN"
    log "GitHub Token injected into build environment."
fi
# ----------------------------------------

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
    --root "$MOUNT_POINT" \
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
sudo -E nixos-enter --root "$MOUNT_POINT" -- sh -c 'echo "root:zenos" | chpasswd' 2>/dev/null || true

# [ UX ] Interactive Password Menu
echo -e "\n${YELLOW}## [ ? ] SECURITY SETTINGS ##${NC}"
read -p "Do you want to interactively set passwords for users? (Default: 'zenos') [y/N] " PASS_CHOICE

if [[ "$PASS_CHOICE" =~ ^[Yy]$ ]]; then
    log "Starting interactive password manager..."
    
    # 1. Gather Users
    mapfile -t HUMAN_USERS < <(grep -E ':1[0-9]{3}:' "$MOUNT_POINT"/etc/passwd | cut -d: -f1)
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
            if sudo -E nixos-enter --root "$MOUNT_POINT" -- passwd "$TARGET_USER"; then
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
sudo -E nixos-enter --root "$MOUNT_POINT" <<'EOF'
    echo "Finalizing Boot Mesh..."
    /nix/var/nix/profiles/system/bin/switch-to-configuration boot
EOF

sudo cp . "$MOUNT_POINT"/zenos-config -r

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
check "[ -d $MOUNT_POINT/nix/store ]" "Nix Store Populated"
check "[ -d $MOUNT_POINT/boot/EFI ]" "ESP Mounted & Populated"

# 2. Bootloader Check
check "[ -f $MOUNT_POINT/boot/EFI/refind/refind_x64.efi ]" "rEFInd Binary Present"
check "[ -f $MOUNT_POINT/boot/EFI/refind/zenos-entries.conf ]" "ZenOS Boot Entries Generated"

# 3. User Check
check "grep -E -q ':1[0-9]{3}:' $MOUNT_POINT/etc/passwd" "Primary User Created"

# 4. NZFS Check
check "[ -d $MOUNT_POINT/System/nix ] && [ -d $MOUNT_POINT/Config ]" "NZFS Hierarchy (Bind Mount Ready)"

trap - ERR SIGINT
echo -e "\n${GREEN}## [ SUCCESS ] ZENOS SYNTHESIZED (v6.1.0 - Final Guard)${NC}"
if command -v notify-send &> /dev/null; then notify-send -u normal -a "ZenOS Installer" "Success" "Installation Complete."; fi
