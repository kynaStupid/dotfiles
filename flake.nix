# flake.nix
{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		#catppuccin.url = "github:catppuccin/nix";

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, /*catppuccin,*/ ... }: {
		homeConfigurations = {
			arch = home-manager.lib.homeManagerConfiguration {
				pkgs = import nixpkgs {
					system = "x86_64-linux";
				};

				extraSpecialArgs = { isNixOS = false; };

				modules = [
					./home.nix
					#catppuccin.homeModules.catppuccin
				];
			};

			nixos = home-manager.lib.homeManagerConfiguration {
				pkgs = import nixpkgs {
					system = "x86_64-linux";
				};

				extraSpecialArgs = { isNixOS = true; };

				modules = [
					./home.nix
					#catppuccin.homeModules.catppuccin
				];
			};
		};
	};
}
