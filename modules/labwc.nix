{ config, pkgs, lib, isNixOS, ... }:

{
  wayland.windowManager.labwc.enable = isNixOS;

  home.file.".config/labwc".source = ../config/labwc;
}
