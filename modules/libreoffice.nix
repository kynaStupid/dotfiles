{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    libreoffice-bin
  ] else []);
  
  xdg.configFile."libreoffice/4/user/registrymodifications.xcu".source = ../config/libreoffice/registrymodifications.xcu;
}
