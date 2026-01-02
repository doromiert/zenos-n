#!/usr/bin/env bash
# zb-config - ZeroBridge Controller
# Usage: zb-config [-i IP] [-c front|back|none|switch] [-o PORT] [-m] [-d] [-k]

CONFIG_DIR="$HOME/.config/zbridge"
CONFIG_FILE="$CONFIG_DIR/state.conf"

# Ensure config environment exists
if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then echo "Error: Cannot create directory."; exit 1; fi
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo 'PHONE_IP=""' > "$CONFIG_FILE"
    echo 'CAM_FACING="back"' >> "$CONFIG_FILE"
    echo 'BROADCAST_PORT="5000"' >> "$CONFIG_FILE"
    echo 'MONITOR_ID=""' >> "$CONFIG_FILE"
    echo 'DESKTOP_ID=""' >> "$CONFIG_FILE"
fi

if ! source "$CONFIG_FILE"; then echo "Error: Failed to read config file."; exit 1; fi

UPDATE_NEEDED=false

usage() { 
    echo "Usage: zb-config [options]"
    echo "Options:"
    echo "  -i IP:PORT      Set Phone IP address"
    echo "  -c MODE         Set Camera: front | back | none | switch"
    echo "  -o PORT         Set UDP Broadcast Port (Default: 5000)"
    echo "  -m              Toggle Audio Monitor (Hear Phone on PC)"
    echo "  -d              Toggle Desktop Mirror (Send PC Audio to Phone)"
    echo "  -k              Kill/Stop ZeroBridge Service"
    echo "  -h              Show this help"
    exit 1 
}

while getopts "i:c:o:mdkh" opt; do
  case $opt in
    i) PHONE_IP="$OPTARG"; UPDATE_NEEDED=true ;;
    c)
      NEW_CAM="$OPTARG"
      if [[ "$NEW_CAM" == "switch" ]]; then
        if [[ "$CAM_FACING" == "front" ]]; then 
            CAM_FACING="back"
        elif [[ "$CAM_FACING" == "back" ]]; then
            CAM_FACING="front"
        else
            CAM_FACING="back" # Default if switching from 'none'
        fi
      else 
        CAM_FACING="$NEW_CAM"
      fi
      UPDATE_NEEDED=true
      ;;
    o) BROADCAST_PORT="$OPTARG"; UPDATE_NEEDED=true ;;
    
    m) # Toggle Monitor (Hear Phone on PC Speakers)
      if [[ -n "$MONITOR_ID" ]]; then
        echo ":: Disabling Monitor (zbin -> Speakers)..."
        pactl unload-module "$MONITOR_ID" 2>/dev/null
        MONITOR_ID=""
      else
        echo ":: Enabling Monitor (zbin -> Speakers)..."
        # module-loopback is used to bridge the virtual sink monitor to the default output
        ID=$(pactl load-module module-loopback source=zbin.monitor latency_msec=10)
        MONITOR_ID="$ID"
      fi
      UPDATE_NEEDED=true
      ;;
      
    d) # Toggle Desktop Mirror (Send PC Speakers to Phone)
      if [[ -n "$DESKTOP_ID" ]]; then
        echo ":: Disabling Desktop Mirror (Speakers -> zbout)..."
        pactl unload-module "$DESKTOP_ID" 2>/dev/null
        DESKTOP_ID=""
      else
        echo ":: Enabling Desktop Mirror (Speakers -> zbout)..."
        # Find default source (monitor of default sink)
        DEFAULT_SINK=$(pactl get-default-sink)
        ID=$(pactl load-module module-loopback source="$DEFAULT_SINK.monitor" sink=zbout latency_msec=10)
        DESKTOP_ID="$ID"
      fi
      UPDATE_NEEDED=true
      ;;

    k)
      echo ":: Stopping ZBridge Service..."
      [[ -n "$MONITOR_ID" ]] && pactl unload-module "$MONITOR_ID" 2>/dev/null
      [[ -n "$DESKTOP_ID" ]] && pactl unload-module "$DESKTOP_ID" 2>/dev/null
      # Clear IDs in config before stopping so they don't persist as "ON"
      {
          echo "PHONE_IP=\"$PHONE_IP\""
          echo "CAM_FACING=\"$CAM_FACING\""
          echo "BROADCAST_PORT=\"$BROADCAST_PORT\""
          echo "MONITOR_ID=\"\""
          echo "DESKTOP_ID=\"\""
      } > "$CONFIG_FILE"
      systemctl --user stop zbridge
      exit 0
      ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ "$UPDATE_NEEDED" = true ]; then
    echo ":: Updating State..."
    {
        echo "PHONE_IP=\"$PHONE_IP\""
        echo "CAM_FACING=\"$CAM_FACING\""
        echo "BROADCAST_PORT=\"$BROADCAST_PORT\""
        echo "MONITOR_ID=\"$MONITOR_ID\""
        echo "DESKTOP_ID=\"$DESKTOP_ID\""
    } > "$CONFIG_FILE"

    if systemctl --user is-active --quiet zbridge; then
        echo ":: Signaling Daemon to Reload (SIGHUP)..."
        systemctl --user kill -s HUP zbridge
    else
        echo ":: Service not running. Starting..."
        systemctl --user start zbridge
    fi
else
    echo ":: ZeroBridge Current State ::"
    echo "IP:      $PHONE_IP"
    echo "Cam:     $CAM_FACING"
    echo "Port:    $BROADCAST_PORT"
    echo "Monitor: ${MONITOR_ID:+ON (ID:$MONITOR_ID)}"
    echo "Monitor: ${MONITOR_ID:-OFF}"
    echo "Desktop: ${DESKTOP_ID:+ON (ID:$DESKTOP_ID)}"
    echo "Desktop: ${DESKTOP_ID:-OFF}"
fi