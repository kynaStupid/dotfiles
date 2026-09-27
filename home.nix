{ config, pkgs, lib, ... }:

let
	username = "sheb";
	modulesPath = [ ./modules ];
in {
	home.username = username;
	home.homeDirectory = "/home/${username}";
	home.stateVersion = "26.05";

	programs.home-manager.enable = true;

	#systemd.user.startServices = "sd-switch";

	imports = lib.flatten (
		map
			(path:
				lib.filter
					(file: lib.hasSuffix ".nix" (toString file))
					(lib.filesystem.listFilesRecursive path)
			)
			modulesPath
	);
}
