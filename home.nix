{ config, pkgs, lib, ... }:

let
  catppuccin-waybar = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "waybar";
    rev = "main";
    hash = "sha256-za0y6hcN2rvN6Xjf31xLRe4PP0YyHu2i454ZPjr+lWA";
  };
in
{
  home.username = "sheb";
  home.homeDirectory = "/home/sheb";
  home.stateVersion = "26.05";
  
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    yazi
    fastfetch
  ];

  catppuccin = {
    enable = true;
	autoEnable = true;
	flavor = "mocha";
  };

  programs.btop.enable = true;
  
  programs.neovim = {
    enable = true;
  };
  home.file.".config/nvim".source = ./config/nvim;
  
  home.file.".config/waybar".source = ./config/waybar;
  home.file.".config/waybar/mocha.css".source =
    "${catppuccin-waybar}/themes/mocha.css";

  home.file.".config/labwc".source = ./config/labwc;
}
