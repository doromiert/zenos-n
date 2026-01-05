#!/usr/bin/env bash
set -e

# ==========================================
# zenos-rebuild (Safe Mode)
# ==========================================
# Wraps nixos-rebuild in a tmux session to prevent
# system corruption if the terminal emulator crashes.
# ==========================================

SESSION_NAME="zenos-rebuild"

# Resolve the absolute path to the flake directory before we change directories
# Assumes script is in scripts/ and flake is in parent dir
SCRIPT_PATH=$(readlink -f "$0")
FLAKE_DIR=$(realpath "$(dirname "$SCRIPT_PATH")/..")
FLAGS="--show-trace"

# 1. Ensure Tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "❌ Error: tmux is not installed."
    echo "   Please add 'pkgs.tmux' to your system packages or run 'nix-shell -p tmux'."
    exit 1
fi

# 2. Check if we are already inside the safety session
if [ -n "$TMUX" ]; then
    echo "🛡️  Inside Safe Session. Starting Rebuild..."
    
    # Change directory to HOME to get out of the Nix Store evaluation path
    cd "$HOME"
    
    # Run the actual rebuild using the absolute path to the flake
    sudo nixos-rebuild switch --flake "$FLAKE_DIR" $FLAGS
    
    echo "✅ Rebuild Complete."
    # We leave the shell open so you can read logs
else
    echo "🚀 Launching Safe Rebuild Session..."
    
    # Check for existing session to re-attach
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "   Attached to running session..."
        tmux attach-session -t "$SESSION_NAME"
    else
        # Create new session
        # We explicitly cd $HOME inside the tmux command string as well
        CMD="cd $HOME; sudo nixos-rebuild switch --flake \"$FLAKE_DIR\" $FLAGS; echo '--------------------------------'; echo 'Press Enter to close session...'; read"
        
        tmux new-session -s "$SESSION_NAME" "$CMD"
    fi
fi