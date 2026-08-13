# nvim.nix
{ config, pkgs, lib, themes, themeSwitcher, isNixOS, ... }:

let
	themeFileEntries = lib.listToAttrs (lib.unique (map (theme: {
		name = "${themeSwitcher.dir}/nvim/plugins/${theme.nvim.type}.lua";
		value.source = pkgs.writeText "${theme.nvim.type}-theme.lua" ''
			return { "${theme.nvim.plugin}", priority = 999 }
		'';
	}) themes))
	//
	lib.listToAttrs (map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/nvim-theme.lua";
		value.source = pkgs.writeText "${theme.id}-nvim-theme.lua"
			theme.nvim.config;
	}) themes);

	nvimConfig = pkgs.runCommand "nvim-config" {} ''
		cp -r ${../config/nvim} "$out"

		substituteInPlace $(find "$out" -type f) \
			--replace-warn \
				"@THEME_SWITCHER_ROOT@" \
				"${config.home.homeDirectory}/${themeSwitcher.dir}"
	'';
in {
	programs.neovim = {
		enable = true;

		viAlias = true;
		vimAlias = true;
	};

	xdg.configFile."nvim".source = nvimConfig;
	home.file = themeFileEntries;
}
