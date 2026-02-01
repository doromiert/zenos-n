{
  pkgs,
  ...
}:
let
  p10kConfig = pkgs.writeText "p10k.zsh" (builtins.readFile ../../../resources/shell/p10k.zsh);
in
{
  security.sudo.extraRules = [
    {
      groups = [ "zenos-rebuild" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  users.groups.zenos-rebuild = { };

  environment.etc."zsh/p10k.zsh".source = p10kConfig;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    histSize = 10000;

    shellAliases = {
      ls = "eza --icons=always --group-directories-first --ignore-glob=.hidden";
      ll = "eza -lah --icons=always --group-directories-first --git --ignore-glob=.hidden";
      lt = "eza --tree --level=2 --icons=always";

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

      # [FIX] Source the system-wide config instead of the user one
      # We check if the global config exists and source it
      [[ ! -f /etc/zsh/p10k.zsh ]] || source /etc/zsh/p10k.zsh
    '';

  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  environment.systemPackages = with pkgs; [
    zenos.programs.zenos-rebuild
    eza
    fzf
    tree
    zsh-powerlevel10k
  ];
}
