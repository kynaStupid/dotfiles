{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    vlc
  ] else []);
  
  #home.file.".config/vlc".source = ../config/vlc;
}
