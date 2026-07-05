{ config, pkgs, lib, ... }:

{
  xdg.configFile."mango".source = ../config/mango;
}
