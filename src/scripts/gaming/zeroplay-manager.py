import os
import json
import sys
import time
from pathlib import Path

# Try importing watchdog for daemon mode
try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    HAS_WATCHDOG = True
except ImportError:
    HAS_WATCHDOG = False

# -- INTERNAL KNOWLEDGE BASE --
# Maps directory names to emulator defaults.
PLATFORM_MAP = {
    "Switch":   {"default": "yuzu", "alts": ["ryujinx"]}, # 'yuzu' maps to Suyu wrapper
    "PS2":      {"default": "pcsx2",   "alts": []},
    "PS3":      {"default": "rpcs3",   "alts": []},
    "PS1":      {"default": "duckstation", "alts": []},
    "PSP":      {"default": "ppsspp",  "alts": []},
    "N64":      {"default": "simple64", "alts": ["mupen64plus"]},
    "GC":       {"default": "dolphin", "alts": []},
    "Wii":      {"default": "dolphin", "alts": []},
    "3DS":      {"default": "citra",   "alts": ["lime3ds"]},
    "Genesis":  {"default": "genesis-plus-gx", "alts": ["picodrive"]},
    "Saturn":   {"default": "beetle-saturn", "alts": []},
    "Dreamcast":{"default": "flycast", "alts": []},
    "Xbox":     {"default": "xemu",    "alts": []},
    "Xbox360":  {"default": "xenia",   "alts": []},
    "NES":      {"default": "mesen",   "alts": []},
    "SNES":     {"default": "bsnes",   "alts": []}
}

SUBFOLDERS = ["Config", "Saves", "Mods", "Cheats", "Updates", "Media", "Manuals"]

def scaffold_game(game_dir, platform):
    """Creates the standard directory tree and a clean override file."""
    # 1. Create Subfolders
    for folder in SUBFOLDERS:
        (game_dir / folder).mkdir(exist_ok=True)
    
    # 2. Generate config.json if missing
    config_path = game_dir / "config.json"
    if not config_path.exists():
        defaults = PLATFORM_MAP.get(platform, {})
        overrides = {
            "meta_game_title": game_dir.name,
            "meta_platform": platform,
            "emulator_override": None, # Use default: " + defaults.get("default", "unknown"),
            "custom_args": [],
            "compat_layer": None
        }
        
        try:
            with open(config_path, 'w') as f:
                json.dump(overrides, f, indent=4)
            print(f"[+] Scaffolding complete for: {game_dir.name}")
        except IOError as e:
            print(f"[!] Error writing config for {game_dir.name}: {e}")

def run_manager(base_path_str):
    """One-time scan of the library."""
    base_path = Path(base_path_str).expanduser()
    
    if not base_path.exists():
        print(f"[*] Games directory {base_path} not found. Skipping.")
        return

    print(f"[*] Scanning ZeroPlay Library at: {base_path}")

    for platform_dir in base_path.iterdir():
        # Ignore PC folder, hidden folders, and files at root
        if not platform_dir.is_dir() or platform_dir.name == "PC" or platform_dir.name.startswith("."):
            continue
            
        # Scan Games inside Platform folder
        for game_dir in platform_dir.iterdir():
            if game_dir.is_dir():
                # Heuristic: A valid game folder has a file that IS NOT config.json
                # We assume this file is the ROM.
                files = [f for f in game_dir.iterdir() if f.is_file() and f.name != "config.json"]
                
                if files:
                    scaffold_game(game_dir, platform_dir.name)

# -- DAEMON LOGIC --

if HAS_WATCHDOG:
    class ZeroPlayHandler(FileSystemEventHandler):
        def __init__(self, base_path):
            self.base_path = base_path

        def _process_event(self, event_path):
            path = Path(event_path)
            
            # Avoid processing scaffolding files to prevent loops
            if path.name == "config.json" or path.parent.name in SUBFOLDERS:
                return

            # Logic: If a file is added/modified, check its hierarchy
            # Structure: ~/Games / [Platform] / [Game] / [File]
            try:
                # We need to find which 'depth' matches our structure
                rel_path = path.relative_to(self.base_path)
                parts = rel_path.parts
                
                # We expect at least: Platform/Game/File (3 parts)
                if len(parts) >= 3:
                    platform_name = parts[0]
                    game_name = parts[1]
                    
                    if platform_name in PLATFORM_MAP and platform_name != "PC":
                        game_dir = self.base_path / platform_name / game_name
                        # Only scaffold if it's a file addition/move inside the game root
                        if path.parent == game_dir:
                            print(f"[*] Change detected in {game_name} ({platform_name}). Updating...")
                            scaffold_game(game_dir, platform_name)
            except ValueError:
                pass # Path not relative to base

        def on_created(self, event):
            if not event.is_directory:
                self._process_event(event.src_path)

        def on_moved(self, event):
            if not event.is_directory:
                self._process_event(event.dest_path)

    def run_daemon(base_path_str):
        path = Path(base_path_str).expanduser()
        if not path.exists():
            print(f"[!] Path {path} does not exist.")
            return

        # Initial scan to catch up
        run_manager(base_path_str)

        print(f"[*] Starting ZeroPlay Daemon on {path}...")
        event_handler = ZeroPlayHandler(path)
        observer = Observer()
        observer.schedule(event_handler, str(path), recursive=True)
        observer.start()
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            observer.stop()
        observer.join()

if __name__ == "__main__":
    # Args: [script, command, path]
    # Commands: scan, daemon
    
    if len(sys.argv) < 2:
        print("Usage: zeroplay-manager.py <scan|daemon> [path]")
        sys.exit(1)

    command = sys.argv[1]
    target = sys.argv[2] if len(sys.argv) > 2 else "~/Games"

    if command == "scan":
        run_manager(target)
    elif command == "daemon":
        if HAS_WATCHDOG:
            run_daemon(target)
        else:
            print("[!] Error: 'watchdog' module not found.")
            print("    Please add `python3Packages.watchdog` to your Nix environment.")
            sys.exit(1)
    else:
        print(f"Unknown command: {command}")