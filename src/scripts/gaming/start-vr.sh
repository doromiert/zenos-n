#!/usr/bin/env bash

# ZeroPlay VR Stack Launcher
# Order: ALVR -> SteamVR -> Overlays

echo "[VR] Starting ALVR Dashboard..."
# Launch ALVR in background, disowned so it survives script exit if needed
nohup alvr_dashboard > /dev/null 2>&1 &
ALVR_PID=$!

echo "[VR] Waiting for SteamVR to initialize..."
# Wait loop for SteamVR process (vrserver or vrmonitor)
# ALVR usually triggers this when headset connects
while ! pgrep -x "vrmonitor" > /dev/null; do
    sleep 1
    echo -n "."
done
echo ""
echo "[VR] SteamVR detected!"

# Give SteamVR a moment to stabilize
sleep 5

echo "[VR] Launching wlx-overlay-s (Desktop Overlay)..."
# Using nohup to detach
nohup wlx-overlay-s --openvr > /dev/null 2>&1 &

echo "[VR] Launching OVR Advanced Settings..."
# Check if binary name differs in your install
nohup ovr-advanced-settings > /dev/null 2>&1 &

echo "[VR] Stack initialization complete."