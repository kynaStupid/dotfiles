{ config, pkgs, lib, isNixOS, ... }:

{
  wayland.windowManager.labwc.enable = isNixOS;

  xdg.configFile."labwc".source = ../config/labwc;
}
