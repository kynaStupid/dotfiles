{ config, pkgs, lib, ... }:

{
  programs.waybar.enable = true;

  home.file.".config/waybar".source = ../config/waybar;
}
