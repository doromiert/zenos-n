import argparse
import os
import sys
import shutil
import json
import random
import urllib.request
import zipfile
from urllib.parse import urlparse
from pathlib import Path
from datetime import datetime, timezone

# --- Configuration ---
XDG_DATA = Path(
    os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")
)
FPWA_ROOT = XDG_DATA / "firefoxpwa"
SITES_DIR = FPWA_ROOT / "sites"
PROFILES_DIR = FPWA_ROOT / "profiles"
GLOBAL_CONFIG = FPWA_ROOT / "config.json"
DESKTOP_DIR = XDG_DATA / "applications"

SCRIPT_DIR = Path(__file__).resolve().parent
# Path resolved in parts to maintain line limit
RESOURCE_REL = "../../resources/firefoxpwa/testprofile"
TEMPLATE_PROFILE = (SCRIPT_DIR / RESOURCE_REL).resolve()


def check_dependencies():
    """Verify firefoxpwa is available in the system PATH."""
    if not shutil.which("firefoxpwa"):
        print("## [ ! ] CRITICAL: 'firefoxpwa' binary not found in PATH.")
        sys.exit(1)


def resolve_canonical_url(url):
    """Resolve redirects to find the final landing URL."""
    try:
        print(f"[*] Resolving canonical URL for: {url}")
        req = urllib.request.Request(url, method="HEAD")
        # Split UA string to respect 79 char limit
        ua = (
            "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) "
            "Gecko/20100101 Firefox/115.0"
        )
        req.add_header("User-Agent", ua)
        with urllib.request.urlopen(req, timeout=5) as response:
            final_url = response.geturl()
            if final_url != url:
                print(f"    [>] Redirected to: {final_url}")
            return final_url
    except Exception:
        return url


def generate_ulid():
    """Generate a pseudo-ULID for unique identifiers."""
    base32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    first = random.choice("01234567")
    rest = "".join(random.choices(base32, k=25))
    return (first + rest).upper()


def install_extensions(profile_path, store_path, addons):
    """Install .xpi extensions from a local store into the profile."""
    if not store_path or not addons:
        return
    ext_dir = profile_path / "extensions"
    ext_dir.mkdir(exist_ok=True)
    store = Path(store_path)

    for name in addons:
        xpi = store / f"{name}.xpi"
        if not xpi.exists():
            continue
        try:
            with zipfile.ZipFile(xpi, 'r') as z:
                ext_id = None
                if 'manifest.json' in z.namelist():
                    with z.open('manifest.json') as m:
                        data = json.load(m)
                        # Extract extension ID with safe nesting
                        bss = data.get('browser_specific_settings', {})
                        gecko = bss.get('gecko', {})
                        app = data.get('applications', {}).get('gecko', {})
                        ext_id = gecko.get('id') or app.get('id')
                if not ext_id:
                    ext_id = xpi.stem if "@" in xpi.stem else None
                if ext_id:
                    shutil.copy2(xpi, ext_dir / f"{ext_id}.xpi")
                    print(f"    [+] Extension Installed: {ext_id}")
        except Exception:
            continue


def configure_ui_layout(user_js_path, layout_string):
    """Configure the Firefox UI layout via user_pref."""
    m = {
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
        i = item.strip().lower()
        if i in m:
            nav_bar.extend(m[i])

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
    js_state = json.dumps(state).replace('"', '\\"')
    with open(user_js_path, "a") as f:
        f.write(
            f'\nuser_pref("browser.uiCustomization.state", "{js_state}");\n'
        )


def create_pwa(name, input_url, icon_input, debug_mode, layout, store, addons):
    """Main logic for creating and registering the PWA."""
    url = resolve_canonical_url(input_url)
    site_id, profile_id = generate_ulid(), generate_ulid()
    site_path, profile_path = SITES_DIR / site_id, PROFILES_DIR / profile_id

    # Create Web Manifest
    domain = urlparse(url).netloc
    scheme = urlparse(url).scheme
    manifest = {
        "name": name, "short_name": name, "start_url": url,
        "scope": f"{scheme}://{domain}/",
        "display": "standalone", "background_color": "#000000",
        "theme_color": "#000000", "description": f"PWA for {name}",
        "icons": [{
            "src": "icon.png", "sizes": "512x512",
            "type": "image/png", "purpose": "any"
        }]
    }

    # Registry management
    registry = {"profiles": {}, "sites": {}}
    if GLOBAL_CONFIG.exists():
        with open(GLOBAL_CONFIG, "r") as f:
            registry = json.load(f)

    registry["profiles"][profile_id] = {
        "ulid": profile_id, "name": name, "sites": [site_id]
    }
    registry["sites"][site_id] = {
        "ulid": site_id, "profile": profile_id,
        "config": {"document_url": url, "manifest_url": url},
        "manifest": manifest
    }

    with open(GLOBAL_CONFIG, "w") as f:
        json.dump(registry, f, separators=(',', ':'))

    # Setup file structure
    site_path.mkdir(parents=True, exist_ok=True)
    with open(site_path / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)

    with open(site_path / "config.json", "w") as f:
        ts = datetime.now(timezone.utc).isoformat()
        json.dump({"usage": {"installed": ts}}, f)

    if icon_input and os.path.exists(icon_input):
        shutil.copy(icon_input, site_path / "icon.png")

    if profile_path.exists():
        shutil.rmtree(profile_path)

    shutil.copytree(
        TEMPLATE_PROFILE,
        profile_path,
        ignore=shutil.ignore_patterns('lock', '.parentlock')
    )

    # Clean profile of temporary cache/indices
    for f in ["compatibility.ini", "search.json.mozlz4", "startupCache"]:
        p = profile_path / f
        if p.exists():
            shutil.rmtree(p) if p.is_dir() else p.unlink()

    user_js = profile_path / "user.js"
    with open(user_js, "a") as f:
        f.write('\nuser_pref("toolkit.legacyUserProfileCustomizations'
                '.stylesheets", true);\n')
        f.write('user_pref("extensions.autoDisableScopes", 0);\n')

    if layout:
        configure_ui_layout(user_js, layout)
    if store and addons:
        install_extensions(profile_path, store, addons)

    # Generate Desktop Entry
    safe_name = "".join(c for c in name if c.isalnum()).lower()
    exec_cmd = f"env -u DRI_PRIME firefoxpwa site launch {site_id}"

    desktop_content = (
        "[Desktop Entry]\n"
        f"Name={name}\n"
        f"Exec={exec_cmd}\n"
        "Type=Application\n"
        "Terminal=false\n"
        f"Icon={site_path}/icon.png\n"
    )

    with open(DESKTOP_DIR / f"{safe_name}-fpwa.desktop", "w") as f:
        f.write(desktop_content)

    print(f"\n[SUCCESS] Registered: {name}")
    print(f"Launch Command: {exec_cmd}")


if __name__ == "__main__":
    check_dependencies()
    parser = argparse.ArgumentParser(
        description="Headless Firefox PWA generator script."
    )
    parser.add_argument("--name", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--icon")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--layout", default="arrows,refresh")
    parser.add_argument("--addon-store")
    parser.add_argument(
        "--addon",
        action="append",
        dest="addons",
        help="Specific addon names to install from store"
    )
    args = parser.parse_args()

    create_pwa(
        args.name,
        args.url,
        args.icon,
        args.debug,
        args.layout,
        args.addon_store,
        args.addons
    )
