{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
    ++ (if isNixOS then [
	  flameshot
	] else []);
  
  home.file.".config/flameshot".source = ../config/flameshot;
}
