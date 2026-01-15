#!/usr/bin/env bash

# Check if running as root (required for plymouthd)
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)."
  exit
fi

echo "--- ZenOS Plymouth Preview Tool ---"
echo "1. Killing old plymouth daemon..."
plymouth quit 2>/dev/null

echo "2. Starting plymouthd in debug mode..."
# We point plymouthd to the system theme path. 
# NOTE: Ensure you have run 'nixos-rebuild switch' at least once with the new branding 
# so the files exist in /run/current-system/sw/share/plymouth/themes/zenos
# OR define the path explicitly if you built it locally.

export PLYMOUTH_THEME_NAME=zenos
plymouthd --debug --tty=/dev/tty --no-daemon &
PID=$!

# Give it a second to initialize
sleep 2

echo "3. Showing Splash..."
plymouth show-splash

echo "4. Press 'Q' or 'Esc' to quit (or wait 10s)..."
read -t 10 -n 1

echo "Exiting..."
plymouth quit
wait $PID