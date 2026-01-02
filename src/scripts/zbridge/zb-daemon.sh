#!/usr/bin/env bash
# zb-daemon - Background Service
# Handled by systemd. DO NOT RUN DIRECTLY.

CONFIG_DIR="$HOME/.config/zbridge"
CONFIG_FILE="$CONFIG_DIR/state.conf"

# --- Defaults ---
PHONE_IP=""
CAM_FACING="back" # Options: "back", "front", "none"
BROADCAST_PORT="5000"

# --- Runtime PIDs ---
SCRCPY_PID=""
BROADCAST_PID=""
ROUTING_PID=""
RELOAD_REQUESTED=false

# --- Cleanup & Traps ---
cleanup() {
    echo ":: [Daemon] Stopping..."
    [[ -n "$SCRCPY_PID" ]] && kill "$SCRCPY_PID" 2>/dev/null
    [[ -n "$BROADCAST_PID" ]] && kill "$BROADCAST_PID" 2>/dev/null
    [[ -n "$ROUTING_PID" ]] && kill "$ROUTING_PID" 2>/dev/null
    exit 0
}

reload_config() {
    echo ":: [Daemon] Reload Signal Received (SIGHUP)"
    RELOAD_REQUESTED=true
    [[ -n "$SCRCPY_PID" ]] && kill -TERM "$SCRCPY_PID" 2>/dev/null
}

trap cleanup SIGINT SIGTERM EXIT
trap reload_config SIGHUP

# --- Audio Infrastructure (PipeWire Native) ---
check_node() {
    # Checks if a port belonging to the node exists
    pw-link --ports | grep -q "^$1:"
}

setup_audio_graph() {
    echo ":: [Init] Verifying Audio Infrastructure (PipeWire)..."
    
    # 1. Create ZBIN (Line-In from Phone) - Audio/Sink
    if ! check_node "zbin"; then
        echo ":: [Init] Creating zbin sink..."
        pw-cli create-node adapter \
            factory.name=support.null-audio-sink \
            node.name=zbin \
            media.class=Audio/Sink \
            node.description="ZeroBridge_Line-In" \
            object.linger=true >/dev/null
    fi

    # 2. Create ZBOUT (Output to Phone) - Audio/Sink
    if ! check_node "zbout"; then
        echo ":: [Init] Creating zbout sink..."
        pw-cli create-node adapter \
            factory.name=support.null-audio-sink \
            node.name=zbout \
            media.class=Audio/Sink \
            node.description="ZeroBridge_Output" \
            object.linger=true >/dev/null
    fi

    # 3. Create ZMIC (Virtual Mic for Discord) - Audio/Source/Virtual
    # In PipeWire, a Virtual Source has Input ports (to feed it) and Output ports (to capture).
    if ! check_node "zmic"; then
        echo ":: [Init] Creating zmic source..."
        pw-cli create-node adapter \
            factory.name=support.null-audio-sink \
            node.name=zmic \
            node.autoconnect
            media.class=Audio/Source/Virtual \
            node.description="ZeroBridge_Microphone" \
            object.linger=true >/dev/null
        
        # Allow node to initialize before linking
        sleep 0.5
    fi

    # 4. Wire ZBIN Monitor -> ZMIC Input
    # This replaces the 'module-remap-source' functionality.
    # We force this link every start to ensure the path exists.
    pw-link zbin:monitor_FL zmic:input_FL >/dev/null 2>&1
    pw-link zbin:monitor_FR zmic:input_FR >/dev/null 2>&1
}

# --- Audio Routing Agent (PipeWire Native) ---
force_route_loop() {
    echo ":: [Route] Agent Active. Enforcing target: zbin"
    
    # Candidate names for Scrcpy in PipeWire graph
    CANDIDATES=("SDL Application" "scrcpy" "Simple DirectMedia Layer")
    
    while true; do
        for SRC in "${CANDIDATES[@]}"; do
            # 1. Force Connect (Idempotent)
            pw-link "$SRC:output_FL" zbin:playback_FL >/dev/null 2>&1
            pw-link "$SRC:output_FR" zbin:playback_FR >/dev/null 2>&1
            
            # 2. Anti-Leak Scan
            pw-link -o -l | while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                
                # Header detection for Candidates OR Loopback
                if [[ "$line" == "$SRC:output_FL" || "$line" == "$SRC:output_FR" ]]; then
                    CURRENT_PORT="$line"
                    IS_LOOPBACK=false
                elif [[ "$line" == *"loopback"* ]]; then
                    CURRENT_PORT="$line"
                    IS_LOOPBACK=true
                elif [[ "$line" == *"|->"* ]]; then
                    # Link line
                    TARGET=$(echo "$line" | sed 's/^.*|-> //')
                    
                    if [[ -n "$CURRENT_PORT" ]]; then
                        # Logic A: If candidate source AND target isn't zbin -> KILL
                        if [[ "$IS_LOOPBACK" == false ]]; then
                            if [[ "$TARGET" != "zbin:playback_FL" && "$TARGET" != "zbin:playback_FR" ]]; then
                                echo ":: [Route] Fixing Leak: $CURRENT_PORT -> $TARGET"
                                pw-link -d "$CURRENT_PORT" "$TARGET" >/dev/null 2>&1
                            fi
                        # Logic B: If loopback source AND target is zbout -> KILL
                        elif [[ "$IS_LOOPBACK" == true && "$TARGET" == *"zbout"* ]]; then
                            echo ":: [Route] Killing Loopback Loop: $CURRENT_PORT -> $TARGET"
                            pw-link -d "$CURRENT_PORT" "$TARGET" >/dev/null 2>&1
                        fi
                    fi
                fi
            done
        done
        sleep 3
    done
}

# --- Initialization ---
if [[ ! -d "$CONFIG_DIR" ]]; then mkdir -p "$CONFIG_DIR"; fi
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo ":: [Daemon] Config file missing. Initializing defaults..."
    echo 'PHONE_IP=""' > "$CONFIG_FILE"
    echo 'CAM_FACING="back"' >> "$CONFIG_FILE"
    echo 'BROADCAST_PORT="5000"' >> "$CONFIG_FILE"
fi

setup_audio_graph

# --- Main Service Loop ---
echo ":: [Daemon] Started."
force_route_loop &
ROUTING_PID=$!

while true; do
    RELOAD_REQUESTED=false
    
    if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; else sleep 5; continue; fi
    if [[ -z "$PHONE_IP" ]]; then sleep 5; continue; fi

    # Network
    if ! adb devices | grep -q "${PHONE_IP%:*}"; then
        echo ":: [Daemon] Connecting to $PHONE_IP..."
        adb connect "$PHONE_IP"
    fi
    
    # Broadcast (PC -> Phone)
    TARGET_IP="${PHONE_IP%:*}"
    [[ -n "$BROADCAST_PID" ]] && kill "$BROADCAST_PID" 2>/dev/null
    
    echo ":: [Daemon] Stream: zbout.monitor -> $TARGET_IP:$BROADCAST_PORT"
    setsid gst-launch-1.0 -q pulsesrc device=zbout.monitor ! \
        audioconvert ! \
        opusenc bitrate=96000 audio-type=voice frame-size=5 ! \
        rtpopuspay ! \
        udpsink host="$TARGET_IP" port="$BROADCAST_PORT" sync=false async=false &
    BROADCAST_PID=$!

    # Scrcpy (Phone -> PC)
    # Define base arguments in an array for cleaner handling
    SCRCPY_ARGS=(
        --serial "${PHONE_IP%:*}"
        --no-window
        --audio-codec=flac 
        --audio-buffer=50
    )

    if [[ "$CAM_FACING" == "none" ]]; then
        # Audio-only mode (Phone as Mic)
        echo ":: [Daemon] Launching Scrcpy (Audio Only - No Camera)..."
        SCRCPY_ARGS+=( 
            --no-video 
            --audio-source=mic 
        )
    else
        # Video mode (Phone as Webcam + Mic/Output)
        ORIENT="flip270"
        [[ "$CAM_FACING" == "front" ]] && ORIENT="flip90"
        
        AUDIO_SRC="mic"
        [[ "$CAM_FACING" == "back" ]] && AUDIO_SRC="output"
        
        echo ":: [Daemon] Launching Scrcpy ($CAM_FACING)..."
        SCRCPY_ARGS+=(
            --video-source=camera
            --camera-facing="$CAM_FACING"
            --capture-orientation="$ORIENT"
            --v4l2-sink=/dev/video9
            --audio-source="$AUDIO_SRC"
        )
    fi
    
    # Force zbin via environment AND audio-output-buffer
    # We add a small sleep to ensure sinks are registered before scrcpy grabs them
    sleep 1
    PULSE_SINK=zbin scrcpy "${SCRCPY_ARGS[@]}" &
    
    SCRCPY_PID=$!
    
    wait $SCRCPY_PID
    
    if [ "$RELOAD_REQUESTED" = true ]; then
        echo ":: [Daemon] Reloading..."
        sleep 1
    else
        echo ":: [Daemon] Scrcpy died. Retrying in 3s..."
        sleep 3
    fi
done