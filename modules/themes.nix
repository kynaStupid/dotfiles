# themes.nix
{ config, pkgs, lib, themeSwitcher, ... }:

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
			accent = { name = "sapphire"; color = { hex = "74c7ec"; ansi = 117; }; };
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
			name = "${themeSwitcher.dir}/themes/${theme.id}/meta.json";
			value.source = pkgs.writeText "meta-${theme.id}.json" (builtins.toJSON {
				dark = theme.dark;
				gtk = { name = theme.gtk.name; };
				qt = { name = theme.qt.name; };
				icons = { name = theme.icons.name; };
				cursor = { name = theme.cursor.name; size = theme.cursor.size; };
				font = { name = theme.font.name; size = theme.font.size; };
				fsh = { name = theme.fsh.name; };
			});
		}) themes)
		++

		# cursors
		(map (theme: {
			name = ".icons/${theme.cursor.name}";
			value.source = builtins.toPath "${builtins.head theme.cursor.packages}/share/icons/${theme.cursor.name}";
		}) themes)
	);
}
