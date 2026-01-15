#!/usr/bin/env bash

# ## [ -0 ] ZENOS REBUILD TOOL
# Wrapper for nixos-rebuild with Tmux safety, notifications, resource optimization, and automation.

set -e

# --- Configuration & Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

SESSION_NAME="zenos-rebuild"

# --- Notification Helper ---
notify() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    
    # Send desktop notification if available
    if command -v notify-send &> /dev/null; then
        notify-send -u "$urgency" -i "zenos-symbolic" -a "ZenOS Rebuild" "$title" "$message" 2>/dev/null || true
    fi
}

# --- 1. Tmux Safety Check ---
# If we are not inside tmux, re-launch self inside tmux
if [ -z "$TMUX" ]; then
    echo -e "${YELLOW}[Safety] Not in Tmux. Launching safe-mode session...${NC}"
    
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        exec tmux attach-session -t "$SESSION_NAME"
    else
        # Create detached session first to configure it
        tmux new-session -d -s "$SESSION_NAME"
        
        # Enable Mouse (Scrolling) and increase History Limit
        tmux set-option -t "$SESSION_NAME" mouse on
        tmux set-option -t "$SESSION_NAME" history-limit 50000
        
        # Send the command to the session
        # We pass "$@" to ensure flags like -r or -l are preserved inside the session
        tmux send-keys -t "$SESSION_NAME" "bash $0 $@; echo -e '\nPress Enter to exit...'; read; exit" C-m
        
        # Attach to the configured session
        exec tmux attach-session -t "$SESSION_NAME"
    fi
fi

# --- 2. Resource Optimization ---
# Calculate cores to prevent UI freeze during heavy compiles
TOTAL_CORES=$(nproc)
# Reserve 2 cores for system responsiveness, minimum 1
MAX_JOBS=$((TOTAL_CORES - 2))
[ $MAX_JOBS -lt 1 ] && MAX_JOBS=1
# Limit per-job cores to keep context switching low
CORES_PER_JOB=2

# --- 3. Host & Flake Detection ---
TARGET_HOST=$(hostname)
FLAKE_PATH=""
FORCE_HOST=""
AUTO_REBOOT=false
AUTO_LOGOUT=false

# Argument Parsing
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--host)
        FORCE_HOST="$2"
        shift 2
        ;;
        -d|--dir)
        FLAKE_PATH="$2"
        shift 2
        ;;
        -r|--reboot)
        AUTO_REBOOT=true
        shift
        ;;
        -l|--logout)
        AUTO_LOGOUT=true
        shift
        ;;
        *)
        # Pass unknown args to nixos-rebuild eventually? 
        # For now, we assume simple usage.
        break
        ;;
    esac
done

if [ -n "$FORCE_HOST" ]; then
    TARGET_HOST="$FORCE_HOST"
fi

# Locate Flake
if [ -n "$FLAKE_PATH" ]; then
    # User specified path
    if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        echo -e "${RED}[!] Error: No flake.nix found at $FLAKE_PATH${NC}"
        notify "Error" "No flake.nix found at $FLAKE_PATH" "critical"
        exit 1
    fi
elif [ -f "$PWD/flake.nix" ]; then
    FLAKE_PATH="$PWD"
elif [ -f "$HOME/zenos-config/flake.nix" ]; then
    FLAKE_PATH="$HOME/zenos-config"
elif [ -f "/etc/nixos/flake.nix" ]; then
    FLAKE_PATH="/etc/nixos"
else
    echo -e "${RED}[!] Error: Could not locate flake.nix${NC}"
    notify "Error" "Could not locate flake.nix in PWD, ~/zenos-config, or /etc/nixos." "critical"
    exit 1
fi

FLAKE_URI="${FLAKE_PATH}#${TARGET_HOST}"

# --- 4. Execution ---
notify "Rebuild Started" "Target: $TARGET_HOST" "normal"

echo -e "${BLUE}========================================${NC}"
echo -e "  ${GREEN}ZenOS Rebuild${NC}"
echo -e "  Target: ${YELLOW}${FLAKE_URI}${NC}"
echo -e "  Optimization: ${YELLOW}-j${MAX_JOBS} -c${CORES_PER_JOB}${NC}"
if [ "$AUTO_REBOOT" = true ]; then
    echo -e "  Post-Action: ${RED}AUTO-REBOOT ENABLED${NC}"
elif [ "$AUTO_LOGOUT" = true ]; then
    echo -e "  Post-Action: ${YELLOW}AUTO-LOGOUT ENABLED${NC}"
fi
echo -e "${BLUE}========================================${NC}"

# Temporarily disable 'set -e' to capture exit code manually
set +e

# Run the build directly.
sudo nixos-rebuild switch \
    --flake "$FLAKE_URI" \
    --show-trace \
    --print-build-logs \
    --option max-jobs "$MAX_JOBS" \
    --option cores "$CORES_PER_JOB" \
    --option accept-flake-config true

EXIT_CODE=$?

# Re-enable strict mode
set -e

echo -e "${BLUE}========================================${NC}"

if [ $EXIT_CODE -eq 0 ]; then
    notify "Rebuild Complete" "System switched successfully." "normal"
    echo -e "${GREEN}SUCCESS: System updated.${NC}"

    # Handle Automation Flags (Only on Success)
    if [ "$AUTO_REBOOT" = true ]; then
        echo -e "${RED}[!] REBOOTING IN 3 SECONDS... (Ctrl+C to cancel)${NC}"
        notify "System" "Rebooting in 3 seconds..." "critical"
        sleep 3
        sudo reboot
    elif [ "$AUTO_LOGOUT" = true ]; then
        echo -e "${YELLOW}[!] LOGGING OUT IN 3 SECONDS... (Ctrl+C to cancel)${NC}"
        notify "System" "Logging out in 3 seconds..." "critical"
        sleep 3
        # Attempt to terminate the current session gracefully via systemd
        loginctl terminate-session "${XDG_SESSION_ID:-self}" || kill -9 -1
    fi

elif [ $EXIT_CODE -eq 130 ]; then
    # 130 is the standard exit code for SIGINT (Ctrl+C)
    notify "Rebuild Interrupted" "Operation cancelled by user." "low"
    echo -e "${YELLOW}INFO: Rebuild cancelled by user (Exit Code: 130).${NC}"
    exit 0
else
    notify "Rebuild Failed" "Check the terminal logs for details." "critical"
    echo -e "${RED}FAILURE: Rebuild encountered errors (Exit Code: $EXIT_CODE).${NC}"
    exit $EXIT_CODE
fi