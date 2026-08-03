# mkCatppuccinTheme.nix
{ pkgs, lib }:

let
	mkTheme = import ./mkTheme.nix { inherit pkgs lib; };

  palettes = import ../palettes/catppuccin.nix;
in {
	variant,
	accent? { name = "none"; color = { hex = "000000"; ansi = 0; }; },
	opacity? { default = 1; unfocused = 1; shell = 1; },
	cursor? { size = 24; },
	icons? { name = "Papirus"; packages = with pkgs; [ papirus-icon-theme ]; },
	font? { name = "Maple Mono NF CN"; size = 12; packages = with pkgs; [ maple-mono.NF-CN ]; },
	border? { width = 2; radius = 12; },
	margin? 4, spacing? 4,
	animations? { focus = { duration = 300; }; morph = { duration = 350; }; move = { duration = 350; }; },
	extra? {},
}:

let
	palette = palettes.${variant};
in mkTheme {
	inherit opacity icons font border margin spacing animations extra;

  id = "catppuccin-${variant}-${accent.name}";
	name = "catppuccin ${variant} ${accent.name}";

	dark = palette.dark;
	colors = palette.colors // builtins.listToAttrs [ { name = accent.name; value = accent.color; } ];
	accent = accent.name;

	gtk = { name = "catppuccin-${variant}-${accent.name}-standard+normal";
		packages = with pkgs; [ (catppuccin-gtk.override { inherit variant; accents = [ accent.name ]; size = "standard"; tweaks = [ "normal" ]; }) ]; };
	qt = { name = "catppuccin-${variant}-${accent.name}";
		packages = with pkgs; [ (catppuccin-kvantum.override { inherit variant; accent = accent.name; }) ]; };

	cursor = { name = "catppuccin-${variant}-${accent.name}-cursors";
		packages = with pkgs; [
			catppuccin-cursors."${variant}${lib.toUpper (builtins.substring 0 1 accent.name)}${builtins.substring 1 999 accent.name}"
		]; } // cursor;
}
