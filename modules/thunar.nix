{ config, pkgs, lib, OS, ... }:

{
  home.packages = with pkgs; [
    thunar
    thunar-volman
    thunar-archive-plugin
    tumbler
		gvfs
		udiskie
  ];
}
