#!/usr/bin/env bash
# ZBridge Persistent Receiver Deployer
# Usage: zbr-installer <PHONE_IP>

PHONE_IP=$1
[[ -z "$PHONE_IP" ]] && { echo "Usage: $0 <PHONE_IP>"; exit 1; }

echo ":: Connecting to $PHONE_IP..."
adb connect "$PHONE_IP"
adb -s "$PHONE_IP" wait-for-device

# --- 1. Create the Payload Script (Runs inside Termux) ---
cat << 'EOF' > zreceiver_payload.sh
#!/data/data/com.termux/files/usr/bin/sh

# Setup Environment
echo ":: Updating Packages..."
yes | pkg upgrade
yes | pkg install termux-services gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad

# Create Service Directory
SERVICE_DIR="$PREFIX/var/service/zreceiver"
mkdir -p "$SERVICE_DIR"

# Write the Run Script
cat << 'RUN' > "$SERVICE_DIR/run"
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
exec 2>&1

while true; do
    echo ":: Starting GStreamer Listener (Opus/40ms)..."
    gst-launch-1.0 -q udpsrc port=5000 ! \
    application/x-rtp,media=audio,clock-rate=48000,encoding-name=OPUS,payload=96 ! \
    rtpopusdepay ! opusdec ! \
    openslessink buffer-time=40000 latency-time=10000
    
    echo ":: Restarting in 1s..."
    sleep 1
done
RUN

# Set Permissions & Enable
chmod +x "$SERVICE_DIR/run"
sv-enable zreceiver

# Start Service
echo ":: Starting Service..."
sv up zreceiver
sv status zreceiver

echo ":: DEPLOYMENT COMPLETE ::"
echo ":: PLEASE DISABLE BATTERY OPTIMIZATIONS FOR TERMUX MANUALLY ::"
EOF

# --- 2. Push Payload to SD Card ---
echo ":: Pushing payload to /sdcard/Download/..."
adb -s "$PHONE_IP" push zreceiver_payload.sh /sdcard/Download/zreceiver_payload.sh

# --- 3. Execute via Input Injection ---
echo ":: Launching Termux..."
adb -s "$PHONE_IP" shell am start -n com.termux/.app.TermuxActivity

echo ":: Waiting for App Load (2s)..."
sleep 2

echo ":: Injecting Command..."
# We move the file to home first because executing from /sdcard is often blocked by noexec mount
CMD="cp /sdcard/Download/zreceiver_payload.sh . && sh zreceiver_payload.sh"

# Send text inputs (escaped spaces)
adb -s "$PHONE_IP" shell input text "cp\ \%sdcard\%Download\%zreceiver_payload.sh\ .\ \&\&\ sh\ zreceiver_payload.sh"
sleep 0.5
adb -s "$PHONE_IP" shell input keyevent 66 # ENTER

echo ":: Done. Check phone screen for progress."
rm zreceiver_payload.sh