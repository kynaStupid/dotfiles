{ config, pkgs, lib, ... }:

{
  home.username = "sheb";
  home.homeDirectory = "/home/sheb";
  home.stateVersion = "26.05";
  
  programs.home-manager.enable = true;
  
  programs.neovim = {
    enable = true;
  };
  home.file.".config/nvim".source = ./config/nvim;
  
  home.packages = with pkgs; [
    yazi
    fastfetch
  ];

  home.file.".config/labwc".source = ./config/labwc;
}
