# quickshell.nix
{ config, pkgs, lib, themes, themeSwitcher, ... }:

let
	themeFileEntries = lib.listToAttrs (map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/qutebrowser-theme.py";
		value.source = pkgs.writeText "qutebrowser-theme-${theme.id}.py" theme.qutebrowser.config;
	}) themes);
in {
	xdg.configFile."qutebrowser/config.py".source = pkgs.replaceVars ../config/qutebrowser/config.py {
		THEME_SWITCHER_ROOT = "${config.home.homeDirectory}/${themeSwitcher.dir}";
	};
	home.file = themeFileEntries;
}
