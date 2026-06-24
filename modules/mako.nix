{ config, pkgs, lib, ... }:

{
  services.mako = {
    enable = true;
	settings = {
	  actions = true;
	  anchor = "top-right";
	  default-timeout = 5;
	  layer = "top";

	  background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#cba6f7";
      progress-color = "over #313244";

      border-radius = 16;
      padding = 14;
      margin = 12;
	  icons = true;
	  markup = true;

      width = 300;
      height = 100;
    };

    extraConfig = ''
      [urgency=high]
      border-color=#fab387
    '';
  };
}
