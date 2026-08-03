{ config, pkgs, lib, themes, isNixOS, ... }:

let
	inherit (config.lib.formats.rasi) mkLiteral;
in {
	programs.rofi = {
		enable = true;

		extraConfig = {
    		modi = "combi,drun,run,window";
    		combi-modi = "drun,run";
    		show-icons = true;
  		};

		theme = {
			"*" = {
				# font = "${theme.font.name} ${toString theme.font.size}";
				# background-color = mkLiteral "#${theme.colors.base.hex}";
				# foreground-color = mkLiteral "#${theme.colors.text.hex}";
			};

			"#inputbar" = {
				children = map mkLiteral [
					"prompt"
					"entry"
				];
			};

			window = {
				width = 700;

				# border = theme.border.width;
				# border-radius = theme.border.radius;
				# border-color = mkLiteral "#${theme.colors.mauve.hex}";

				# padding = theme.margin;
			};
		};
	};
}
