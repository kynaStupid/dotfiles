{ pkgs, OS, ... }:

{
	home.packages = with pkgs; [
		fastfetch
		proton-vpn-cli
	]
	++ (if OS == "nix" then [
		github-desktop
		steam
	] else []);
}
