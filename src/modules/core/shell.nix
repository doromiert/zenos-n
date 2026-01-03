# contains stuff like ssh and default shell
{ pkgs, config, lib, ... }:
let
  # [ ACTION ] Define zenos-rebuild as a standalone script
  zenosRebuild = pkgs.writeShellScriptBin "zenos-rebuild" ''
    # ZenOS Rebuild Wrapper
    # Optimizations: Auto-Host, Hyper-Parallelism, Notifications, Smart Path

    set -e

    # --- 0. Flags & Arguments ---
    CLEAN_MODE=false
    EXTRA_ARGS=""

    for arg in "$@"; do
        if [[ "$arg" == "--clean" ]]; then
            CLEAN_MODE=true
        else
            EXTRA_ARGS="$EXTRA_ARGS $arg"
        fi
    done

    # --- 1. Smart Path Detection ---
    # Priority: Current Dir > /etc/nixos > ~/Projects/zenos-n
    if [ -f "$PWD/flake.nix" ]; then
        FLAKE_PATH="$PWD"
        echo -e "\033[0;34m:: Detected flake in current directory.\033[0m"
    elif [ -f "/etc/nixos/flake.nix" ]; then
        FLAKE_PATH="/etc/nixos"
        echo -e "\033[0;34m:: Using system flake in /etc/nixos.\033[0m"
    elif [ -f "$HOME/Projects/zenos-n/flake.nix" ]; then
        FLAKE_PATH="$HOME/Projects/zenos-n"
        echo -e "\033[0;34m:: Using dev flake in ~/Projects/zenos-n.\033[0m"
    else
        echo -e "\033[0;31m!! No flake.nix found! Please run inside your config repo.\033[0m"
        exit 1
    fi

    # --- 2. Clean Mode (Optional) ---
    if [ "$CLEAN_MODE" = true ]; then
        echo -e "\033[0;33m:: Maintenance Mode: Cleaning Garbage...\033[0m"
        if command -v notify-send &> /dev/null; then
             notify-send -u low -a "ZenOS" "Maintenance" "Running garbage collection..."
        fi
        sudo nix-collect-garbage -d
        echo -e "\033[0;32m:: Trash taken out.\033[0m"
    fi

    # --- 3. Detect Hostname ---
    HOST=$(cat /etc/hostname)
    echo -e "\033[0;34m:: Rebuilding ZenOS for host: $HOST\033[0m"

    # --- 4. Notify Start ---
    if command -v notify-send &> /dev/null; then
        notify-send -u normal -a "ZenOS" "System Update" "Rebuilding configuration for $HOST..."
    fi

    # --- 5. Calculate Jobs (Hyper-Threading: Cores * 4) ---
    CORES=$(nproc)
    JOBS=$((CORES * 4))

    # --- 6. Execute Rebuild with Speed Flags ---
    # We use 'sudo' internally so the user can run 'zenos-rebuild' without sudo prefix
    if sudo nixos-rebuild switch \
        --flake "$FLAKE_PATH#$HOST" \
        --option max-jobs $JOBS \
        --option cores 0 \
        --option http-connections 128 \
        --option download-buffer-size 67108864 \
        --option keep-going true \
        $EXTRA_ARGS; then
        
        # 7. Success
        echo -e "\033[0;32m:: ZenOS Rebuild Complete.\033[0m"
        if command -v notify-send &> /dev/null; then
            GEN=$(nixos-rebuild list-generations | grep current | awk '{print $1}')
            notify-send -u normal -a "ZenOS" "Update Successful" "System is now running generation $GEN."
        fi
        
        # 8. Post-Install Integrity Check (Optional but cool)
        echo -e "\033[0;34m:: Verifying integrity...\033[0m"
        if [ -d "/Boot" ] && [ -L "/Boot" ]; then
             echo -e "\033[0;32m[OK] NZFS Boot Link active.\033[0m"
        fi
    else
        # 9. Failure
        echo -e "\033[0;31m!! ZenOS Rebuild Failed.\033[0m"
        if command -v notify-send &> /dev/null; then
            notify-send -u critical -a "ZenOS" "Update Failed" "Check terminal output for errors."
        fi
        exit 1
    fi
  '';
in
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    histSize = 10000;

    # [P13.9] Practical Aliases using eza
    shellAliases = {
      # The 'eza' suite
      ls = "eza --icons=always --group-directories-first";
      ll = "eza -lah --icons=always --group-directories-first --git";
      lt = "eza --tree --level=2 --icons=always";

      # NixOS Management
      # [ CHANGE ] Point alias to our new smart script
      nos = "zenos-rebuild"; 
      noc = "sudo nix-collect-garbage -d";
    };

    shellInit = ''
      # Navigation: Search-based keys + word-jumping (Ctrl + Arrows)
      bindkey "^[[A" up-line-or-search
      bindkey "^[[B" down-line-or-search
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      # P10k instant prompt logic for performance
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };

  # SSH Service
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  environment.systemPackages = with pkgs; [
    eza
    fzf
    tree
    zsh-powerlevel10k
    
    # [ NEW ] The Rebuild Script
    zenosRebuild
    libnotify # Ensure notify-send is available system-wide
  ];
}
