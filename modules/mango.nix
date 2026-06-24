{ config, pkgs, lib, ... }:

{
  home.file.".config/mango".source = ../config/mango;
}
