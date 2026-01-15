.
├── coreModules
│   ├── graphical
│   │   ├── flatpak.nix
│   │   ├── misc.nix
│   │   └── pipewire.nix
│   ├── server
│   │   └── misc.nix
│   └── shared
│       ├── boot.nix
│       ├── branding.nix
│       ├── locale.nix
│       ├── net.nix
│       ├── security.nix
│       ├── shell.nix
│       └── syncthing.nix
├── desktops
│   ├── gnome
│   │   ├── main.nix
│   │   └── zenos-styling.nix
│   ├── ii
│   │   └── main.nix
│   └── kde
│       └── main.nix
├── deviceConfigs
│   ├── amd
│   │   ├── cpu
│   │   │   ├── generic.nix
│   │   │   └── r9-9700.nix
│   │   └── gpu
│   │       ├── generic.nix
│   │       └── rx6900xt.nix
│   ├── hosts
│   │   └── dt2-tweaks.nix
│   ├── intel
│   ├── nvidia
│   ├── qemu-guest.nix
│   ├── ram
│   │   ├── tier16.nix
│   │   ├── tier32.nix
│   │   ├── tier4.nix
│   │   ├── tier64.nix
│   │   └── tier8.nix
│   ├── tablet.nix
│   └── tweaks
│       ├── networking.nix
│       └── storage.nix
├── flake.lock
├── flake.nix
├── helperScripts
│   ├── preview-plymouth.sh
│   ├── project_dumper.sh
│   └── stresstest.sh
├── hosts
│   ├── doromi-server
│   │   └── main.nix
│   └── doromi-tul-2
│       ├── main.nix
│       └── syncthing.nix
├── lib
│   └── utils.nix
├── modules
│   ├── creative
│   │   └── vscode.nix
│   ├── gaming
│   │   └── steam.nix
│   ├── server
│   │   └── copyparty.nix
│   ├── structure.nix
│   └── virtualization
│       ├── containers.nix
│       └── qemu.nix
├── oldsrc
│   ├── hosts
│   │   ├── aethertop
│   │   │   ├── hardware.nix
│   │   │   ├── main.nix
│   │   │   └── syncthing.nix
│   │   ├── doromipad
│   │   │   ├── hardware.nix
│   │   │   ├── main.nix
│   │   │   └── syncthing.nix
│   │   ├── doromi-server
│   │   │   ├── hardware.nix
│   │   │   ├── main.nix
│   │   │   └── syncthing.nix
│   │   ├── doromi-tul-2
│   │   │   ├── hardware.nix
│   │   │   ├── main.nix
│   │   │   └── syncthing.nix
│   │   ├── kitty-laptop
│   │   │   ├── hardware.nix
│   │   │   ├── main.nix
│   │   │   └── syncthing.nix
│   │   └── test-vm
│   │       ├── hardware.nix
│   │       └── main.nix
│   ├── modules
│   │   ├── core
│   │   │   ├── boot.nix
│   │   │   ├── branding.nix
│   │   │   ├── flatpak.nix
│   │   │   ├── locale.nix
│   │   │   ├── misc-services.nix
│   │   │   ├── net.nix
│   │   │   ├── nzfs.nix
│   │   │   ├── security.nix
│   │   │   ├── shell.nix
│   │   │   └── syncthing.nix
│   │   ├── desktop
│   │   │   ├── gnome
│   │   │   │   ├── main.nix
│   │   │   │   └── styling.nix
│   │   │   ├── hyprland
│   │   │   │   └── main.nix
│   │   │   ├── ii
│   │   │   │   └── main.nix
│   │   │   └── kde
│   │   ├── roles
│   │   │   ├── containers.nix
│   │   │   ├── creative
│   │   │   │   ├── audio.nix
│   │   │   │   ├── graphics.nix
│   │   │   │   ├── misc.nix
│   │   │   │   └── video.nix
│   │   │   ├── dev.nix
│   │   │   ├── gaming
│   │   │   │   ├── emulation.nix
│   │   │   │   ├── main.nix
│   │   │   │   ├── minecraft.nix
│   │   │   │   └── xr.nix
│   │   │   ├── gaming.nix
│   │   │   ├── pipewire.nix
│   │   │   ├── tablet.nix
│   │   │   ├── virtualization.nix
│   │   │   ├── web.nix
│   │   │   └── zbridge.nix
│   │   └── server
│   │       ├── cloudflare.nix
│   │       ├── copyparty.nix
│   │       ├── forgejo.nix
│   │       ├── immich.nix
│   │       ├── jellyfin.nix
│   │       └── minecraft.nix
│   ├── scripts
│   │   ├── gaming
│   │   │   ├── start-vr.sh
│   │   │   └── zeroplay-manager.py
│   │   ├── make-zero.py
│   │   ├── refind.py
│   │   ├── zbridge
│   │   │   ├── zb-config.sh
│   │   │   ├── zb-daemon.sh
│   │   │   └── zb-installer.sh
│   │   ├── zbridge.sh
│   │   └── zenos-rebuild.sh
│   └── users
│       ├── aether
│       │   ├── dconf.nix
│       │   ├── graphical.nix
│       │   ├── janitor.nix
│       │   ├── keepass.nix
│       │   ├── main.nix
│       │   ├── pwa.nix
│       │   └── shortcuts.nix
│       ├── blade0
│       │   ├── dconf.nix
│       │   ├── graphical.nix
│       │   ├── janitor.nix
│       │   ├── keepass.nix
│       │   ├── main.nix
│       │   ├── pwa.nix
│       │   └── shortcuts.nix
│       ├── cat
│       │   ├── dconf.nix
│       │   ├── graphical.nix
│       │   ├── janitor.nix
│       │   ├── keepass.nix
│       │   ├── main.nix
│       │   ├── pwa.nix
│       │   └── shortcuts.nix
│       ├── doromiert
│       │   ├── dconf.nix
│       │   ├── graphical.nix
│       │   ├── janitor.nix
│       │   ├── keepass.nix
│       │   ├── main.nix
│       │   ├── pwa.nix
│       │   └── shortcuts.nix
│       ├── ecodz
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── hubi
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── jeyphr
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── lenni
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── meowster
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── saphhie
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── saxum
│       │   ├── graphical.nix
│       │   └── main.nix
│       ├── shareduser
│       │   ├── graphical.nix
│       │   └── main.nix
│       └── xen
│           ├── graphical.nix
│           └── main.nix
├── README.md
├── stateVersion.txt
├── tree.nix
├── users
│   └── doromiert
│       ├── graphical.nix
│       └── main.nix
└── zenos-installer.sh

66 directories, 158 files
