{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

	catppuccin.url = "github:catppuccin/nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:FlameFlag/nixcord";
  };

  outputs = { nixpkgs, home-manager, catppuccin, nixcord, ... }: {
    homeConfigurations.sheb =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
	      system = "x86_64-linux";
          config.allowUnfree = true;
		};

		extraSpecialArgs = { inherit nixcord; };

        modules = [
		  ./home.nix
		  catppuccin.homeModules.catppuccin
		];
      };
  };
}
