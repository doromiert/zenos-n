#!/usr/bin/env bash

set -e

echo "Initializing Nix configuration structure..."

mkdir -p src
mkdir -p src/hosts
mkdir -p src/scripts
mkdir -p resources

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
    cp -r --no-clobber templates/host/* "src/hosts/$host"
    find "src/hosts/$host" -type f -exec sed -i "s/PLACEHOLDER/$host/g" {} +
done

for user in "${users[@]}"; do
    mkdir -p "src/users/$user"
    cp -r --no-clobber templates/user/* "src/users/$user"
    find "src/users/$user" -type f -exec sed -i "s/PLACEHOLDER/$user/g" {} +
done

cp -r "templates/modules" "src" 

echo "Structure created successfully."
tree .