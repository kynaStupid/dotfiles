{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

	catppuccin.url = "github:catppuccin/nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, catppuccin, ... }: {
    homeConfigurations.sheb =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };

        modules = [
		  ./home.nix
		  catppuccin.homeModules.catppuccin
		];
      };
  };
}
