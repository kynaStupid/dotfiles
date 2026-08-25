{ config, pkgs, lib, themes, themeSwitcher, ... }:

let
	rofiConfig = pkgs.runCommand "rofi-config" {} ''
		cp -r ${../config/rofi} "$out"

		substituteInPlace $(find "$out" -type f) \
			--replace-warn \
				"@THEME_SWITCHER_ROOT@" \
				"${config.home.homeDirectory}/${themeSwitcher.dir}"
	'';

	themeFileEntries = lib.listToAttrs (map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/rofi-theme.rasi";
		value.source = pkgs.writeText "${theme.id}-rofi-theme.rasi"
			theme.rofi.config;
	}) themes);
in {
	programs.rofi.enable = true;

	xdg.configFile."rofi".source = rofiConfig;
	home.file = themeFileEntries;
}
