{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;

	viAlias = true;
	vimAlias = true;
  };
  home.file.".config/nvim".source = ./config/nvim;
}
