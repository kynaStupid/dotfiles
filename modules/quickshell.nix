{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    quickshell
  ] else []);

  home.file.".config/quickshell".source = ../config/quickshell;
}
