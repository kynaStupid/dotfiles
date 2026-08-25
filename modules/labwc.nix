{ config, pkgs, lib, OS, ... }:

{
  wayland.windowManager.labwc.enable = OS == "nix";

  xdg.configFile."labwc".source = ../config/labwc;
}
