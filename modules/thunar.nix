{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; [
    thunar
    thunar-volman
    thunar-archive-plugin
    tumbler
    gvfs
  ];
}
