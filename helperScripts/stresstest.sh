#!/usr/bin/env bash

# Doromi-Tul-2 GNOME/Wayland Stability Test
# Targets: Mutter Actor State & AMDGPU Scheduler Preemption

URL="https://webglsamples.org/aquarium/aquarium.html" # A nice WebGL stress test
COUNT=10
DELAY=2

echo "== Starting Stress Test =="
echo "Target: checking if opening $COUNT firefox instances triggers the Mutter actor crash."

# 1. Verify Environment Fixes
echo "[1/4] Verifying Fixes..."
if [[ "$MUTTER_DEBUG_KMS_THREAD_TYPE" == "user" ]]; then
    echo "  [OK] MUTTER_DEBUG_KMS_THREAD_TYPE is set to 'user'."
else
    echo "  [WARN] MUTTER_DEBUG_KMS_THREAD_TYPE is NOT set. Race condition may persist."
fi

CMD_PREEMPT=$(cat /sys/module/amdgpu/parameters/mcbp 2>/dev/null)
if [[ "$CMD_PREEMPT" == "0" ]]; then
    echo "  [OK] AMDGPU Mid-Command Buffer Preemption (MCBP) is DISABLED."
else
    echo "  [WARN] AMDGPU MCBP might be enabled (Value: $CMD_PREEMPT). Check boot params."
fi

# 2. Background GPU Load
echo "[2/4] Spawning Background GPU Load..."
# Try to run a simple GL app to keep the GPU scheduler active, mimicking the 'scrcpy' load
if command -v glxgears &> /dev/null; then
    glxgears &
    GL_PID=$!
    echo "  Running glxgears (PID $GL_PID)"
else
    echo "  glxgears not found, relying on WebGL only."
fi

# 3. Firefox Spawn Loop
echo "[3/4] Launching Firefox Instances..."
for i in $(seq 1 $COUNT); do
    echo "  Opening Instance $i/$COUNT..."
    
    # We use --new-window to force a new window actor creation in Mutter
    nohup firefox --new-window "$URL" >/dev/null 2>&1 &
    
    # Sleep to allow the compositor to 'settle' and potentially trigger the race condition
    sleep $DELAY
    
    # OPTIONAL: Manually maximize the window here if you want to test the edge-tiling fix.
    # But since we disabled it, just the opening act is the test.
done

echo "[4/4] Test Complete. Monitor for 30 seconds."
echo "If GNOME has not crashed yet, try manually resizing one of the windows now."
echo "Press ENTER to cleanup closed windows (kills firefox processes)."
read -r

# Cleanup
echo "Cleaning up..."
if [[ -n "$GL_PID" ]]; then kill $GL_PID; fi
pkill -f "firefox"
echo "Done."