#!/usr/bin/env bash

set -e

echo "Initializing Nix configuration structure..."

mkdir -p modules/core
mkdir -p modules/desktop
mkdir -p modules/roles
mkdir -p modules/server
mkdir -p users/doromiert/resources

touch flake.nix

hosts=(
    
    "doromi-tul-ii"
    "doromipad"
    "doromi-server"
)

users=(
    # anax kulup
    "doromiert"
    "cnb"
    # admins
    "meowster"
    "blade0"
    "lenni"
    "ecodz"
    # friends
    "jeyphr"
    "saphhie"
    "aether"
    "xen"
    # roxyna
    "hubi"
    "saxum"
    # useful
    "shareduser"
)

for host in "${hosts[@]}"; do
    mkdir "hosts/$host"
    touch "hosts/$host/main.nix"
    touch "hosts/$host/hardware.nix"
    touch "hosts/$host/syncthing.nix"
done

for user in "${users[@]}"; do
    mkdir "users/$user"
    touch "users/$user/main.nix" # for both server and graphical envs
    touch "users/$user/graphical.nix"
done

# Core
touch modules/core/branding.nix
touch modules/core/security.nix
touch modules/core/shell.nix
touch modules/core/syncthing.nix # will contain all devices we want to use
touch modules/core/misc-services.nix

# Desktop
touch modules/desktop/gnome.nix
touch modules/desktop/styling.nix

# Roles
touch modules/roles/creative.nix
touch modules/roles/gaming.nix
touch modules/roles/tablet.nix
touch modules/roles/virtualization.nix
touch modules/roles/web.nix
touch modules/roles/dev.nix

# Server
touch modules/server/cloudflare.nix
touch modules/server/forgejo.nix
touch modules/server/immich.nix
touch modules/server/jellyfin.nix
touch modules/server/copyparty.nix
touch modules/server/minecraft.nix

echo "Structure created successfully."
tree .