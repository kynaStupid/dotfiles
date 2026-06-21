{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

	catppuccin.url = "github:catppuccin/nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, home-manager, catppuccin, nixgl, ... }: {
    homeConfigurations.sheb =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };

        modules = [
		  ./home.nix
		  catppuccin.homeModules.catppuccin
		];

        extraSpecialArgs = { inherit nixgl; };
      };
  };
}
