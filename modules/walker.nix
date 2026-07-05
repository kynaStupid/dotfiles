{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
  	walker
	elepant
  ];
}
