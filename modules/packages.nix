{ pkgs, isNixOS, ... }:

{
  home.packages = with pkgs; [
    fastfetch
	vlc
  ]
  ++ (if isNixOS then [
    github-desktop
  ] else []);
}
