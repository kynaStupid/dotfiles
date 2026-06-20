{ config, pkgs, lib, ... }:

{
  # programs.labwc.enable = true;
  home.file.".config/labwc".source = ../config/labwc;
}
