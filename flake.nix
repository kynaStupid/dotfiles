# flake.nix
{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, ... }: {
		homeConfigurations = {
			void = home-manager.lib.homeManagerConfiguration {
				pkgs = import nixpkgs {
					system = "x86_64-linux";
				};

				extraSpecialArgs = { OS = "void"; };

				modules = [
					./home.nix
				];
			};

			arch = home-manager.lib.homeManagerConfiguration {
				pkgs = import nixpkgs {
					system = "x86_64-linux";
				};

				extraSpecialArgs = { OS = "arch"; };

				modules = [
					./home.nix
				];
			};

			nixos = home-manager.lib.homeManagerConfiguration {
				pkgs = import nixpkgs {
					system = "x86_64-linux";
				};

				extraSpecialArgs = { OS = "nix"; };

				modules = [
					./home.nix
				];
			};
		};
	};
}
