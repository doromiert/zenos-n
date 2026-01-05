# Target the directory relative to this script or provide path
PROFILE_DIR=${1:-"./resources/firefoxpwa/templateprofile"}

if [ ! -d "$PROFILE_DIR" ]; then
    echo "Error: Directory $PROFILE_DIR does not exist."
    exit 1
fi

echo "Cleaning up Firefox profile template: $PROFILE_DIR"

# 1. Essential Protection: Ensure 'chrome' directory is safe
if [ ! -d "$PROFILE_DIR/chrome" ]; then
    echo "Warning: 'chrome' directory not found. This template might not have custom CSS."
fi

# 2. Define lists of garbage to delete
# These are directories that hold heavy cache or site-specific data
STALE_DIRS=(
    "cache2"
    "jumpListCache"
    "startupCache"
    "entries"
    "storage"
    "bookmarkbackups"
    "datareporting"
    "gmp-gmpopenh264"
    "gmp-widevinecdm"
    "pending_updates"
    "shader-cache"
    "threadsafe_log.txt.0.35417"
    "thumbnails"
    "sessionstore-backups"
    "minidumps"
    "saved-telemetry-pings"
)

# These are specific files that store history, sessions, or telemetry
STALE_FILES=(
    "addonStartup.json.lz4"
    "addons.json"
    "AlternateServices.bin"
    "broadcast-listeners.json"
    "compatibility.ini"
    "containers.json"
    "content-prefs.sqlite"
    "cookies.sqlite"
    "cookies.sqlite-shm"
    "cookies.sqlite-wal"
    "extensions.json"
    "favicons.sqlite"
    "favicons.sqlite-shm"
    "favicons.sqlite-wal"
    "formhistory.sqlite"
    "history.sqlite"
    "key4.db"
    "logins.json"
    "permissions.sqlite"
    "places.sqlite"
    "places.sqlite-shm"
    "places.sqlite-wal"
    "prefs.js"
    "protections.sqlite"
    "search.json.mozlz4"
    "sessionCheckpoints.json"
    "sessionstore.jsonlz4"
    "siteSecurityServiceState.txt"
    "storage.sqlite"
    "telemetry_modules_ping.json"
    "times.json"
    "webappsstore.sqlite"
    "xulstore.json"
)

# 3. Execution
echo "Removing stateful directories..."
for dir in "${STALE_DIRS[@]}"; do
    rm -rf "$PROFILE_DIR/$dir"
done

echo "Removing stateful files..."
for file in "${STALE_FILES[@]}"; do
    rm -f "$PROFILE_DIR/$file"
done

# 4. Remove generic SQLite temp files and log files
find "$PROFILE_DIR" -name "*.sqlite-shm" -delete
find "$PROFILE_DIR" -name "*.sqlite-wal" -delete
find "$PROFILE_DIR" -name "*.log" -delete

# 5. Handle the random hex sqlite files seen in tree.txt (e.g., 17418329.sqlite)
find "$PROFILE_DIR" -maxdepth 1 -regex ".*/[0-9a-f]+\.sqlite.*" -delete

echo "Done. Your template is now clean and ready for pwamaker.py."
echo "Kept: $(du -sh "$PROFILE_DIR")"