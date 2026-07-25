# theme.nix
{ config, pkgs, lib, ... }:

let
	theme = {
    	gtk = {
	  		name = "catppuccin-mocha-mauve-standard+normal";
	  		packages = with pkgs; [
	  			(catppuccin-gtk.override {
	   				variant = "mocha";
		  			accents = [ "mauve" ];
		  			size = "standard";
		  			tweaks = [ "normal" ];
	    		})
	  		];
		};
    	qt = {
	  		name = "catppuccin-mocha-mauve";
	  		packages = with pkgs; [
        		(catppuccin-kvantum.override {
          			variant = "mocha";
          			accent = "mauve";
        		})
      		];
		};
    	icons = {
	  		name = "Papirus";
	  		packages = with pkgs; [
	    	papirus-icon-theme
	  		];
		};
    	cursor = {
	  		name = "catppuccin-mocha-mauve-cursors";
	  		size = 24;
	  		packages = with pkgs; [
	    		#catppuccin-cursors.mochaMauve
	  		];
		};
    	font = {
	  		name = "Maple Mono NF CN";
	  		size = 12;
	  		packages = with pkgs; [
	    		maple-mono.NF-CN
	  		];
		};
		dark = true;
		colors = {
			base = {
				hex = "1e1e2e";
				ansi = "235";
			};
			text = {
				hex = "cdd6f4";
				ansi = "189";
			};
			yellow = {
				hex = "f9e2af";
				ansi = "223";
			};
			green = {
				hex = "a6e3a1";
				ansi = "151";
			};
			blue = {
				hex = "89b4fa";
				ansi = "111";
			};
		};
		border = {
			width = 2;
		};
  	};
in {
  	_module.args.theme = theme;

  	home.pointerCursor = {
    	enable = true;
    	name = theme.cursor.name;
		size = theme.cursor.size;
		package = pkgs.catppuccin-cursors.mochaMauve;
		gtk.enable = true;
		x11.enable = true;
  	};

  	home.packages = with pkgs; []
    	++theme.gtk.packages
		++theme.qt.packages
		++theme.icons.packages
		++theme.cursor.packages
		++theme.font.packages
  	;

  	imports = [
    	./gtk.nix
    	./qt.nix
  	];
}
