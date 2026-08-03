{ config, pkgs, lib, isNixOS, ... }:
 
{
  programs.neovim = {
    enable = true;

		viAlias = true;
		vimAlias = true;
  };

  xdg.configFile."nvim".source = ../config/nvim;
}
