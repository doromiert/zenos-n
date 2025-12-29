# contains stuff like ssh and default shell
{ pkgs, ... }:{

    programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;

        zplug = {
            enable = true;
            plugins = [
                { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
            ];
        };

        history.size = 10000;

        # [P13.9] Practical Aliases using eza
        shellAliases = {
            # The 'eza' suite
            ls = "eza --icons=always --group-directories-first";
            ll = "eza -lah --icons=always --group-directories-first --git";
            lt = "eza --tree --level=2 --icons=always";
            
            # NixOS Management
            nos = "sudo nixos-rebuild switch";
            noc = "sudo nix-collect-garbage -d";
        };

        initExtra = ''
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

    # SSH Service (Keeping the server enabled, but removing the shell shortcuts)
    services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.PermitRootLogin = "no";
    };

    environment.systemPackages = with pkgs; [
        eza
        fzf
        zsh-powerlevel10k
    ];
}