{ config, pkgs, lib, nixcord, ... }:

{
  imports = [ nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    legcord = {
      enable = true;
      vencord.enable = true;

      settings = {
        channel = "stable";
        tray = "dynamic";
        minimizeToTray = true;
        mods = [ "vencord" ];
        doneSetup = true;
      };
    };

    config = {
      useQuickCss = true;
      themeLinks = [
        "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
      ];
      frameless = true;

      plugins = {
	    
      };
    };
  };
}
