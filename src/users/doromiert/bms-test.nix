{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.programs.blur-my-shell;

  # --- Helpers for Types ---
  mkBool =
    default: description:
    mkOption {
      type = types.bool;
      default = default;
      description = description;
    };

  mkInt =
    default: description:
    mkOption {
      type = types.int;
      default = default;
      description = description;
    };

  mkDouble =
    default: description:
    mkOption {
      type = types.float;
      default = default;
      description = description;
    };

  mkColor =
    default: description:
    mkOption {
      type = types.str;
      default = default;
      description = description;
    };

  # --- Pipeline & Effect Submodules ---
  pipelineSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Human readable name of the pipeline.";
      };
      effects = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = "List of effects. Supports simplified syntax (e.g. { blur.gaussian = { ... }; }).";
      };
    };
  };

  # --- Shared Options ---
  commonBlurOptions = {
    blur = mkBool true "Whether to activate blur for this component.";
    customize = mkBool false "Whether to customize sigma/brightness or use global values.";
    sigma = mkInt 30 "Gaussian sigma (blur strength).";
    brightness = mkDouble 0.6 "Brightness of the blur effect.";
    color = mkColor "(0.0,0.0,0.0,0.0)" "Color to mix with the blur (GVariant tuple string).";
    noise-amount = mkDouble 0.0 "Amount of noise to add.";
    noise-lightness = mkDouble 0.0 "Lightness of the noise.";
  };

  mkComponent =
    extraOptions:
    types.submodule {
      options = commonBlurOptions // extraOptions;
    };

  # --- GVariant Serialization Logic ---

  mkVariant = v: "<${v}>";
  mkString = v: "'${v}'";

  # Ensure floats always have a decimal point to avoid Int32 mismatch errors in GVariant
  mkFloat =
    v:
    let
      s = toString v;
    in
    if builtins.match ".*\\..*" s == null then "${s}.0" else s;

  serializeValue =
    v:
    if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isInt v then
      toString v
    else if builtins.isFloat v then
      mkFloat v
    else if builtins.isString v then
      mkString v
    else
      throw "Unsupported type in pipeline params: ${builtins.typeOf v}";

  serializeParams =
    params:
    if params == { } then
      "@a{sv} {}"
    else
      let
        # Sort keys to ensure deterministic output
        keys = builtins.sort (a: b: a < b) (builtins.attrNames params);
        pairs = map (k: "${mkString k}: ${mkVariant (serializeValue params.${k})}") keys;
      in
      "{${concatStringsSep ", " pairs}}";

  # Pad IDs to 12 digits (e.g. effect_000000000001) to match dconf behavior
  padId =
    index:
    let
      s = toString index;
      zeros = "000000000000"; # 12 zeros
    in
    "effect_${builtins.substring 0 (12 - builtins.stringLength s) zeros}${s}";

  normalizeEffect =
    index: effectAttrs:
    let
      genId = padId index;

      process = type: params: {
        inherit type params;
        id = if effectAttrs ? id then effectAttrs.id else genId;
      };
    in
    if effectAttrs ? blur.gaussian then
      process "native_static_gaussian_blur" effectAttrs.blur.gaussian
    else if effectAttrs ? blur.monte_carlo then
      process "monte_carlo_blur" effectAttrs.blur.monte_carlo
    else if effectAttrs ? corner then
      process "corner" effectAttrs.corner
    else if effectAttrs ? noise then
      process "noise" effectAttrs.noise
    else if effectAttrs ? color then
      process "color" effectAttrs.color
    else if effectAttrs ? pixelize then
      process "pixelize" effectAttrs.pixelize
    else if effectAttrs ? derivative then
      process "derivative" effectAttrs.derivative
    else if effectAttrs ? type then
      process effectAttrs.type (effectAttrs.params or { })
    else
      throw "Unknown effect type in pipeline configuration";

  serializeEffect =
    index: effectAttrs:
    let
      norm = normalizeEffect index effectAttrs;
      # The dictionary itself is built here
      dict = "{'type': ${mkVariant (mkString norm.type)}, 'id': ${mkVariant (mkString norm.id)}, 'params': ${mkVariant (serializeParams norm.params)}}";
    in
    # CRITICAL FIX: The dictionary MUST be wrapped in a variant <{...}> because 'effects' is an array of variants (av)
    mkVariant dict;

  serializePipeline =
    pipeline:
    let
      serializedEffects = imap0 serializeEffect pipeline.effects;
    in
    "{'name': ${mkVariant (mkString pipeline.name)}, 'effects': ${mkVariant "[${concatStringsSep ", " serializedEffects}]"}}";

in
{
  options.programs.blur-my-shell = {
    enable = mkEnableOption "Blur My Shell GNOME extension configuration";

    # --- General Settings ---
    general = {
      settings-version = mkInt 1 "Settings version.";
      sigma = mkInt 30 "Global gaussian sigma.";
      brightness = mkDouble 0.6 "Global brightness.";
      color = mkColor "(0.0,0.0,0.0,0.0)" "Global color mix.";
      noise-amount = mkDouble 0.0 "Global noise amount.";
      noise-lightness = mkDouble 0.0 "Global noise lightness.";
      color-and-noise = mkBool true "Whether color and noise effects are used globally.";
      hacks-level = mkInt 1 "Level of hacks to use (0-2).";
      debug = mkBool false "Enable verbose logging.";

      pipelines = mkOption {
        description = "Pipeline definitions.";
        type = types.attrsOf pipelineSubmodule;
        default = { };
      };
    };

    # --- Components ---

    overview = mkOption {
      description = "Overview configuration.";
      type = mkComponent {
        pipeline = mkOption {
          type = types.str;
          default = "pipeline_default";
        };
        style-components = mkInt 1 "Style of components (0: none, 1: light, 2: dark, 3: transparent).";
      };
      default = { };
    };

    appfolder = mkOption {
      description = "Appfolder configuration.";
      type = mkComponent {
        style-dialogs = mkInt 1 "Style of dialogs (0: none, 1: transparent, 2: light, 3: dark).";
      };
      default = { };
    };

    panel = mkOption {
      description = "Top Panel configuration.";
      type = mkComponent {
        pipeline = mkOption {
          type = types.str;
          default = "pipeline_default";
        };
        static-blur = mkBool true "Use static blur.";
        unblur-in-overview = mkBool true "Disable blur in overview.";
        force-light-text = mkBool false "Force light text on panel.";
        override-background = mkBool true "Override panel background.";
        style-panel = mkInt 0 "Panel style (0: transparent, 1: light, 2: dark, 3: contrasted).";
        override-background-dynamically = mkBool false "Dynamically unblur when windows approach.";
      };
      default = { };
    };

    dash-to-dock = mkOption {
      description = "Dash to Dock integration.";
      type = mkComponent {
        pipeline = mkOption {
          type = types.str;
          default = "pipeline_default_rounded";
        };
        static-blur = mkBool true "Use static blur.";
        override-background = mkBool true "Override background.";
        style-dash-to-dock = mkInt 0 "Style (0: transparent, 1: light, 2: dark).";
        unblur-in-overview = mkBool false "Unblur in overview.";
        corner-radius = mkInt 12 "Corner radius for rounding effect.";
      };
      default = { };
    };

    applications = mkOption {
      description = "Per-application blur configuration.";
      type = mkComponent {
        opacity = mkInt 215 "Opacity of window actor.";
        dynamic-opacity = mkBool true "Make focused window opaque.";
        blur-on-overview = mkBool false "Blur applications in overview.";
        enable-all = mkBool false "Blur all applications by default.";
        whitelist = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Apps to always blur.";
        };
        blacklist = mkOption {
          type = types.listOf types.str;
          default = [
            "Plank"
            "com.desktop.ding"
            "Conky"
          ];
          description = "Apps to never blur.";
        };
      };
      default = {
        blur = false;
        customize = true;
        brightness = 1.0;
      };
    };

    screenshot = mkOption {
      description = "Screenshot UI configuration.";
      type = mkComponent {
        pipeline = mkOption {
          type = types.str;
          default = "pipeline_default";
        };
      };
      default = { };
    };

    lockscreen = mkOption {
      description = "Lockscreen configuration.";
      type = mkComponent {
        pipeline = mkOption {
          type = types.str;
          default = "pipeline_default";
        };
      };
      default = { };
    };

    window-list = mkOption {
      description = "Window List extension integration.";
      type = mkComponent {
        pipeline = mkOption {
          type = types.str;
          default = "pipeline_default";
        };
      };
      default = { };
    };

    coverflow-alt-tab = mkOption {
      description = "Coverflow Alt-Tab integration.";
      type = types.submodule {
        options = {
          blur = mkBool true "Enable blur.";
          pipeline = mkOption {
            type = types.str;
            default = "pipeline_default";
          };
        };
      };
      default = { };
    };

    hidetopbar = mkOption {
      description = "Hide Top Bar integration.";
      type = types.submodule {
        options = {
          compatibility = mkBool false "Try compatibility with hidetopbar extension.";
        };
      };
      default = { };
    };

    dash-to-panel = mkOption {
      description = "Dash to Panel integration.";
      type = types.submodule {
        options = {
          blur-original-panel = mkBool true "Blur original panel with Dash to Panel.";
        };
      };
      default = { };
    };
  };

  # --- Implementation ---

  config = mkIf cfg.enable {
    home.activation.bms-pipelines = ''
      ${pkgs.dconf}/bin/dconf write /org/gnome/shell/extensions/blur-my-shell/pipelines "{${
        concatStringsSep ", " (
          mapAttrsToList (id: pipe: "${mkString id}: ${serializePipeline pipe}") cfg.general.pipelines
        )
      }}"
    '';

    dconf.settings = {

      # General
      "org/gnome/shell/extensions/blur-my-shell" = {
        settings-version = cfg.general.settings-version;
        sigma = cfg.general.sigma;
        brightness = cfg.general.brightness;
        color = cfg.general.color;
        noise-amount = cfg.general.noise-amount;
        noise-lightness = cfg.general.noise-lightness;
        color-and-noise = cfg.general.color-and-noise;
        hacks-level = cfg.general.hacks-level;
        debug = cfg.general.debug;
      };

      # Overview
      "org/gnome/shell/extensions/blur-my-shell/overview" = {
        blur = cfg.overview.blur;
        pipeline = cfg.overview.pipeline;
        customize = cfg.overview.customize;
        sigma = cfg.overview.sigma;
        brightness = cfg.overview.brightness;
        color = cfg.overview.color;
        noise-amount = cfg.overview.noise-amount;
        noise-lightness = cfg.overview.noise-lightness;
        style-components = cfg.overview.style-components;
      };

      # Appfolder
      "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
        blur = cfg.appfolder.blur;
        customize = cfg.appfolder.customize;
        sigma = cfg.appfolder.sigma;
        brightness = cfg.appfolder.brightness;
        color = cfg.appfolder.color;
        noise-amount = cfg.appfolder.noise-amount;
        noise-lightness = cfg.appfolder.noise-lightness;
        style-dialogs = cfg.appfolder.style-dialogs;
      };

      # Panel
      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        blur = cfg.panel.blur;
        pipeline = cfg.panel.pipeline;
        customize = cfg.panel.customize;
        sigma = cfg.panel.sigma;
        brightness = cfg.panel.brightness;
        color = cfg.panel.color;
        noise-amount = cfg.panel.noise-amount;
        noise-lightness = cfg.panel.noise-lightness;
        static-blur = cfg.panel.static-blur;
        unblur-in-overview = cfg.panel.unblur-in-overview;
        force-light-text = cfg.panel.force-light-text;
        override-background = cfg.panel.override-background;
        style-panel = cfg.panel.style-panel;
        override-background-dynamically = cfg.panel.override-background-dynamically;
      };

      # Dash to Dock
      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = cfg.dash-to-dock.blur;
        pipeline = cfg.dash-to-dock.pipeline;
        customize = cfg.dash-to-dock.customize;
        sigma = cfg.dash-to-dock.sigma;
        brightness = cfg.dash-to-dock.brightness;
        color = cfg.dash-to-dock.color;
        noise-amount = cfg.dash-to-dock.noise-amount;
        noise-lightness = cfg.dash-to-dock.noise-lightness;
        static-blur = cfg.dash-to-dock.static-blur;
        override-background = cfg.dash-to-dock.override-background;
        style-dash-to-dock = cfg.dash-to-dock.style-dash-to-dock;
        unblur-in-overview = cfg.dash-to-dock.unblur-in-overview;
        corner-radius = cfg.dash-to-dock.corner-radius;
      };

      # Applications
      "org/gnome/shell/extensions/blur-my-shell/applications" = {
        blur = cfg.applications.blur;
        customize = cfg.applications.customize;
        sigma = cfg.applications.sigma;
        brightness = cfg.applications.brightness;
        color = cfg.applications.color;
        noise-amount = cfg.applications.noise-amount;
        noise-lightness = cfg.applications.noise-lightness;
        opacity = cfg.applications.opacity;
        dynamic-opacity = cfg.applications.dynamic-opacity;
        blur-on-overview = cfg.applications.blur-on-overview;
        enable-all = cfg.applications.enable-all;
        whitelist = cfg.applications.whitelist;
        blacklist = cfg.applications.blacklist;
      };

      # Screenshot
      "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
        blur = cfg.screenshot.blur;
        pipeline = cfg.screenshot.pipeline;
        customize = cfg.screenshot.customize;
        sigma = cfg.screenshot.sigma;
        brightness = cfg.screenshot.brightness;
        color = cfg.screenshot.color;
        noise-amount = cfg.screenshot.noise-amount;
        noise-lightness = cfg.screenshot.noise-lightness;
      };

      # Lockscreen
      "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
        blur = cfg.lockscreen.blur;
        pipeline = cfg.lockscreen.pipeline;
        customize = cfg.lockscreen.customize;
        sigma = cfg.lockscreen.sigma;
        brightness = cfg.lockscreen.brightness;
        color = cfg.lockscreen.color;
        noise-amount = cfg.lockscreen.noise-amount;
        noise-lightness = cfg.lockscreen.noise-lightness;
      };

      # Window List
      "org/gnome/shell/extensions/blur-my-shell/window-list" = {
        blur = cfg.window-list.blur;
        pipeline = cfg.window-list.pipeline;
        customize = cfg.window-list.customize;
        sigma = cfg.window-list.sigma;
        brightness = cfg.window-list.brightness;
        color = cfg.window-list.color;
        noise-amount = cfg.window-list.noise-amount;
        noise-lightness = cfg.window-list.noise-lightness;
      };

      # Coverflow Alt-Tab
      "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
        blur = cfg.coverflow-alt-tab.blur;
        pipeline = cfg.coverflow-alt-tab.pipeline;
      };

      # Hide Topbar
      "org/gnome/shell/extensions/blur-my-shell/hidetopbar" = {
        compatibility = cfg.hidetopbar.compatibility;
      };

      # Dash to Panel
      "org/gnome/shell/extensions/blur-my-shell/dash-to-panel" = {
        blur-original-panel = cfg.dash-to-panel.blur-original-panel;
      };
    };
  };
}
