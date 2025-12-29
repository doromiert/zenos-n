#!/usr/bin/env bash

set -e

echo "Initializing Nix configuration structure..."

mkdir -p src
mkdir -p resources
mkdir -p src/modules/core
mkdir -p src/modules/desktop
mkdir -p src/modules/roles
mkdir -p src/modules/server
mkdir -p src/hosts

touch flake.nix

hosts=(
    
    "doromi-tul-2"
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
    mkdir -p "src/hosts/$host"
    touch "src/hosts/$host/main.nix"
    touch "src/hosts/$host/hardware.nix"
    touch "src/hosts/$host/syncthing.nix"
done

for user in "${users[@]}"; do
    mkdir -p "src/users/$user"
    cp -r templates/user "src/users/$user"
    find "src/users/$user" -type f -exec sed -i "s/PLACEHOLDER/$user/g" {} +
done

# Core
touch src/modules/core/branding.nix
touch src/modules/core/security.nix
touch src/modules/core/shell.nix
touch src/modules/core/syncthing.nix # will contain all devices we want to use
touch src/modules/core/misc-services.nix

# Desktop
touch src/modules/desktop/gnome.nix
touch src/modules/desktop/styling.nix

# Roles
touch src/modules/roles/creative.nix
touch src/modules/roles/gaming.nix
touch src/modules/roles/tablet.nix
touch src/modules/roles/virtualization.nix
touch src/modules/roles/web.nix
touch src/modules/roles/dev.nix

# Server
touch src/modules/server/cloudflare.nix
touch src/modules/server/forgejo.nix
touch src/modules/server/immich.nix
touch src/modules/server/jellyfin.nix
touch src/modules/server/copyparty.nix
touch src/modules/server/minecraft.nix

echo "Structure created successfully."
tree .