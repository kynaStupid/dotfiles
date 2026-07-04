{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    obs-studio
  ] else []);

  #home.file.".config/obs-studio".source = ../config/obs-studio;
}
