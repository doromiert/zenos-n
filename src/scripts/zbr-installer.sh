#!/usr/bin/env bash
# zbr-installer - ZBridge Persistent Receiver Deployer
# Usage: zbr-installer <PHONE_IP>

PHONE_IP=$1
[[ -z "$PHONE_IP" ]] && { echo "Usage: $0 <PHONE_IP>"; exit 1; }

echo ":: Connecting to $PHONE_IP..."
adb connect "$PHONE_IP"
adb -s "$PHONE_IP" wait-for-device

# --- 1. Generate Configuration Payload ---
cat << 'EOF' > zreceiver_setup.sh
#!/data/data/com.termux/files/usr/bin/sh
# Define Paths manually to ensure they work even if env is broken
PREFIX="/data/data/com.termux/files/usr"
SVDIR="$PREFIX/var/service"
SERVICE_DIR="$SVDIR/zreceiver"

echo ":: Installing Dependencies..."
yes | pkg update
yes | pkg install termux-services gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad

echo ":: configuring Service Files..."
mkdir -p "$SERVICE_DIR"

# Write the Service Run Script
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

chmod +x "$SERVICE_DIR/run"

echo ":: Service Configured. Ready for Restart."
EOF

# --- 2. Push & Execute Configuration ---
echo ":: Pushing setup script..."
adb -s "$PHONE_IP" push zreceiver_setup.sh /sdcard/Download/zreceiver_setup.sh

echo ":: Launching Termux to apply config..."
adb -s "$PHONE_IP" shell am start -n com.termux/.app.TermuxActivity
sleep 3
adb -s "$PHONE_IP" shell input text "sh\ /sdcard/Download/zreceiver_setup.sh"
sleep 0.5
adb -s "$PHONE_IP" shell input keyevent 66 # ENTER

# Wait for the script to finish (give it 15s to install packages)
echo ":: Waiting for installation to finish (15s)..."
sleep 15

# --- 3. THE FIX: Force Restart Termux ---
echo ":: Force-Stopping Termux (Reloads Environment)..."
adb -s "$PHONE_IP" shell am force-stop com.termux

echo ":: Relaunching Termux..."
adb -s "$PHONE_IP" shell am start -n com.termux/.app.TermuxActivity

echo ":: Waiting for Service Daemon..."
sleep 5

# --- 4. Verify Status ---
echo ":: Checking Service Status..."
# We use input injection to check status so you see it on screen
adb -s "$PHONE_IP" shell input text "sv\ status\ zreceiver"
adb -s "$PHONE_IP" shell input keyevent 66 # ENTER

echo ":: DONE. You should see 'run: zreceiver' on the phone screen."
rm zreceiver_setup.sh