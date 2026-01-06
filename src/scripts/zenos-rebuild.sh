set -e

        # ==========================================
        # zenos-rebuild (Safe Mode)
        # ==========================================
        
        SESSION_NAME="zenos-rebuild"
        FLAKE_DIR="~/Projects/zenos-n"
        FLAGS="--show-trace"

        # 1. Validation: Ensure the flake actually exists at the target path
        if [ ! -f "$FLAKE_DIR/flake.nix" ]; then
          echo "❌ Error: No flake.nix found at $FLAKE_DIR"
          echo "   Please edit 'flakeDir' in zenos-rebuild.nix to match your repo location."
          exit 1
        fi

        # 2. Check if we are already inside the safety session
        if [ -n "$TMUX" ]; then
            echo "🛡️  Inside Safe Session. Starting Rebuild..."
            
            # Move to HOME to ensure we aren't in a restrictive path
            cd "$HOME"
            
            # Run the rebuild
            sudo nixos-rebuild switch --flake "$FLAKE_DIR" $FLAGS
            
            echo "✅ Rebuild Complete."
        else
            echo "🚀 Launching Safe Rebuild Session..."
            
            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                echo "   Attached to running session..."
                tmux attach-session -t "$SESSION_NAME"
            else
                # Complex command to run inside tmux:
                # 1. cd Home
                # 2. Run Rebuild
                # 3. Pause for user to read logs
                CMD="cd $HOME; sudo nixos-rebuild switch --flake \"$FLAKE_DIR\" $FLAGS; echo '--------------------------------'; echo 'Press Enter to close session...'; read"
                
                tmux new-session -s "$SESSION_NAME" "$CMD"
            fi
    fi 