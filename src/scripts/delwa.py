#!/usr/bin/env python3
"""
Firefox PWA Deletion Utility (delwa)
Removes a PWA by human-readable name, cleaning up profiles, config, and desktop entries.
"""

import argparse
import os
import sys
import shutil
import json
import re
from pathlib import Path

class Delwa:
    def __init__(self):
        self.xdg_data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        self.fpwa_root = self.xdg_data / "firefoxpwa"
        self.global_config = self.fpwa_root / "config.json"
        self.desktop_dir = self.xdg_data / "applications"

    def find_target(self, name):
        """Find site_id and desktop file by Name key."""
        if not self.desktop_dir.exists():
            return None, None
            
        # Regex to match exact Name line
        name_pattern = re.compile(f"^Name={re.escape(name)}$", re.MULTILINE)
        exec_pattern = re.compile(r"^Exec=.*firefoxpwa site launch ([A-Z0-9]+)", re.MULTILINE)
        
        for entry in self.desktop_dir.glob("*.desktop"):
            try:
                content = entry.read_text()
                if name_pattern.search(content):
                    match = exec_pattern.search(content)
                    if match:
                        return match.group(1), entry
            except Exception:
                continue
        return None, None

    def delete(self, name):
        print(f"[*] Searching for PWA: '{name}'...")
        site_id, desktop_path = self.find_target(name)
        
        if not site_id:
            print(f"## [ ! ] Error: No PWA found with Name='{name}' in {self.desktop_dir}")
            sys.exit(1)
            
        print(f"    > Found ID: {site_id}")
        print(f"    > Desktop File: {desktop_path.name}")

        # 1. Load Registry to find Profile ID
        registry = {"profiles": {}, "sites": {}}
        profile_id = None
        if self.global_config.exists():
            try:
                with open(self.global_config, "r") as f:
                    registry = json.load(f)
                    profile_id = registry.get("sites", {}).get(site_id, {}).get("profile")
            except Exception as e:
                print(f"## [ ! ] Config read error: {e}")

        # 2. Delete Profile Directory
        if profile_id:
            p_path = self.fpwa_root / "profiles" / profile_id
            if p_path.exists():
                print(f"    > Deleting Profile: {profile_id}")
                shutil.rmtree(p_path)
            
            # Remove from registry dict
            if profile_id in registry["profiles"]:
                del registry["profiles"][profile_id]

        # 3. Delete Site Directory
        s_path = self.fpwa_root / "sites" / site_id
        if s_path.exists():
            print(f"    > Deleting Site Config")
            shutil.rmtree(s_path)
        
        if site_id in registry["sites"]:
            del registry["sites"][site_id]

        # 4. Save Registry
        with open(self.global_config, "w") as f:
            json.dump(registry, f, separators=(',', ':'))

        # 5. Delete Desktop Entry
        if desktop_path.exists():
            print(f"    > removing .desktop entry")
            desktop_path.unlink()

        print(f"[SUCCESS] Deleted PWA: {name}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete Firefox PWA by Name")
    parser.add_argument("name", help="Exact name of the PWA (e.g. 'GitHub')")
    args = parser.parse_args()
    
    app = Delwa()
    app.delete(args.name)