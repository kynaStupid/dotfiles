{ config, pkgs, lib, ... }:

let
	username = "sheb";
in {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";
  
  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  imports = [
  	./modules/packages.nix
		./modules/theme-switcher.nix
		./modules/themes.nix
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
		./modules/qutebrowser.nix
		./modules/vlc.nix
		./modules/flameshot.nix
		./modules/obs.nix
		./modules/dorion.nix
		./modules/libreoffice.nix
  ];
}
