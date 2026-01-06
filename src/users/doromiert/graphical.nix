{
  inputs,
  ...
}:
{
  # Ensure the Nixcord module is imported

  home-manager.users.doromiert =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        ./shortcuts.nix
        ./dconf.nix
        ./pwa.nix
        ./keepass.nix
        inputs.nixcord.homeModules.nixcord
      ];
      #home.file.".config/forge/config/windows.json".source = ./resources/windows.json;

      # Regular packages
      home.packages = with pkgs; [
        telegram-desktop
        # [P13.D] Ensure formatter is available for the LSP
        nixfmt-rfc-style
      ];

      # [USER SPECIFIC] VS Code Overrides
      # This extends the base configuration defined in dev.nix
      programs.vscode = {
        # The Vim Addon (User Preference)
        extensions = [ pkgs.vscode-extensions.vscodevim.vim ];

        # Merged from settings.json
        userSettings = {
          # Existing Nix overrides
          "vim.useSystemClipboard" = true;
          "vim.hlsearch" = true;
          "editor.selectionClipboard" = false;
          # [ADDED] Visual Navigation Plugins
          # 'easymotion' highlights all possible targets for a motion (like 'fs') with a key to jump to.
          # Usage: <Leader><Leader> + f + <char>
          "vim.easymotion" = true;
          # 'sneak' allows jumping to any location specified by two characters (like 'st')
          "vim.sneak" = true;

          # JSON Configs
          "editor.formatOnSave" = true;
          "editor.suggest.insertMode" = "replace";
          "editor.linkedEditing" = true;
          "javascript.updateImportsOnFileMove.enabled" = "always";
          "window.zoomLevel" = 0.25;
          "launch" = { };
          "[json]" = { };
          "workbench.statusBar.visible" = true;
          "editor.minimap.enabled" = false;
          "breadcrumbs.enabled" = false;

          "update.showReleaseNotes" = false;
          "workbench.activityBar.visible" = true;
          "zenMode.hideLineNumbers" = false;
          "zenMode.hideTabs" = false;
          "editor.lineNumbers" = "relative";

          "vim.leader" = "<Space>";

          # Vim Keybindings (Kept in settings as they are plugin-specific settings)
          "vim.normalModeKeyBindingsNonRecursive" = [
            # NAVIGATION
            # switch b/w buffers
            {
              before = [ "<S-h>" ];
              commands = [ ":bprevious" ];
            }
            {
              before = [ "<S-l>" ];
              commands = [ ":bnext" ];
            }

            # splits
            {
              before = [
                "leader"
                "v"
              ];
              commands = [ ":vsplit" ];
            }
            {
              before = [
                "leader"
                "s"
              ];
              commands = [ ":split" ];
            }

            # panes
            {
              before = [
                "leader"
                "h"
              ];
              commands = [ "workbench.action.focusLeftGroup" ];
            }
            {
              before = [
                "leader"
                "j"
              ];
              commands = [ "workbench.action.focusBelowGroup" ];
            }
            {
              before = [
                "leader"
                "k"
              ];
              commands = [ "workbench.action.focusAboveGroup" ];
            }
            {
              before = [
                "leader"
                "l"
              ];
              commands = [ "workbench.action.focusRightGroup" ];
            }
            # NICE TO HAVE
            {
              before = [
                "leader"
                "w"
              ];
              commands = [ ":w!" ];
            }
            {
              before = [
                "leader"
                "q"
              ];
              commands = [ ":q!" ];
            }
            {
              before = [
                "leader"
                "x"
              ];
              commands = [ ":x!" ];
            }
            {
              before = [
                "["
                "d"
              ];
              commands = [ "editor.action.marker.prev" ];
            }
            {
              before = [
                "]"
                "d"
              ];
              commands = [ "editor.action.marker.next" ];
            }
            {
              before = [
                "<leader>"
                "c"
                "a"
              ];
              commands = [ "editor.action.quickFix" ];
            }
            {
              before = [
                "leader"
                "f"
              ];
              commands = [ "workbench.action.quickOpen" ];
            }
            {
              before = [
                "leader"
                "p"
              ];
              commands = [ "editor.action.formatDocument" ];
            }
            {
              before = [
                "g"
                "h"
              ];
              commands = [ "editor.action.showDefinitionPreviewHover" ];
            }
          ];

          "vim.visualModeKeyBindings" = [
            # Stay in visual mode while indenting
            {
              before = [ "<" ];
              commands = [ "editor.action.outdentLines" ];
            }
            {
              before = [ ">" ];
              commands = [ "editor.action.indentLines" ];
            }
            # Move selected lines while staying in visual mode
            {
              before = [ "J" ];
              commands = [ "editor.action.moveLinesDownAction" ];
            }
            {
              before = [ "K" ];
              commands = [ "editor.action.moveLinesUpAction" ];
            }
            # toggle comment selection
            {
              before = [
                "leader"
                "c"
              ];
              commands = [ "editor.action.commentLine" ];
            }
          ];

          "[typescriptreact]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "go.toolsManagement.autoUpdate" = true;
          "[typescript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[jsonc]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
        };
      };

      # [Masking] Create a "Discord" desktop entry that launches Vesktop
      # This ensures discord:// links work and it appears as "Discord" in the launcher.
      xdg.desktopEntries.discord = {
        name = "Discord";
        genericName = "Internet Messenger";
        exec = "vesktop %U";
        icon = "discord";
        type = "Application";
        categories = [
          "Network"
          "InstantMessaging"
        ];
        mimeType = [ "x-scheme-handler/discord" ];
        # [FIX] Link the running 'vesktop' window to this 'Discord' shortcut
        # This solves the issue of separate/generic icons appearing in the dock on Wayland.
        settings = {
          StartupWMClass = "vesktop";
          Keywords = "discord;vencord;vesktop;";
        };
      };

      programs.nixcord = {
        enable = true;

        # [SWITCHED] Using Vesktop instead of official Discord
        # Better Wayland support, screen sharing with audio, and performance.

        discord.enable = false;
        vesktop = {
          enable = true;
          autoscroll.enable = true;
          state = {
            "firstLaunch" = false;
            "windowBounds" = {
              "x" = 0;
              "y" = 0;
              "width" = 0;
              "height" = 0;
            };
          };
          settings = {
            "hardwareVideoAcceleration" = true;
            "customTitleBar" = true;
            "staticTitle" = false;
          };
        };

        config = {
          useQuickCss = true;
          disableMinSize = true;

          # [FIX] Load themes into the menu as well, just in case QuickCSS fails.
          themeLinks = [
            "https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css"
            # "https://raw.githubusercontent.com/ricewind012/discord-gnome-theme/master/gnome.theme.css"
            # ↑ broken, hopefully replaced by gord soon
          ];

          # Global Vencord Settings
          enabledThemes = [
            "discord-adblock.css"
            "gnome.theme.css"
          ];

          # Highly Practical Plugin Configuration [p13.9 focus]
          plugins = {
            # Essentials
            fakeNitro = {
              enable = true;
              transformEmojis = true;
            };

            themeAttributes.enable = true;

            # UI Improvements
            betterFolders = {
              enable = true;
              sidebar = true;
              sidebarAnim = true;
            };
            memberCount.enable = true;
            showHiddenThings.enable = true;
            PinDMs = {
              enable = true;
              canCollapseDmSection = true;
              pinOrder = 1;

              # Converted from JSON export
              # Note: Keys beginning with numbers must be quoted in Nix
              userBasedCategoryList = {
                "786127059020808192" = [
                  {
                    id = "pxjb5vmmgvq";
                    name = "anaxort";
                    color = 3447003;
                    collapsed = false;
                    channels = [ "1163390615875235850" ];
                  }
                  {
                    id = "pw400h4v3r8";
                    name = "pyxaxerei";
                    color = 10181046;
                    collapsed = false;
                    channels = [
                      "932002355006824518"
                      "1251984601346474137"
                      "1076666124596420658"
                      "1235474431854247947"
                      "1317442836534136832"
                      "1406532912115093597"
                      "1373419992690852033"
                      "1436806723032842282"
                      "950102506892042280"
                      "1370491641739218956"
                      "1068059647606521897"
                      "1002319154155622410"
                      "932155260695379988"
                      "853881398985490443"
                      "853859473462394890"
                      "1007987169777950750"
                      "1257274200683446304"
                      "1169986857422028850"
                      "1125888401720225864"
                      "932680448784621658"
                      "996098799418232902"
                      "1448774106609881143"
                      "1034497174853128283"
                      "1446931065846366320"
                      "1385202673149808673"
                      "1362263213546147952"
                      "931433605740240957"
                      "1344023312254242826"
                      "1265042253399855134"
                      "1442531824663396394"
                      "1080007672545415238"
                      "993870226259193927"
                      "1375899970053476554"
                      "962773292857573458"
                      "1438120331893149796"
                      "1320116227359641620"
                      "1436998598314295370"
                      "1056652715234701353"
                      "1065671896017928233"
                      "1435403641396920423"
                      "1435038376842760263"
                      "1149745026650353740"
                      "1432913066550493316"
                      "1361256971365519513"
                      "1377624366581284946"
                      "1383425235495157860"
                      "1427872016089874516"
                      "1425613934219628717"
                      "1378452184819302534"
                      "1134586397802635348"
                      "1161389907844014161"
                      "1408784983677735035"
                    ];
                  }
                  {
                    id = "giad3o5lhl9";
                    name = "kulupei";
                    color = 15277667;
                    collapsed = false;
                    channels = [
                      "1138946738695180288"
                      "1396015342270025749"
                      "1320177024685576242"
                      "1299480215503896609"
                    ];
                  }
                  {
                    id = "4f5sbjgmrg9";
                    name = "wtx";
                    color = 3066993;
                    collapsed = true;
                    channels = [
                      "1451158271871291585"
                      "1073688149999501312"
                      "1093616425198956655"
                      "942068119499849748"
                      "1184487132560101396"
                      "1433110846690824262"
                      "1412166821091479704"
                    ];
                  }
                  {
                    id = "ezzyxp82irr";
                    name = "work-ish";
                    color = 10070709;
                    collapsed = true;
                    channels = [ "1222475248792895550" ];
                  }
                ];
              };
            };

            # [REMOVED] 'noMinSize' is not supported by current Nixcord version.
            # Enable this manually in Vencord settings -> Plugins if needed.

            # Privacy & Utility
            callTimer.enable = true;
            ClearURLs.enable = true;
            CopyUserURLs.enable = true;

            # Performance/Fixes
            # vencordToolbox.enable = true;
            webKeybinds.enable = true;

            # [NOTE] Often redundant on Vesktop (it has native fixes), but harmless to keep.
            webScreenShareFixes.enable = true;

            youtubeAdblock.enable = true;

            # Custom RPC
            CustomRPC = {
              enable = true;
              config = {
                type = 0; # Playing
                name = "Sex 2";
                details = "Duos";
              };
            };
          };
        };

        # [FIX] Added quotes to URLs to ensure CSS validity
        quickCss = ''
          /* Discord AdBlock */
          @import url("https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css");

          /* Discord Gnome Theme */
          @import url("https://raw.githubusercontent.com/ricewind012/discord-gnome-theme/main/dist/discord-gnome-theme.theme.css");
        '';
      };
    };
}
