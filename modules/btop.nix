# btop.nix
{ config, pkgs, lib, themes, ... }:

let
	mkBtopTheme = theme: pkgs.writeText "btop-theme-${theme.id}.theme" ''
		theme[main_bg]=""
		theme[main_fg]="#${theme.colors.text.hex}"

		theme[title]="#${theme.colors.${theme.accent}.hex}"
		theme[hi_fg]="#${theme.colors.blue.hex}"

		theme[selected_bg]="#${theme.colors.surface1.hex}"
		theme[selected_fg]="#${theme.colors.text.hex}"
		theme[inactive_fg]="#${theme.colors.overlay0.hex}"

		theme[proc_misc]="#${theme.colors.${theme.accent}.hex}"

		theme[cpu_box] = "#${theme.colors.blue.hex}"
		theme[mem_box] = "#${theme.colors.green.hex}"
		theme[net_box] = "#${theme.colors.${theme.accent}.hex}"
		theme[proc_box] = "#${theme.colors.pink.hex}"
		theme[div_line] = "#${theme.colors.overlay0.hex}"

		theme[temp_start] = "#${theme.colors.blue.hex}"
		theme[temp_mid] = "#${theme.colors.yellow.hex}"
		theme[temp_end] = "#${theme.colors.red.hex}"

		theme[cpu_start]="#${theme.colors.blue.hex}"
		theme[cpu_mid]="#${theme.colors.${theme.accent}.hex}"
		theme[cpu_end]="#${theme.colors.red.hex}"

		theme[free_start]="#${theme.colors.green.hex}"
		theme[free_mid]="#${theme.colors.yellow.hex}"
		theme[free_end]="#${theme.colors.red.hex}"

		theme[cached_start]="#${theme.colors.blue.hex}"
		theme[cached_mid]="#${theme.colors.${theme.accent}.hex}"
		theme[cached_end]="#${theme.colors.pink.hex}"

		theme[available_start]="#${theme.colors.green.hex}"
		theme[available_mid]="#${theme.colors.yellow.hex}"
		theme[available_end]="#${theme.colors.red.hex}"

		theme[used_start]="#${theme.colors.red.hex}"
		theme[used_mid]="#${theme.colors.yellow.hex}"
		theme[used_end]="#${theme.colors.${theme.accent}.hex}"

		theme[download_start]="#${theme.colors.blue.hex}"
		theme[download_mid]="#${theme.colors.${theme.accent}.hex}"
		theme[download_end]="#${theme.colors.pink.hex}"

		theme[upload_start]="#${theme.colors.green.hex}"
		theme[upload_mid]="#${theme.colors.yellow.hex}"
		theme[upload_end]="#${theme.colors.red.hex}"
	'';

	themeFileEntries = lib.listToAttrs (map (theme: {
		name = ".local/state/theme-switcher/themes/${theme.id}/btop-theme.theme";
		value.source = mkBtopTheme theme;
	}) themes);
in {
	programs.btop = {
		enable = true;
		package = pkgs.btop.override {
			cudaSupport = true;
			rocmSupport = true;
		};
		settings = {
			update_ms = 1000;
			theme_background = false;

			color_theme = "pikt";
		};
	};

	home.file = themeFileEntries;
}
