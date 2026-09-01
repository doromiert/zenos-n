#!/usr/bin/env bash

set -Eeuo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zenos-vr"
log_file="$state_dir/launcher.log"
steam_root="${STEAM_ROOT:-$HOME/.local/share/Steam}"
steamvr_root="${STEAMVR_ROOT:-$steam_root/steamapps/common/SteamVR}"
openvr_paths="${XDG_CONFIG_HOME:-$HOME/.config}/openvr/openvrpaths.vrpath"
steamvr_settings="$steam_root/config/steamvr.vrsettings"

mkdir -p "$state_dir"
exec >> >(tee -a "$log_file") 2>&1
exec 9>"$state_dir/launcher.lock"

log() {
    printf '[%(%Y-%m-%d %H:%M:%S)T] %s\n' -1 "$*"
}

if ! flock -n 9; then
    log "Another VR launch is already in progress."
    exit 0
fi

require_file() {
    if [[ ! -f "$1" ]]; then
        log "Required SteamVR file is missing: $1"
        exit 1
    fi
}

repair_json() {
    local file="$1"
    local tmp
    shift

    if [[ ! -f "$file" ]]; then
        log "Skipping missing configuration: $file"
        return
    fi

    tmp="$(mktemp "${file}.zenos-vr.XXXXXX")"
    if ! jq "$@" "$file" > "$tmp"; then
        rm -f "$tmp"
        log "Failed to update JSON configuration: $file"
        exit 1
    fi

    if cmp -s "$file" "$tmp"; then
        rm -f "$tmp"
        return
    fi

    cp -n --preserve=mode,timestamps "$file" "${file}.zenos-vr-backup"
    chmod --reference="$file" "$tmp"
    mv "$tmp" "$file"
    log "Repaired configuration: $file"
}

repair_openvr_registration() {
    local dashboard
    local alvr_root
    local driver

    dashboard="$(readlink -f "$(command -v alvr_dashboard)")"
    alvr_root="${dashboard%/bin/alvr_dashboard}"
    if [[ -d "$alvr_root/lib64/alvr" ]]; then
        driver="$alvr_root/lib64/alvr"
    else
        driver="$alvr_root/lib/alvr"
    fi

    # $driver below is a jq variable, not a shell expansion.
    # shellcheck disable=SC2016
    repair_json "$openvr_paths" --arg driver "$driver" '
        .external_drivers = (
            ((.external_drivers // [])
                | map(select(((contains("-alvr-") and endswith("/alvr"))) | not)))
            + [$driver]
            | unique
        )
    '
}

repair_steamvr_settings() {
    repair_json "$steamvr_settings" '
        .driver_vrlink.enable = false |
        .steamvr.disableAsync = true |
        .steamvr.enableLinuxVulkanAsync = false |
        .steamvr.preferredRefreshRate = 120.0
    '
}

patch_rpath() {
    local file="$1"
    local expected="$2"
    local force_rpath="${3:-false}"
    local current

    require_file "$file"
    current="$(patchelf --print-rpath "$file")"

    if [[ "$current" != "$expected" ]] || { [[ "$force_rpath" == true ]] && ! readelf -d "$file" | grep -q '(RPATH)'; }; then
        log "Repairing RPATH: ${file#"$steamvr_root"/}"
        if [[ "$force_rpath" == true ]]; then
            patchelf --force-rpath --set-rpath "$expected" "$file"
        else
            patchelf --set-rpath "$expected" "$file"
        fi
    fi
}

repair_steamvr() {
    local compositor="$steamvr_root/bin/linux64/vrcompositor-launcher"
    local qt_conf="$steamvr_root/bin/linux64/qt.conf"
    local capability

    require_file "$compositor"
    capability="$(getcap "$compositor" || true)"
    if [[ "$capability" != *"cap_sys_nice=eip"* ]]; then
        log "SteamVR compositor capability is missing; requesting elevation."
        /run/wrappers/bin/pkexec @setcap@ CAP_SYS_NICE=eip "$compositor"
    fi

    patch_rpath "$steamvr_root/bin/linux64/restarthelper" "\$ORIGIN/qt/lib"
    patch_rpath "$steamvr_root/bin/linux64/vrmonitor" "\$ORIGIN:\$ORIGIN/qt/lib"
    patch_rpath "$steamvr_root/bin/linux64/qt/plugins/platforms/libqxcb.so" "@libSM@:@libICE@:\$ORIGIN/../../lib"
    patch_rpath "$steamvr_root/bin/linux64/qt/lib/libQt5XcbQpa.so.5" "@libSM@:@libICE@:\$ORIGIN"
    patch_rpath "$steamvr_root/bin/vrwebhelper/linux64/libcef.so" "\$ORIGIN:@nss@:@nspr@" true

    if [[ ! -f "$qt_conf" ]] || ! grep -qxF 'Plugins = qt/plugins' "$qt_conf"; then
        log "Repairing SteamVR Qt plugin configuration."
        printf '[Paths]\nPlugins = qt/plugins\n' > "$qt_conf"
    fi
}

restart_overlay_supervisor() {
    local variable
    local -a graphical_environment=()

    for variable in \
        DISPLAY \
        WAYLAND_DISPLAY \
        XAUTHORITY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE; do
        if [[ -v "$variable" ]]; then
            graphical_environment+=("$variable")
        fi
    done

    if (( ${#graphical_environment[@]} > 0 )); then
        systemctl --user import-environment "${graphical_environment[@]}"
    fi
    systemctl --user restart zenos-vr-overlays.service
}

wait_for_stable_process() {
    local process="$1"
    local timeout="$2"
    local stable_for="${3:-1}"
    local elapsed=0
    local stable=0
    local last_pid=""
    local pid=""

    while (( elapsed < timeout )); do
        pid="$(pgrep -n -x "$process" || true)"
        if [[ -n "$pid" && "$pid" == "$last_pid" ]]; then
            ((stable += 1))
            if (( stable >= stable_for )); then
                return 0
            fi
        elif [[ -n "$pid" ]]; then
            last_pid="$pid"
            stable=1
        else
            last_pid=""
            stable=0
        fi
        sleep 1
        ((elapsed += 1))
    done

    log "Timed out waiting for $process after ${timeout}s."
    return 1
}

start_detached() {
    nohup "$@" >> "$log_file" 2>&1 &
}

log "Preparing the VR stack."
repair_openvr_registration
repair_steamvr_settings
repair_steamvr
restart_overlay_supervisor

if ! pgrep -x alvr_dashboard > /dev/null; then
    log "Starting ALVR dashboard."
    start_detached alvr_dashboard
fi
wait_for_stable_process alvr_dashboard 20

if ! pgrep -x vrmonitor > /dev/null && ! pgrep -x vrserver > /dev/null; then
    log "Starting SteamVR."
    start_detached steam -applaunch 250820
fi

log "VR stack startup dispatched; overlay lifecycle is managed by zenos-vr-overlays.service."
