{ config, pkgs, lib, ... }:

{
  services.mako = {
    enable = true;
	settings = {
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#cba6f7";
      progress-color = "over #313244";

      border-radius = 16;
      padding = 14;
      margin = 12;

      width = 340;
      height = 120;
    };

    extraConfig = ''
      [urgency=high]
      border-color=#fab387
    '';
  };
}
