{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./bms-test.nix ];

  programs.blur-my-shell = {
    enable = true;

    general = {
      settings-version = 2;

      pipelines = {
        pipeline_default = {
          name = "Default";
          effects = [
            {
              blur.gaussian = {
                radius = 30;
                brightness = 0.3;
                unscaled_radius = 100;
              };
            }
            { noise = { }; }
          ];
        };

        pipeline_default_rounded = {
          name = "Default rounded";
          effects = [
            {
              blur.gaussian = {
                radius = 30;
                brightness = 0.6;
              };
            }
            {
              corner = {
                radius = 24;
              };
            }
          ];
        };
      };
    };

    appfolder = {
      brightness = 0.6;
      sigma = 30;
    };

    coverflow-alt-tab = {
      pipeline = "pipeline_default";
    };

    dash-to-dock = {
      blur = true;
      brightness = 0.6;
      pipeline = "pipeline_default_rounded";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0; # Transparent
    };

    lockscreen = {
      pipeline = "pipeline_default";
    };

    overview = {
      pipeline = "pipeline_default";
    };

    panel = {
      blur = false; # Explicitly disabled in your dump
      brightness = 0.6;
      pipeline = "pipeline_default";
      sigma = 30;
    };

    screenshot = {
      pipeline = "pipeline_default";
    };

    window-list = {
      brightness = 0.6;
      sigma = 30;
    };
  };
}
