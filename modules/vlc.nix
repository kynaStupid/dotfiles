{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    vlc
  ] else []);
  
  xdg.configFile."vlc/vlcrc".source = ../config/vlc/vlcrc;
  xdg.configFile."vlc/vlc-qt-interface.conf".source = ../config/vlc/vlc-qt-interface.conf;
}
