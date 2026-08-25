{ config, pkgs, lib, OS, ... }:

{
  home.packages = with pkgs; []
  ++ (if OS == "nix" then [
    flameshot
  ] else []);
  
  xdg.configFile."flameshot".source = ../config/flameshot;
}
