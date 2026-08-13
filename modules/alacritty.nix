{ config, pkgs, lib, themes, themeSwitcher, isNixOS, ... }:

let
	mkAlacrittyToml = theme: pkgs.writeText "alacritty-theme-${theme.id}.toml" ''
		[window]
		opacity = ${toString theme.opacity.shell}

		[font]
		size = ${toString theme.font.size}
		normal.family = "${theme.font.name}"

		[colors.primary]
		background = "#${theme.colors.base.hex}"
		foreground = "#${theme.colors.text.hex}"

		[colors.cursor]
		text = "#${theme.colors.base.hex}"
		cursor = "#${theme.colors.${theme.accent}.hex}"

		[colors.selection]
		text = "#${theme.colors.base.hex}"
		background = "#${theme.colors.${theme.accent}.hex}"

		[colors.normal]
		black   = "#${theme.colors.crust.hex}"
		red     = "#${theme.colors.red.hex}"
		green   = "#${theme.colors.green.hex}"
		yellow  = "#${theme.colors.yellow.hex}"
		blue    = "#${theme.colors.blue.hex}"
		magenta = "#${theme.colors.pink.hex}"
		cyan    = "#${theme.colors.overlay1.hex}"
		white   = "#${theme.colors.text.hex}"

		[colors.bright]
		black   = "#${theme.colors.surface0.hex}"
		red     = "#${theme.colors.red.hex}"
		green   = "#${theme.colors.green.hex}"
		yellow  = "#${theme.colors.yellow.hex}"
		blue    = "#${theme.colors.blue.hex}"
		magenta = "#${theme.colors.pink.hex}"
		cyan    = "#${theme.colors.overlay2.hex}"
		white   = "#${theme.colors.text.hex}"
	'';

	themeFileEntries = lib.listToAttrs (map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/alacritty-theme.toml";
		value.source = mkAlacrittyToml theme;
	}) themes);
in {
  programs.alacritty = {
    enable = true;
    package = if isNixOS then pkgs.alacritty else null;
		settings = {
	  	window = {
        decorations = "None";

        padding = {
          x = 0;
          y = 0;
        };
    	};

	  	selection.save_to_clipboard = true;

  		keyboard.bindings = [
     	 	{
     	   	key = "C";
     	   	mods = "Control|Shift";
     	   	action = "Copy";
     	 	}
     	 	{
     	   	key = "V";
     	   	mods = "Control|Shift";
     	   	action = "Paste";
     	 	}
    	];

			general.import = [
				"${config.home.homeDirectory}/${themeSwitcher.dir}/active/alacritty-theme.toml"
			];
		};
  };

	home.file = themeFileEntries;
}
