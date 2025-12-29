#!/usr/bin/env python3
import os
import glob
import re

# Paths
PROFILE_DIR = "/nix/var/nix/profiles/"
OUTPUT_FILE = "/boot/EFI/refind/zenos-entries.conf"
ICON_PATH = "/EFI/refind/icons/os_zenos.png"

def get_gens():
    # Find all system-*-link files
    links = glob.glob(os.path.join(PROFILE_DIR, "system-*-link"))
    # Sort by generation number descending
    links.sort(key=lambda x: int(re.search(r'system-(\d+)-link', x).group(1)), reverse=True)
    return links[:5]

def generate_config():
    gens = get_gens()
    if not gens:
        return

    with open(OUTPUT_FILE, "w") as f:
        f.write(f'menuentry "ZenOS" {{\n')
        f.write(f'    icon {ICON_PATH}\n')
        
        for i, gen in enumerate(gens):
            gen_num = re.search(r'system-(\d+)-link', gen).group(1)
            target = os.readlink(gen)
            
            kernel = os.path.join(target, "kernel")
            initrd = os.path.join(target, "initrd")
            init = os.path.join(target, "init")
            
            # Read kernel params from the generation
            with open(os.path.join(target, "kernel-params"), "r") as p:
                params = p.read().strip()

            entry_type = "submenuentry" if i > 0 else "loader"
            
            # The first generation is the default 'loader' for the main icon
            if i == 0:
                f.write(f'    loader {kernel}\n')
                f.write(f'    initrd {initrd}\n')
                f.write(f'    options "init={init} {params}"\n')
            
            # All generations (including current) get a submenu entry for the F2 menu
            f.write(f'    submenuentry "Generation {gen_num}" {{\n')
            f.write(f'        loader {kernel}\n')
            f.write(f'        initrd {initrd}\n')
            f.write(f'        options "init={init} {params}"\n')
            f.write(f'    }}\n')
            
        f.write(f'}}\n')

if __name__ == "__main__":
    generate_config()