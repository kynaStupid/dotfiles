{ config, pkgs, lib, OS, ... }:

{
	home.packages = with pkgs; []
	++ (if OS == "nix" then [
		libreoffice-bin
	] else []);

	xdg.configFile."libreoffice/4/user/registrymodifications.xcu".source = ../config/libreoffice/registrymodifications.xcu;
}
