{ config, pkgs, lib, ... }:

{
  home.username = "sheb";
  home.homeDirectory = "/home/sheb";
  home.stateVersion = "26.05";
  
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    yazi
    fastfetch
  ];

  catppuccin = {
    enable = true;
	autoEnable = true;
	flavor = "mocha";
  };

  programs.btop.enable = true;
  
  programs.neovim = {
    enable = true;

	viAlias = true;
	vimAlias = true;
  };
  home.file.".config/nvim".source = ./config/nvim;
  
  home.file.".config/waybar".source = ./config/waybar;

  home.file.".config/mako".source = ./config/mako;
  
  home.file.".config/labwc".source = ./config/labwc;
}
