# nvim.nix
{ config, pkgs, lib, themes, isNixOS, ... }:

let
	themeFileEntries = lib.listToAttrs (lib.unique (map (theme: {
		name = ".local/state/theme-switcher/nvim/plugins/${theme.nvim.type}.lua";
		value.source = pkgs.writeText "${theme.nvim.type}-theme.lua" ''
			return { "${theme.nvim.plugin}", priority = 999 }
		'';
	}) themes))
	//
	lib.listToAttrs (map (theme: {
		name = ".local/state/theme-switcher/themes/${theme.id}/nvim-theme.lua";
		value.source = pkgs.writeText "${theme.id}-nvim-theme.lua"
			theme.nvim.config;
	}) themes);
in {
  programs.neovim = {
    enable = true;

		viAlias = true;
		vimAlias = true;
  };

  xdg.configFile."nvim".source = ../config/nvim;
	home.file = themeFileEntries;
}
