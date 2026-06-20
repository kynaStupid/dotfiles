{ config, pkgs, lib, ... }:

{
  programs.btop.enable = true;
  home.file.".config/btop".source = ./config/btop;
}
