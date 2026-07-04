{ config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; []
  ++ (if isNixOS then [
    quickshell
  ] else []);

  home.file.".config/quickshell".source =
  	config.lib.file.mkOutOfStoreSymlink
	  "/home/sheb/dotfiles/config/quickshell";
}
