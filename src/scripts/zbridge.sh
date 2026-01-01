#!/usr/bin/env bash
# zbridge - ZeroBridge Android Virtual Device Manager
# Update: Supports Hot-Swapping Cameras via Ctrl+C

# --- Defaults ---
ENABLE_MIC=false
ENABLE_CAM=false
ENABLE_BROADCAST=false
CAM_FACING="back" # Default start
PHONE_IP=""
BROADCAST_PORT=""
FIREWALL_OPENED=false
SCRCPY_PID=""
SWITCH_REQUESTED=false

# --- Stability & Quality Settings ---
STABILITY_FLAGS=(
    --max-size=1024
    --video-bit-rate=4M
    --max-fps=30
    --audio-codec=flac
    --audio-buffer=50
)

usage() {
    echo "Usage: $0 -m -c <front|back> -i <ip:port> -o <port>"
    echo "Controls: Ctrl+C = SWITCH CAMERA | Ctrl+Z = EXIT"
    exit 1
}

# --- Signal Handling ---
cleanup() {
    # Only cleanup if we are TRULY exiting (not switching)
    if [ "$SWITCH_REQUESTED" = true ]; then
        return
    fi
    
    echo ":: Stopping..."
    [[ -n "$BROADCAST_PID" ]] && kill "$BROADCAST_PID" 2>/dev/null
    [[ -n "$ROUTING_PID" ]] && kill "$ROUTING_PID" 2>/dev/null
    
    if [[ "$FIREWALL_OPENED" == true ]]; then
        sudo iptables -D INPUT -p udp --dport "$BROADCAST_PORT" -j ACCEPT 2>/dev/null
    fi
    exit 0
}

toggle_camera() {
    echo ":: [HOT-SWAP] Toggling Camera..."
    SWITCH_REQUESTED=true
    if [[ -n "$SCRCPY_PID" ]]; then
        kill -TERM "$SCRCPY_PID" 2>/dev/null
    fi
}

trap cleanup EXIT
trap toggle_camera SIGINT
trap "exit 0" SIGTSTP SIGQUIT # Map Ctrl+Z and Ctrl+\ to Exit

# --- Audio Routing Agent (PipeWire Native) ---
force_route_loop() {
    echo ":: [Routing Agent] Watching for scrcpy audio..."
    
    # Target Sinks
    TARGET_L="vmic:playback_FL"
    TARGET_R="vmic:playback_FR"

    while true; do
        # 1. Connect (Idempotent) - Force connection to VMIC
        pw-link "SDL Application:output_FL" "$TARGET_L" 2>/dev/null
        pw-link "SDL Application:output_FR" "$TARGET_R" 2>/dev/null

        # 2. Disconnect (State Machine Parser) - Kill connections to Speakers/Vout
        # pw-link -o -l output format:
        # Source_Name
        #   |-> Target_Name
        CURRENT_SRC=""
        
        pw-link -o -l | while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            
            if [[ "$line" != *"|->"* ]]; then
                # Line is a Source Port (Header)
                CURRENT_SRC="$line"
            else
                # Line is a Link (Indented)
                # TARGET="${line#*|-> }" # Strip prefix
                TARGET=$(echo "$line" | sed 's/^.*|-> //')

                # --- Logic: Left Channel ---
                if [[ "$CURRENT_SRC" == "SDL Application:output_FL" ]]; then
                    # If this link is NOT to our allowed sink, kill it
                    if [[ "$TARGET" != "$TARGET_L" ]]; then
                        # echo ":: Unlinking LEAK: $CURRENT_SRC -> $TARGET"
                        pw-link -d "$CURRENT_SRC" "$TARGET" 2>/dev/null
                    fi
                fi

                # --- Logic: Right Channel ---
                if [[ "$CURRENT_SRC" == "SDL Application:output_FR" ]]; then
                    # If this link is NOT to our allowed sink, kill it
                    if [[ "$TARGET" != "$TARGET_R" ]]; then
                        # echo ":: Unlinking LEAK: $CURRENT_SRC -> $TARGET"
                        pw-link -d "$CURRENT_SRC" "$TARGET" 2>/dev/null
                    fi
                fi
            fi
        done

        sleep 1
    done
}

while getopts "mc:i:o:h" opt; do
  case $opt in
    m) ENABLE_MIC=true ;;
    c) ENABLE_CAM=true; CAM_FACING=$OPTARG ;;
    i) PHONE_IP=$OPTARG ;;
    o) ENABLE_BROADCAST=true; BROADCAST_PORT=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ -z "$PHONE_IP" ]] && usage

echo ":: Connecting to $PHONE_IP..."
adb connect "$PHONE_IP"

# --- Broadcast Service (GStreamer Low-Latency) ---
if [ "$ENABLE_BROADCAST" = true ]; then
    TARGET_IP="${PHONE_IP%:*}"
    echo ":: [GSTREAMER] Pushing Low-Latency Opus to $TARGET_IP:$BROADCAST_PORT..."
    
    if sudo iptables -I INPUT -p udp --dport "$BROADCAST_PORT" -j ACCEPT; then
        FIREWALL_OPENED=true
    fi

    # 5ms Frame Size = 200 packets/sec for ultra-low latency
    # FIX: Use 'setsid' to detach process from terminal signal group (prevents death on Ctrl+C)
    setsid gst-launch-1.0 -q pulsesrc device=vout.monitor ! \
        audioconvert ! \
        opusenc bitrate=96000 audio-type=voice frame-size=5 ! \
        rtpopuspay ! \
        udpsink host="$TARGET_IP" port="$BROADCAST_PORT" sync=false async=false &
        
    BROADCAST_PID=$!
fi

# Start the Routing Agent
force_route_loop &
ROUTING_PID=$!

echo ":: Starting Bridge Loop..."
echo ":: [CONTROLS] Ctrl+C to SWITCH CAMERA | Ctrl+Z to EXIT"

# --- Main Loop ---
while true; do
    SWITCH_REQUESTED=false

    # Dynamic Arguments per Loop
    CMD_ARGS=( --serial "${PHONE_IP%:*}" "${STABILITY_FLAGS[@]}" )

    if [ "$ENABLE_MIC" = true ]; then
        CMD_ARGS+=( --audio-source=mic )
    else
        CMD_ARGS+=( --audio-source=output )
    fi

    if [ "$ENABLE_CAM" = true ]; then
        # Orientation Logic
        if [[ "$CAM_FACING" == "front" ]]; then
            ORIENT="flip90"
        else
            ORIENT="flip270" # Back camera (User reported flipped fix)
        fi

        echo ":: Camera: $CAM_FACING | Orientation: $ORIENT"
        CMD_ARGS+=( --video-source=camera --camera-facing="$CAM_FACING" --capture-orientation="$ORIENT" --v4l2-sink=/dev/video9 --no-window )
    else
        CMD_ARGS+=( --no-video --no-window )
    fi

    # Run Scrcpy in background so we can wait/trap
    scrcpy "${CMD_ARGS[@]}" &
    SCRCPY_PID=$!
    
    # Wait for scrcpy to exit (either via window close or signal)
    wait $SCRCPY_PID
    
    # Logic Branch
    if [ "$SWITCH_REQUESTED" = true ]; then
        # Toggle State for next loop
        if [[ "$CAM_FACING" == "front" ]]; then
            CAM_FACING="back"
        else
            CAM_FACING="front"
        fi
        sleep 0.5
    else
        # Normal exit (Window closed)
        echo ":: Scrcpy exited normally."
        break
    fi
done