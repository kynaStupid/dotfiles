{ pkgs, isNixOS, ... }:

{
	home.packages = with pkgs; [
		fastfetch
	]
	++ (if isNixOS then [
		github-desktop
		steam
	] else []);
}
