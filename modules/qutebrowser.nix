# quickshell.nix
{ config, pkgs, lib, themes, themeSwitcher, ... }:

let
	themeFileEntries = lib.listToAttrs ((map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/qutebrowser-theme.py";
		value.source = pkgs.writeText "qutebrowser-theme-${theme.id}.py" theme.qutebrowser.config;
	}) themes)
	++ (lib.concatMap (theme:
		map (userStyle: {
			name = "${themeSwitcher.dir}/themes/${theme.id}/qutebrowser-userStyles/${userStyle.name}";
			value.source = pkgs.writeText "qutebrowser-${theme.id}-${userStyle.name}"
				userStyle.config;
		}) theme.qutebrowser.userStyles
	) themes));
in {
	xdg.configFile."qutebrowser/config.py".source = pkgs.replaceVars ../config/qutebrowser/config.py {
		THEME_SWITCHER_ROOT = "${config.home.homeDirectory}/${themeSwitcher.dir}";
		USERSCRIPTS_UPDATE_FILE = "${config.xdg.configHome}/qutebrowser/userScripts-update";
	};
	xdg.configFile."qutebrowser/userScripts-update" = {
		source = ../config/qutebrowser/userScripts-update;
		executable = true;
	};
	xdg.configFile."qutebrowser/userScripts.d".source = ../config/qutebrowser/userScripts.d;
	home.file = themeFileEntries;
}
