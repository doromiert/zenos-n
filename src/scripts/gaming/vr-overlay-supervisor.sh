#!/usr/bin/env bash

set -Eeuo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zenos-vr"
log_file="$state_dir/overlays.log"
wlx_pid=""
ovras_pid=""

mkdir -p "$state_dir"
exec >> >(tee -a "$log_file") 2>&1
exec 9>"$state_dir/overlay-supervisor.lock"

log() {
    printf '[%(%Y-%m-%d %H:%M:%S)T] %s\n' -1 "$*"
}

if ! flock -n 9; then
    log "Another overlay supervisor is already running."
    exit 0
fi

stop_overlays() {
    log "Stopping overlays for compositor transition."

    if [[ -n "$wlx_pid" ]]; then
        kill "$wlx_pid" 2>/dev/null || true
    fi
    if [[ -n "$ovras_pid" ]]; then
        kill "$ovras_pid" 2>/dev/null || true
    fi

    pkill -TERM -x wlx-overlay-s 2>/dev/null || true
    pkill -TERM -f '/ovr-advanced-settings-|/AdvancedSettings' 2>/dev/null || true
    wlx_pid=""
    ovras_pid=""
}

start_overlays() {
    stop_overlays
    sleep 1

    log "Starting wlx-overlay-s through steam-run."
    : > "$state_dir/wlx.log"
    steam-run wlx-overlay-s --openvr --replace >> "$state_dir/wlx.log" 2>&1 &
    wlx_pid=$!

    log "Starting OVR Advanced Settings."
    : > "$state_dir/ovras.log"
    ovr-advanced-settings >> "$state_dir/ovras.log" 2>&1 &
    ovras_pid=$!
}

shutdown() {
    trap - EXIT INT TERM
    stop_overlays
    exit 0
}
trap stop_overlays EXIT
trap shutdown INT TERM

log "Overlay supervisor started."
while true; do
    candidate_pid=""
    stable_samples=0

    while (( stable_samples < 15 )); do
        pid="$(pgrep -n -x vrcompositor || true)"
        if [[ -n "$pid" && "$pid" == "$candidate_pid" ]]; then
            ((stable_samples += 1))
        elif [[ -n "$pid" ]]; then
            candidate_pid="$pid"
            stable_samples=1
            log "Compositor candidate detected: PID $candidate_pid"
        else
            candidate_pid=""
            stable_samples=0
        fi
        sleep 1
    done

    log "Compositor PID $candidate_pid is stable."
    start_overlays

    overlay_failed=false
    while [[ "$(pgrep -n -x vrcompositor || true)" == "$candidate_pid" ]]; do
        if ! kill -0 "$wlx_pid" 2>/dev/null || ! kill -0 "$ovras_pid" 2>/dev/null; then
            log "An overlay exited; retrying after the compositor stability check."
            overlay_failed=true
            break
        fi
        sleep 1
    done

    if [[ "$overlay_failed" == false ]]; then
        log "Compositor PID changed or stopped."
    fi
    stop_overlays
    sleep 2
done
