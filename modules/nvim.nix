{ config, pkgs, lib, isNixOS, ... }:
 
{
  programs.neovim = {
    enable = isNixOS;

	viAlias = true;
	vimAlias = true;
  };

  xdg.configFile."nvim".source = ../config/nvim;
}
