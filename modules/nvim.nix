{ config, pkgs, lib, isNixOS, ... }:
 
{
  programs.neovim = {
    enable = isNixOS;

	viAlias = true;
	vimAlias = true;
  };

  home.file.".config/nvim".source = ../config/nvim;
}
