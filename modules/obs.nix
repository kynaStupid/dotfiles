{ config, pkgs, lib, OS, ... }:

{
  home.packages = with pkgs; []
  ++ (if OS == "nix" then [
    obs-studio
  ] else []);

  #home.file.".config/obs-studio".source = ../config/obs-studio;
}
