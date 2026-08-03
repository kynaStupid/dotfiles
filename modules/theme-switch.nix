# theme-switch.nix
{ pkgs, lib, ... }:

{
	home.packages = [
		(pkgs.writeShellApplication {
			name = "theme-switch";
			runtimeInputs = with pkgs; [ jq glib kdePackages.qtstyleplugin-kvantum awww mako findutils ];
			text = builtins.readFile ../config/theme-switch/theme-switch;
		})
	];
}
