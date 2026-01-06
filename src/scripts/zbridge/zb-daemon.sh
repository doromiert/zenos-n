#!/usr/bin/env bash
# zb-daemon - Background Service
# Handled by systemd. DO NOT RUN DIRECTLY.

CONFIG_DIR="$HOME/.config/zbridge"
CONFIG_FILE="$CONFIG_DIR/state.conf"

# --- Defaults ---
PHONE_IP=""
CAM_FACING="back" 
BROADCAST_PORT="5000"

# --- Customizable Node Names (Default to zbridge standard) ---
# These can be overridden in state.conf
NODE_IN="zbin"
NODE_OUT="zbout"
NODE_MIC="zmic"

# --- Runtime PIDs ---
SCRCPY_PID=""
BROADCAST_PID=""
ROUTING_PID=""
RELOAD_REQUESTED=false

# --- Cleanup Logic (Standard PipeWire only) ---
destroy_zbridge_nodes() {
    echo ":: [Cleanup] Wiping residual ZeroBridge nodes..."
    # Fetch all node names and filter for ours, then destroy by name
    # We use pw-link -ports to get names reliably without 
    for name in "$NODE_IN" "$NODE_OUT" "$NODE_MIC"; do
        if pw-link --ports | grep -q "^$name:"; then
            echo ":: [Cleanup] Destroying $name..."
            pw-cli destroy "$name" >/dev/null 2>&1
        fi
    done
}

cleanup() {
    echo ":: [Daemon] Shutting down..."
    [[ -n "$ROUTING_PID" ]] && kill "$ROUTING_PID" 2>/dev/null
    [[ -n "$BROADCAST_PID" ]] && kill "$BROADCAST_PID" 2>/dev/null
    [[ -n "$SCRCPY_PID" ]] && kill "$SCRCPY_PID" 2>/dev/null
    destroy_zbridge_nodes
    exit 0
}

reload_config() {
    echo ":: [Daemon] Reloading configuration (SIGHUP)..."
    RELOAD_REQUESTED=true
    [[ -n "$SCRCPY_PID" ]] && kill -TERM "$SCRCPY_PID" 2>/dev/null
    [[ -n "$BROADCAST_PID" ]] && kill "$BROADCAST_PID" 2>/dev/null
    force_route_loop
}

trap cleanup SIGINT SIGTERM EXIT
trap reload_config SIGHUP

# --- Audio Infrastructure ---
check_node() {
    pw-link --ports | grep -q "^$1:"
}

setup_audio_graph() {
    # 1. Input Node (Phone -> PC)
    if ! check_node "$NODE_IN"; then
        pw-cli create-node adapter factory.name=support.null-audio-sink node.name="$NODE_IN" media.class=Audio/Sink node.description="ZeroBridge_Line-In" object.linger=true >/dev/null
    fi
    # 2. Output Node (PC -> Phone)
    if ! check_node "$NODE_OUT"; then
        pw-cli create-node adapter factory.name=support.null-audio-sink node.name="$NODE_OUT" media.class=Audio/Sink node.description="ZeroBridge_Output" object.linger=true >/dev/null
    fi
    # 3. Mic Node (Virtual Source)
    if ! check_node "$NODE_MIC"; then
        pw-cli create-node adapter factory.name=support.null-audio-sink node.name="$NODE_MIC" media.class=Audio/Source/Virtual node.description="ZeroBridge_Microphone" object.linger=true >/dev/null
    fi
    sleep 0.5
}

# --- Routing Agent ---
force_route_loop() {
    echo ":: [Route] Agent Active (IN:$NODE_IN OUT:$NODE_OUT MIC:$NODE_MIC)."
    
    while true; do
        # 1. Internal bridge: Line-In Monitor -> Virtual Mic Input
        pw-link "$NODE_IN:monitor_FL" "$NODE_MIC:input_FL" >/dev/null 2>&1
        pw-link "$NODE_IN:monitor_FR" "$NODE_MIC:input_FR" >/dev/null 2>&1

        # 2. Hardcoded SDL (Scrcpy) routing enforcement
        # Kill drift to Output node
        pw-link -d "SDL Application:output_FL" "$NODE_OUT:playback_FL" >/dev/null 2>&1
        pw-link -d "SDL Application:output_FR" "$NODE_OUT:playback_FR" >/dev/null 2>&1
        
        # Snap to Input node
        pw-link "SDL Application:output_FL" "$NODE_IN:playback_FL" >/dev/null 2>&1
        pw-link "SDL Application:output_FR" "$NODE_IN:playback_FR" >/dev/null 2>&1
        
        # 3. Ensure GStreamer is pulling from Output monitor
        # We look for the input port of the active broadcaster
        GST_PORT=$(pw-link -i | grep "gst-launch-1.0" | head -n 1 | cut -d: -f1)
        if [[ -n "$GST_PORT" ]]; then
            pw-link "$NODE_OUT:monitor_FL" "$GST_PORT:input_FL" >/dev/null 2>&1
            pw-link "$NODE_OUT:monitor_FR" "$GST_PORT:input_FR" >/dev/null 2>&1
        fi
        
        sleep 2
    done
}

# --- Start Logic ---
if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; fi

destroy_zbridge_nodes
setup_audio_graph

force_route_loop &
ROUTING_PID=$!

while true; do
    RELOAD_REQUESTED=false
    
    if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; else sleep 5; continue; fi
    [[ -z "$PHONE_IP" ]] && { echo ":: [Daemon] Waiting for IP..."; sleep 5; continue; }

    adb connect "$PHONE_IP" >/dev/null 2>&1
    
    # Broadcast PC -> Phone
    TARGET_IP="${PHONE_IP%:*}"
    if [[ -z "$BROADCAST_PID" ]] || ! kill -0 "$BROADCAST_PID" 2>/dev/null; then
        echo ":: [Daemon] Starting Broadcast to $TARGET_IP:$BROADCAST_PORT"
        setsid gst-launch-1.0 -q pulsesrc device="$NODE_OUT.monitor" ! \
            audioconvert ! \
            opusenc bitrate=96000 audio-type=voice frame-size=5 ! \
            rtpopuspay ! \
            udpsink host="$TARGET_IP" port="$BROADCAST_PORT" sync=false async=false &
        BROADCAST_PID=$!
    fi

    # Scrcpy Phone -> PC
    SCRCPY_ARGS=( --serial "${PHONE_IP%:*}" --no-window --audio-codec=flac --audio-buffer=50 )
    if [[ "$CAM_FACING" == "none" ]]; then
        SCRCPY_ARGS+=( --no-video --audio-source=mic )
    else
        ORIENT="flip270"; [[ "$CAM_FACING" == "front" ]] && ORIENT="flip90"
        AUDIO_SRC="mic"; [[ "$CAM_FACING" == "back" ]] && AUDIO_SRC="output"
        SCRCPY_ARGS+=( --video-source=camera --camera-facing="$CAM_FACING" --capture-orientation="$ORIENT" --v4l2-sink=/dev/video9 --audio-source="$AUDIO_SRC" )
    fi
    
    echo ":: [Daemon] Launching Scrcpy..."
    PULSE_SINK="$NODE_IN" scrcpy "${SCRCPY_ARGS[@]}" &
    SCRCPY_PID=$!
    
    wait $SCRCPY_PID
    
    if [ "$RELOAD_REQUESTED" = true ]; then
        echo ":: [Daemon] Refreshing loop for new config..."
        sleep 1
    else
        echo ":: [Daemon] Scrcpy exited. Retrying in 3s..."
        sleep 3
    fi
done