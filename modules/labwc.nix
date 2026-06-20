{ config, pkgs, lib, ... }:

{
  home.file.".config/labwc".source = ./config/labwc;
}
