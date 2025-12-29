# Specification Sheet: ZenOS N 

## 1. Vision & Overview
**Project Name:** ZenOS 1.0N
**Identity:** The flagship OS environment for Negative Zero hardware.
**Goal:** A monolithic NixOS Flake repository managing a "Meta-Distro" environment.
**Core Philosophy:** "Hybrid & Portable" — The Main PC acts as a high-performance Workstation and Hypervisor, isolating Server functions into a declarative VM for stability, while specific power states manage energy efficiency.

## 2. Architecture: The Flake
The repository utilizes a single `flake.nix` entry point.

### Inputs
* **Core:** `nixos-25.11` (Unified Stable Base).
* **Optimization:** `chaotic-nyx` (Provides CachyOS kernel/v3-v4 binaries for performance).
* **Hardware:** `nixos-hardware`.
* **User Env:** `home-manager`.
* **Theming:** `stylix`.
* **Gaming:** `nix-gaming`, `nix-minecraft`.
* **Extensions:** `firefox-pwa`, `nix-vscode-extensions`.
* **Custom:** `swisstag`.

## 3. Branding & Visual Identity
* **Boot Sequence:** Custom Plymouth script featuring a static "Negative Zero" logo with a 4s period pulsing purple glow (`#6a0dad`).
* **Bootloader:** rEFInd with custom NZ-theme.
* **Typography:**
    * System: Atkinson Hyperlegible.
    * Terminal/Mono: Atkinson Hyperlegible Mono.
* **Cursor:** Googledot-black.
* **Icons:** Adwaita-hacks.

## 4. Profiles (Hosts)

### Host A: `doromi-tul-ii` (Main PC)
* **Role:** Workstation, Hypervisor & Gaming Rig.
* **Hardware:** Ryzen 9 7900, RX 6900XT.
* **OS Base:** NixOS 25.11 + `chaotic-nyx`.
* **Storage Strategy:**
    * Swapfiles managed via `swapDevices` (No partitions).
    * Dedicated HDD for server data (passed to VM).
* **Virtualization (Libvirt/QEMU):**
    * **Guest:** `doromi-server` (KVM).
    * **Windows VM:** Dynamic GPU pass-through (RX 6900XT) via libvirt hooks.
    * **Looking Glass:** Low-latency VM frame relay.
    * **Bridge:** `/host` shared folder mount for instant file access between VM and Host.
* **Power Management ("Away" Mode):**
    * **Trigger:** `systemctl isolate server-mode.target`.
    * **State:**
        * CPU governor switches to `powersave`.
        * Stops GDM/GNOME entirely (frees GPU/CPU).
        * Disables non-essential hardware wakeups.
        * Background services: `ntfy` (alerts), `syncthing`, `doromi-server` VM.
    * **Automation:** Triggers `nix-collect-garbage -d`, `fstrim -av`, and auto-updates once stable.
    * **Remote:** KDE Connect + `NOPASSWD` sudo rules for power toggles.

### Host B: `doromipad` (ThinkPad L13)
* **Role:** Portable x86 Tablet.
* **OS Base:** NixOS 25.11.
* **Modules:** `core`, `desktop`, `roles/tablet`, `roles/creative` (Lightweight).
* **Power:** GNOME Power Profiles Daemon.

### Host C: `doromi-server` (The VM)
* **Role:** Dedicated Server (Virtualized).
* **OS Base:** NixOS 25.11 (Headless).
* **Hardware:** VirtIO Drivers (QEMU Guest Agent enabled).
* **Networking:** Cloudflare Tunnel (Ingress), Bridged Adapter (LAN Access).
* **Services:** See Section 6.

## 5. Software Stack (User: doromiert)

### 5.1. Core & Productivity
* **Browser:**
    * Firefox (Main): Hardened + `firefox-gnome-theme` + `hide-single-tab` CSS hack.
    * Google Chrome: Compatibility backup.
* **Communication:** Discord (Vencord), Telegram (64Gram/Kotatogram).
* **Office:** LibreOffice (GTK4/Adwaita VCL branding), Obsidian (Synced), RNote, Apostrophe.
* **Creative Suite:**
    * **DAW:** Bitwig Studio (Modular/Visual workflow).
    * **Visuals:** Blender, Kdenlive, Natron (UI Motion Graphics), Figma (via FirefoxPWA).
* **Utils:** Parabolic, Ear Tag, SwissTag, Extension Manager, Resources, Showtime.

### 5.2. Development & CLI
* **Shell:** Zsh + Powerlevel10k + Zoxide.
* **Editor:** VS Code, **Black Box** (Terminal), **Buffer** (Scratchpad).
* **Dev Tools:** Biblioteca (GTK4 Learning), Dev Toolbox, Iconic, Git.

### 5.3. GNOME Desktop Environment
* **Window Management:** Forge (Tiling), Burn My Windows, Compiz Windows Effect, Compiz-alike Magic Lamp Effect, Rounded Window Corners, Blur My Shell.
* **UX/Navigation:** AlphabeticalAppGrid, Category Sorted App Grid, CoverflowAltTab, Hide Top Bar, Mouse Tail, Tweaks System Menu.
* **System:** GSConnect, Clipboard Indicator, Notification Timeout.

### 5.4. Connectivity
* **Android Integration:** `rquickshare` (Quick Share support), KDE Connect (GSConnect).

## 6. Data & Directory Schema

### 6.1. Home Directory Structure
* **Standard:** Documents, Pictures, Videos, Music.
* **Custom:**
    * `~/Downloads` (Symlink target).
    * `~/Funny`, `~/Projects`, `~/3D`, `~/Android`, `~/AI`, `~/Apps & Scripts`.
    * `~/Doom`, `~/Rift`, `~/Random`, `~/Passwords`.

### 6.2. The Janitor Daemon
* **Implementation:** Python/Watchdog daemon.
* **Function:** Monitors `~/Downloads`, sorts files based on extension, and creates categorized symlinks back to `~/Downloads` for easy access while keeping actual storage structured.

## 7. The Negative Zero Game Library
* **Path Structure:** `Games/{System}/{Title}/` containing:
    * `Rom`, `Config`, `Saves`, `Mods`, `Cheats`, `Updates`, `Media`, `Manuals`.
* **Minecraft:** Prism Launcher.
    * **Optimization:** Custom Java flags (ZGC, memory tuning) defined in Nix.
    * **UI:** Scaled for high-DPI/Gamescope accessibility.
* **Steam:** Runs via Gamescope.

## 8. Server Services (VM Guest)
* **Media:** Jellyfin, Immich (Photo Backup).
* **Files:** Copyparty (File Server).
* **Code:** Forgejo (Git Server).
* **Gaming:** Minecraft Server (Declarative).
* **Access:** SSH, Cloudflare Tunnel.

## 9. File Structure (Flake)
```text
.
├── flake.nix
├── resources/
│   ├── zenos-logo.png          # 512x512 Transparent
│   ├── plymouth/               # Custom pulsing script
│   ├── GoogleDot-Black/
│   ├── Adwaita-hacks/
│   └── wallpapers/
├── hosts/
│   ├── doromi-tul-ii/          # Main PC
│   │   ├── main.nix
│   │   ├── hardware.nix        # Includes swapDevices
│   │   ├── power-modes.nix     # "Away" mode systemd targets
│   │   └── virtualization.nix  # GPU Pass-through hooks
│   ├── doromipad/
│   └── doromi-server/
├── modules/
│   ├── core/
│   │   ├── chaotic.nix         # Chaotic-Nyx config
│   │   ├── janitor.nix         # Systemd service for Python watchdog
│   │   └── ...
│   ├── desktop/
│   │   ├── gnome-extensions.nix
│   │   └── styling.nix
│   ├── roles/
│   └── server/
└── users/
    └── doromiert/
        ├── scripts/
        │   └── janitor.py
        └── home.nix