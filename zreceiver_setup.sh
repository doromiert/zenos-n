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
