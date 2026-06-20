{ config, pkgs, lib, ... }:

{
  programs.mako.enable = true;
  home.file.".config/mako".source = ./config/mako;
}
