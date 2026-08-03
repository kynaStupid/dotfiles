# themes.nix
{ config, pkgs, lib, ... }:

let
	mkTheme = import ../lib/mkTheme.nix { inherit pkgs lib; };
	mkCatppuccinTheme = import ../lib/mkCatppuccinTheme.nix { inherit pkgs lib; };

	packagesOf = theme:
		(theme.gtk.packages or []) ++
		(theme.qt.packages or []) ++
		(theme.cursor.packages or []) ++
		(theme.icons.packages or []) ++
		(theme.font.packages or []);
	
	themes = [
		(mkCatppuccinTheme {
			variant = "mocha";
			accent = { name = "mauve"; color = { hex = "cba6f7"; ansi = 183; }; };
			opacity = { default = 1; unfocused = 0.85; shell = 0.95; };
			icons = { name = "Papirus-Light"; packages = with pkgs; [ papirus-icon-theme ]; };
		})
		(mkCatppuccinTheme {
			variant = "latte";
			accent = { name = "peach"; color = { hex = "fe640b"; ansi = 208; }; };
			opacity = { default = 1; unfocused = 0.7; shell = 0.8; };
			icons = { name = "Papirus-Dark"; packages = with pkgs; [ papirus-icon-theme ]; };
		})
	];

	theme = builtins.head themes;
in {
	_module.args.themes = themes;

	home.packages = lib.unique (lib.concatMap packagesOf themes);

	imports = [
		./gtk.nix
		./qt.nix
	];

	home.file = lib.listToAttrs (
		# meta.json
		(map (theme: {
			name = ".local/state/theme-switcher/themes/${theme.id}/meta.json";
			value.source = pkgs.writeText "meta-${theme.id}.json" (builtins.toJSON {
				gtk = { name = theme.gtk.name; };
				qt = { name = theme.qt.name; };
				icons = { name = theme.icons.name; };
				cursor = { name = theme.cursor.name; size = theme.cursor.size; };
			});
		}) themes) ++

		# cursors
		(map (theme: {
			name = ".icons/${theme.cursor.name}";
			value.source = builtins.toPath "${builtins.head theme.cursor.packages}/share/icons/${theme.cursor.name}";
		}) themes)
	);
}
