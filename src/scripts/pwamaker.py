#!/usr/bin/env python3
"""
Firefox PWA Generator (Modular Refactor)
Generates isolated Firefox profiles and desktop entries for Progressive Web Apps.
Designed for integration with NixOS/Linux environments.
"""

import argparse
import os
import sys
import shutil
import json
import random
import re
import urllib.request
from urllib.parse import urlparse
from pathlib import Path
from datetime import datetime, timezone

# --- 1. CONFIGURATION & CONTEXT ---

class PWAContext:
    """
    Manages global configuration, paths, and environment context.
    """
    def __init__(self, explicit_template_path=None):
        self.xdg_data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        self.fpwa_root = self.xdg_data / "firefoxpwa"
        self.sites_dir = self.fpwa_root / "sites"
        self.profiles_dir = self.fpwa_root / "profiles"
        self.global_config = self.fpwa_root / "config.json"
        self.desktop_dir = self.xdg_data / "applications"
        
        self.template_profile = None
        
        if explicit_template_path:
            p = Path(explicit_template_path)
            if p.exists():
                self.template_profile = p
        
        if not self.template_profile:
            script_dir = Path(__file__).resolve().parent
            candidates = [
                script_dir / "../../resources/firefoxpwa/testprofile",
                script_dir / "resources/testprofile",
                Path("/usr/share/firefoxpwa/testprofile")
            ]
            self.template_profile = next((p for p in candidates if p.exists()), None)

        if not self.template_profile:
            print(f"## [ ! ] CRITICAL: Template profile not found.")
            sys.exit(1)

    @staticmethod
    def generate_ulid():
        base32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        first = random.choice("01234567")
        rest = "".join(random.choices(base32, k=25))
        return (first + rest).upper()

# --- 2. PROFILE MANAGEMENT ---

class ProfileManager:
    def __init__(self, context: PWAContext):
        self.ctx = context

    def prepare_profile(self, profile_id: str):
        dest = self.ctx.profiles_dir / profile_id
        
        if dest.exists():
            shutil.rmtree(dest)
        
        shutil.copytree(
            self.ctx.template_profile, 
            dest, 
            ignore=shutil.ignore_patterns('lock', '.parentlock'),
            dirs_exist_ok=True 
        )
        
        os.chmod(dest, 0o755)

        for root, dirs, files in os.walk(dest):
            for d in dirs:
                os.chmod(os.path.join(root, d), 0o755)
            for f in files:
                os.chmod(os.path.join(root, f), 0o644)
        
        for trash in ["compatibility.ini", "search.json.mozlz4", "startupCache"]:
            p = dest / trash
            if p.exists():
                shutil.rmtree(p) if p.is_dir() else p.unlink()
        
        return dest

    def install_extensions(self, profile_path: Path, addons: list):
        if not addons:
            return

        ext_dir = profile_path / "extensions"
        ext_dir.mkdir(exist_ok=True)

        print(f"[*] Installing {len(addons)} extensions...")
        for addon_def in addons:
            try:
                if ":" not in addon_def:
                    continue
                    
                ext_id, ext_path = addon_def.split(":", 1)
                src = Path(ext_path)
                
                if not src.exists():
                    print(f"    [!] Extension file missing: {src}")
                    continue

                dest = ext_dir / f"{ext_id}.xpi"
                shutil.copy2(src, dest)
                os.chmod(dest, 0o644)
            except Exception as e:
                print(f"    [!] Failed to install {addon_def}: {e}")

    def configure_user_js(self, profile_path: Path, layout_str: str):
        user_js = profile_path / "user.js"
        prefs = [
            'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);',
            'user_pref("extensions.autoDisableScopes", 0);',
            'user_pref("browser.uidensity", 1);'
        ]
        if layout_str:
            layout_json = self._generate_layout_json(layout_str)
            prefs.append(f'user_pref("browser.uiCustomization.state", "{layout_json}");')

        with open(user_js, "a") as f:
            f.write("\n".join(prefs) + "\n")

    def _generate_layout_json(self, layout_string: str) -> str:
        mapping = {
            "arrows": ["back-button", "forward-button"],
            "back": ["back-button"],
            "forward": ["forward-button"],
            "refresh": ["stop-reload-button"],
            "reload": ["stop-reload-button"],
            "home": ["home-button"],
            "spacer": ["spacer"],
            "spring": ["spring"],
        }
        nav_bar = []
        for item in layout_string.split(","):
            key = item.strip().lower()
            if key in mapping:
                nav_bar.extend(mapping[key])
        state = {
            "placements": {
                "widget-overflow-fixed-list": [],
                "nav-bar": nav_bar,
                "toolbar-menubar": ["menubar-items"],
                "TabsToolbar": ["tabbrowser-tabs", "new-tab-button"],
                "PersonalToolbar": ["personal-bookmarks"],
                "unified-extensions-area": []
            },
            "seen": nav_bar + ["developer-button"],
            "dirtyAreaCache": ["nav-bar", "unified-extensions-area"],
            "currentVersion": 20,
            "newElementCount": 0
        }
        return json.dumps(state).replace('"', '\\"')

# --- 3. PWA ORCHESTRATION ---

class PWABuilder:
    def __init__(self, context: PWAContext):
        self.ctx = context
        self.pm = ProfileManager(context)

    def resolve_url(self, url: str) -> str:
        try:
            req = urllib.request.Request(url, method="HEAD")
            req.add_header("User-Agent", "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36")
            with urllib.request.urlopen(req, timeout=5) as response:
                return response.geturl()
        except Exception:
            return url

    def find_existing_app(self, name):
        """
        Scans .local/share/applications for a .desktop file with Name={name}.
        Returns (site_id, desktop_path) or (None, None).
        """
        if not self.ctx.desktop_dir.exists():
            return None, None
            
        name_pattern = re.compile(f"^Name={re.escape(name)}$", re.MULTILINE)
        exec_pattern = re.compile(r"^Exec=.*firefoxpwa site launch ([A-Z0-9]+)", re.MULTILINE)
        
        for entry in self.ctx.desktop_dir.glob("*.desktop"):
            try:
                content = entry.read_text()
                if name_pattern.search(content):
                    match = exec_pattern.search(content)
                    if match:
                        return match.group(1), entry
            except Exception:
                continue
        return None, None

    def get_profile_id_for_site(self, site_id):
        """Retrieve profile ID from global config using site ID."""
        if not self.ctx.global_config.exists():
            return None
        try:
            with open(self.ctx.global_config, "r") as f:
                data = json.load(f)
                return data.get("sites", {}).get(site_id, {}).get("profile")
        except:
            return None

    def register_in_global_config(self, site_id, profile_id, name, url, manifest):
        registry = {"profiles": {}, "sites": {}}
        if self.ctx.global_config.exists():
            try:
                with open(self.ctx.global_config, "r") as f:
                    registry = json.load(f)
            except json.JSONDecodeError:
                pass

        registry["profiles"][profile_id] = {
            "ulid": profile_id, "name": name, "sites": [site_id]
        }
        registry["sites"][site_id] = {
            "ulid": site_id, "profile": profile_id,
            "config": {"document_url": url, "manifest_url": url},
            "manifest": manifest
        }

        with open(self.ctx.global_config, "w") as f:
            json.dump(registry, f, separators=(',', ':'))

    def update_existing(self, site_id, desktop_path, name, url, icon, addons):
        print(f"[~] Found existing app '{name}' (ID: {site_id}). Updating...")
        
        final_url = self.resolve_url(url)
        site_path = self.ctx.sites_dir / site_id
        
        # 1. Update Manifest
        if site_path.exists():
            manifest_path = site_path / "manifest.json"
            if manifest_path.exists():
                with open(manifest_path, "r+") as f:
                    data = json.load(f)
                    data["start_url"] = final_url
                    data["scope"] = f"{urlparse(final_url).scheme}://{urlparse(final_url).netloc}/"
                    f.seek(0)
                    json.dump(data, f, indent=2)
                    f.truncate()
        
        # 2. Update Icon
        if icon and os.path.exists(icon):
            shutil.copy(icon, site_path / "icon.png")
            
        # 3. Update Extensions (Non-destructive to profile data)
        profile_id = self.get_profile_id_for_site(site_id)
        if profile_id:
            profile_path = self.ctx.profiles_dir / profile_id
            if profile_path.exists() and addons:
                self.pm.install_extensions(profile_path, addons)
        
        # 4. Refresh Registry (to ensure URL match)
        # We need the manifest data we just wrote/calculated
        domain = urlparse(final_url).netloc
        scheme = urlparse(final_url).scheme
        manifest = {
            "name": name, "short_name": name, "start_url": final_url,
            "scope": f"{scheme}://{domain}/",
            "display": "standalone", "background_color": "#000000",
            "theme_color": "#000000", "description": f"PWA for {name}",
            "icons": [{"src": "icon.png", "sizes": "512x512", "type": "image/png", "purpose": "any"}]
        }
        if profile_id:
             self.register_in_global_config(site_id, profile_id, name, final_url, manifest)

        print(f"[OK] Updated {name} successfully.")

    def create(self, name, url, icon, layout, addons):
        print(f"\n=== Deploying PWA: {name} ===")
        
        # Redundancy Check
        existing_id, existing_path = self.find_existing_app(name)
        if existing_id:
            self.update_existing(existing_id, existing_path, name, url, icon, addons)
            return

        # --- New Creation Flow ---
        final_url = self.resolve_url(url)
        site_id = self.ctx.generate_ulid()
        profile_id = self.ctx.generate_ulid()
        
        site_path = self.ctx.sites_dir / site_id
        site_path.mkdir(parents=True, exist_ok=True)
        
        domain = urlparse(final_url).netloc
        scheme = urlparse(final_url).scheme
        manifest = {
            "name": name, "short_name": name, "start_url": final_url,
            "scope": f"{scheme}://{domain}/",
            "display": "standalone", "background_color": "#000000",
            "theme_color": "#000000", "description": f"PWA for {name}",
            "icons": [{"src": "icon.png", "sizes": "512x512", "type": "image/png", "purpose": "any"}]
        }
        
        with open(site_path / "manifest.json", "w") as f:
            json.dump(manifest, f, indent=2)
            
        with open(site_path / "config.json", "w") as f:
            ts = datetime.now(timezone.utc).isoformat()
            json.dump({"usage": {"installed": ts}}, f)

        if icon and os.path.exists(icon):
            shutil.copy(icon, site_path / "icon.png")

        self.register_in_global_config(site_id, profile_id, name, final_url, manifest)

        print("[*] Generating Profile...")
        profile_path = self.pm.prepare_profile(profile_id)
        self.pm.configure_user_js(profile_path, layout)
        if addons:
            self.pm.install_extensions(profile_path, addons)

        self.create_desktop_entry(name, site_id, site_path)
        print(f"[SUCCESS] {name} deployed. Site ID: {site_id}")

    def create_desktop_entry(self, name, site_id, site_path):
        safe_name = "".join(c for c in name if c.isalnum()).lower()
        exec_cmd = f"env -u DRI_PRIME firefoxpwa site launch {site_id}"
        
        content = (
            "[Desktop Entry]\n"
            f"Name={name}\n"
            f"Exec={exec_cmd}\n"
            "Type=Application\n"
            "Terminal=false\n"
            f"Icon={site_path}/icon.png\n"
            "Categories=Network;WebBrowser;\n"
        )
        
        out_path = self.ctx.desktop_dir / f"{safe_name}-fpwa.desktop"
        self.ctx.desktop_dir.mkdir(parents=True, exist_ok=True)
        
        with open(out_path, "w") as f:
            f.write(content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Modular Firefox PWA Generator")
    parser.add_argument("--name", required=True, help="Display name of the PWA")
    parser.add_argument("--url", required=True, help="Target URL")
    parser.add_argument("--icon", help="Path to icon file")
    parser.add_argument("--layout", default="arrows,refresh", help="Comma-separated navbar items")
    parser.add_argument("--template", help="Explicit path to template profile")
    parser.add_argument("--addon", action="append", dest="addons", help="Extension in format 'ID:/path/to/file.xpi'")
    
    args = parser.parse_args()
    
    if not shutil.which("firefoxpwa"):
        print("## [ ! ] CRITICAL: 'firefoxpwa' binary missing.")
        sys.exit(1)
        
    ctx = PWAContext(explicit_template_path=args.template)
    builder = PWABuilder(ctx)
    builder.create(args.name, args.url, args.icon, args.layout, args.addons)
