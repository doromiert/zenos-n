#!/usr/bin/env python3
import os
import glob
import re

# Configuration
PROFILE_DIR = "/nix/var/nix/profiles/"
# Assumes the ESP is mounted at /boot. Change if mounted at /boot/efi
ESP_MOUNT = "/boot" 
OUTPUT_FILE = os.path.join(ESP_MOUNT, "EFI/refind/zenos-entries.conf")
ICON_PATH = "/EFI/refind/themes/refind-ambience-hack/icons/os_zenos.png"

# Flags from your manual config that might not be in the generation's kernel-params
# Use this to enforce your hardware specific settings
FORCED_OPTIONS = "amd_iommu=on iommu=pt preempt=full threadirqs amd_pstate=active splash loglevel=4 lsm=landlock,yama,bpf"

def get_gens():
    """Finds top 5 most recent system generations."""
    links = glob.glob(os.path.join(PROFILE_DIR, "system-*-link"))
    if not links: return []
    links.sort(key=lambda x: int(re.search(r'system-(\d+)-link', x).group(1)), reverse=True)
    return links[:5]

def resolve_esp_path(store_link_path, file_type):
    """
    Resolves a /nix/store link to a physical file on the ESP.
    NixOS typically installs kernels to ESP as: /EFI/nixos/{HASH}-{name}.efi
    """
    try:
        # 1. Get the actual store path (e.g., /nix/store/58rgh...-linux-zen.../bzImage)
        real_path = os.readlink(store_link_path)
        
        # 2. Extract the directory name (e.g., 58rgh...-linux-zen...)
        store_dir_name = os.path.basename(os.path.dirname(real_path))
        
        # 3. Construct the filename pattern found in your tree output
        # Tree: 58rgh...-linux-zen-6.18.2-bzImage.efi
        suffix = "-bzImage.efi" if file_type == "kernel" else "-initrd.efi"
        
        # 4. Search for this file on the ESP
        # We search by hash to be robust against slight naming variations
        hash_part = store_dir_name.split("-")[0]
        search_pattern = os.path.join(ESP_MOUNT, "EFI/nixos", f"*{hash_part}*{suffix}")
        matches = glob.glob(search_pattern)
        
        if matches:
            # Return path relative to ESP root (remove /boot)
            return matches[0].replace(ESP_MOUNT, "")
            
    except Exception as e:
        print(f"Warning: Could not resolve ESP path for {store_link_path}: {e}")
    
    # Fallback: Return the direct store path. 
    # This works ONLY if rEFInd has valid FS drivers for the root partition.
    print(f"Fallback: Using store path for {file_type} (File not found in /EFI/nixos/)")
    return store_link_path

def generate_config():
    gens = get_gens()
    if not gens:
        print("No generations found in profile dir.")
        return

    print(f"Generating {OUTPUT_FILE} for {len(gens)} generations...")

    with open(OUTPUT_FILE, "w") as f:
        f.write(f'menuentry "ZenOS" {{\n')
        f.write(f'    icon {ICON_PATH}\n')
        
        for i, gen in enumerate(gens):
            gen_num = re.search(r'system-(\d+)-link', gen).group(1)
            target = os.readlink(gen)
            
            kernel_link = os.path.join(target, "kernel")
            initrd_link = os.path.join(target, "initrd")
            init_path = os.path.join(target, "init")
            
            # Resolve physical files
            loader_final = resolve_esp_path(kernel_link, "kernel")
            initrd_final = resolve_esp_path(initrd_link, "initrd")
            
            # Read built-in params
            params_file = os.path.join(target, "kernel-params")
            params = ""
            if os.path.exists(params_file):
                with open(params_file, "r") as p:
                    params = p.read().strip()

            # Combine init path, built-in params, and forced hardware flags
            # Note: We append FORCED_OPTIONS. Linux kernel usually takes the last value if duplicates exist,
            # but usually these flags are unique enough.
            full_options = f"init={init_path} {params} {FORCED_OPTIONS}"

            # Main Entry (First Gen)
            if i == 0:
                f.write(f'    loader {loader_final}\n')
                f.write(f'    initrd {initrd_final}\n')
                f.write(f'    options "{full_options}"\n')
            
            # Submenus
            f.write(f'    submenuentry "Generation {gen_num}" {{\n')
            f.write(f'        loader {loader_final}\n')
            f.write(f'        initrd {initrd_final}\n')
            f.write(f'        options "{full_options}"\n')
            f.write(f'    }}\n')
            
        f.write(f'}}\n')
    print("Done.")

if __name__ == "__main__":
    generate_config()