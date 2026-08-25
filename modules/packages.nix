{ pkgs, OS, ... }:

{
	home.packages = with pkgs; [
		fastfetch
	]
	++ (if OS == "nix" then [
		github-desktop
		steam
	] else []);
}
