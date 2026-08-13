# theme-switcher.nix
{ config, pkgs, lib, ... }:

let
	themeSwitcherName = "pikt";
	themeSwitcher = {
		name = themeSwitcherName;
		dir = ".local/state/${themeSwitcherName}";
	};
in {
	_module.args.themeSwitcher = themeSwitcher;

	home.packages = [
		(pkgs.writeShellApplication {
			name = themeSwitcher.name;
			runtimeInputs = with pkgs; [ jq glib dconf kdePackages.qtstyleplugin-kvantum awww mako findutils ];
			text = builtins.readFile (pkgs.replaceVars ../config/theme-switcher/${themeSwitcher.name} {
				THEME_SWITCHER_ROOT = "${config.home.homeDirectory}/${themeSwitcher.dir}";
			});
		})
	];
}
