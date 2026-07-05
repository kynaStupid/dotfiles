{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    flameshot
  ] else []);
  
  xdg.configFile."flameshot".source = ../config/flameshot;
}
