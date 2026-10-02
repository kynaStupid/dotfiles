# vis.nix
{ config, pkgs, lib, themes, themeSwitcher, ... }:

{
	xdg.configFile."vis".source = ../config/vis;
}