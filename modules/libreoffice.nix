{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    libreoffice-bin
  ] else []);
  
  home.file.".config/libreoffice/4/user/registrymodifications.xcu".source = ../config/libreoffice/registrymodifications.xcu;
}
