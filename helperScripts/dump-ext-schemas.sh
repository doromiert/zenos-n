#!/usr/bin/env bash

OUT_DIR="/tmp/extension_schemas"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "Scraping Nix profiles for schemas..."

# Search system and user profiles
PROFILES=("/run/current-system/sw" "$HOME/.nix-profile" "/etc/profiles/per-user/$USER")

for profile in "${PROFILES[@]}"; do
    if [ -d "$profile" ]; then
        # Find all xml files within gnome-shell extension paths
        find -L "$profile" -path "*/gnome-shell/extensions/*/schemas/*.xml" 2>/dev/null | while read -r schema; do
            # Extract UUID from path (3 levels up from the file)
            UUID=$(echo "$schema" | rev | cut -d'/' -f3 | rev)
            FILE_NAME=$(basename "$schema")
            
            ln -sf "$schema" "$OUT_DIR/${UUID}_${FILE_NAME}"
        done
    fi
done

if [ "$(ls -A $OUT_DIR)" ]; then
    echo "Success! Symlinks created in: $OUT_DIR"
    ls -1 "$OUT_DIR"
else
    echo "## [ ! ] Error: No schemas found."
    echo "Try running: find /nix/store -name '*gschema.xml' | grep gnome-shell"
fi