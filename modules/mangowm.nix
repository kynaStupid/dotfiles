{ config, pkgs, lib, ... }:

{
  home.file.".config/mangowm".source = ../config/mangowm;
}
