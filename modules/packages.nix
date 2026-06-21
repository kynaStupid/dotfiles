{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
	github-desktop
	karere
  ];
}
