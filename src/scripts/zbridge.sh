#!/usr/bin/env bash
# zbridge - ZeroBridge Android Virtual Device Manager

# --- Defaults ---
ENABLE_MIC=false
ENABLE_CAM=false
ENABLE_BROADCAST=false
CAM_FACING="back"
PHONE_IP=""
BROADCAST_PORT=""
FIREWALL_OPENED=false

# --- Stability & Quality Settings ---
STABILITY_FLAGS=(
    --max-size=1024
    --video-bit-rate=4M
    --max-fps=30
    --audio-codec=flac
    --audio-buffer=50     # Increased buffer to prevent dropouts
)

usage() {
    echo "Usage: $0 -m -c <front|back> -i <ip:port> -o <port>"
    exit 1
}

cleanup() {
    echo ":: Stopping..."
    [[ -n "$BROADCAST_PID" ]] && kill "$BROADCAST_PID" 2>/dev/null
    [[ -n "$ROUTING_PID" ]] && kill "$ROUTING_PID" 2>/dev/null
    if [[ "$FIREWALL_OPENED" == true ]]; then
        sudo iptables -D INPUT -p tcp --dport "$BROADCAST_PORT" -j ACCEPT 2>/dev/null
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM

# --- Audio Routing Agent (PipeWire Native) ---
# Enforces that scrcpy ONLY connects to vmic
force_route_loop() {
    echo ":: [Routing Agent] Watching for scrcpy audio..."
    
    # Target Sinks
    TARGET_L="vmic:playback_FL"
    TARGET_R="vmic:playback_FR"

    while true; do
        # 1. Connect (Idempotent)
        # We try to link every loop. pw-link returns 0 if already linked, so strict error hiding needed.
        # We quote strictly to handle spaces in "SDL Application".
        pw-link "SDL Application:output_FL" "$TARGET_L" 2>/dev/null
        pw-link "SDL Application:output_FR" "$TARGET_R" 2>/dev/null

        # 2. Disconnect (State Machine Parser)
        # pw-link -o -l outputs a tree:
        # Source_Name
        #   |-> Target_Name
        CURRENT_SRC=""
        
        pw-link -o -l | while IFS= read -r line; do
            # Skip empty lines
            [[ -z "$line" ]] && continue
            
            if [[ "$line" != *"|->"* ]]; then
                # Line is a Source Port (Header)
                CURRENT_SRC="$line"
            else
                # Line is a Link (Indented)
                # Format: "  |-> Target_Name"
                # We strip the arrow and leading space to get pure Target Name
                TARGET="${line#*|-> }"
                
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

        sleep 3
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
    echo ":: [GSTREAMER] Pushing Low-Latency Opus to $TARGET_IP..."

    # Pipeline Explanation:
    # 1. pulsesrc: Grabs directly from the monitor (Device name must match `pactl list sources`)
    # 2. audioconvert: Ensures format matches Opus requirements
    # 3. opusenc: Encodes audio.
    #    - bitrate=96000: Good balance.
    #    - audio-type=voice: Tells encoder to optimize for speech patterns (faster).
    #    - frame-size=5: CRITICAL. Sends tiny 5ms packets to force immediate playback.
    # 4. rtpopuspay: Packages into RTP.
    # 5. udpsink: Fires packets at the phone.
    
    gst-launch-1.0 -q pulsesrc device=vout.monitor ! \
        audioconvert ! \
        opusenc bitrate=96000 audio-type=voice frame-size=5 ! \
        rtpopuspay ! \
        udpsink host="$TARGET_IP" port="$BROADCAST_PORT" sync=false async=false &
        
    BROADCAST_PID=$!
fi

# --- Scrcpy Argument Logic ---
CMD_ARGS=( --serial "${PHONE_IP%:*}" "${STABILITY_FLAGS[@]}" )

if [ "$ENABLE_MIC" = true ]; then
    # Inject Phone Microphone as Audio Source
    CMD_ARGS+=( --audio-source=mic )
else
    # Capture Phone Media (Default Behavior)
    # MUST be output, otherwise no stream exists to route
    CMD_ARGS+=( --audio-source=output )
fi

if [ "$ENABLE_CAM" = true ]; then
    CMD_ARGS+=( --video-source=camera --camera-facing="$CAM_FACING" --capture-orientation=flip90 --v4l2-sink=/dev/video9 --no-window )
else
    CMD_ARGS+=( --no-video --no-window )
fi

echo ":: Starting Bridge Loop..."

# Start the PW-Link Agent in background
force_route_loop &
ROUTING_PID=$!

while true; do
    scrcpy "${CMD_ARGS[@]}"
    echo ":: Scrcpy stopped. Restarting in 2s..."
    sleep 2
done