{ config, pkgs, lib, ... }:

{
  home.username = "sheb";
  home.homeDirectory = "/home/sheb";
  home.stateVersion = "26.05";
  
  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
  
  catppuccin = {
    enable = true;
	autoEnable = true;
	flavor = "mocha";
	accent = "mauve";
	gtk.icon.enable = false;
  };

  imports = [
  	./modules/packages.nix
	./modules/theme.nix
	./modules/zsh.nix
	./modules/labwc.nix
	./modules/mango.nix
	./modules/quickshell.nix
	./modules/waybar.nix
	./modules/mako.nix
	./modules/rofi.nix
	./modules/alacritty.nix
	./modules/btop.nix
	./modules/yazi.nix
	./modules/nvim.nix
	./modules/thunar.nix
	./modules/vlc.nix
	./modules/flameshot.nix
	./modules/obs.nix
	./modules/dorion.nix
	./modules/libreoffice.nix
  ];
}
