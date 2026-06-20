{ config, pkgs, lib, ... }:

{
  programs.yazi.enable = true;
  home.file.".config/yazi".source = ../config/yazi;
}
