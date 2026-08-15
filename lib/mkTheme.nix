# mkTheme.nix
{ pkgs, lib }:
{
	id, name,
	dark, colors, accent, opacity,
	gtk, qt,
	cursor, icons, font,
	border,
	margin, spacing,
	animations,
	extra? {},
	nvim,
	rofi,
	fsh,
}:

{ inherit
	id name
	dark colors accent opacity
	gtk qt
	cursor icons font
	border
	margin spacing
	animations
	extra
	nvim
	rofi
	fsh
; }
