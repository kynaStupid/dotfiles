{ config, pkgs, lib, ... }:

{
  home.username = "sheb";
  home.homeDirectory = "/home/sheb";
  home.stateVersion = "26.05";
  
  programs.home-manager.enable = true;
  
  catppuccin = {
    enable = true;
	autoEnable = true;
	flavor = "mocha";
  };

  imports = [
  	./modules/packages.nix
	./modules/nvim.nix
	./modules/waybar.nix
	./modules/labwc.nix
	./modules/mako.nix
	./modules/btop.nix
	./modules/yazi.nix
  ];
}
