# quickshell.nix
{ config, pkgs, lib, themes, themeSwitcher, isNixOS, ... }:

{
	xdg.configFile."qutebrowser/config.py".source = ../config/qutebrowser/config.py;
}
