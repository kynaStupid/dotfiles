# quickshell.nix
{ config, pkgs, lib, themes, themeSwitcher, isNixOS, ... }:

let
	mkThemeJson = theme: pkgs.writeText "quickshell-theme-${theme.id}.json" (builtins.toJSON {
		barHeight           = 24;
		barWidth            = 32;
		barTextSize         = theme.font.size;
		barRadius           = theme.border.radius;
		borderWidth         = theme.border.width;
		animFocusDuration   = theme.animations.focus.duration;
		animMorphDuration   = theme.animations.morph.duration;
		animMoveDuration    = theme.animations.move.duration;
		barOpacityFocused   = theme.opacity.shell;
		barOpacityUnfocused = theme.opacity.unfocused;

		accent   = "#" + theme.colors.${theme.accent}.hex;
		pink     = "#" + theme.colors.pink.hex;
		red      = "#" + theme.colors.red.hex;
		yellow   = "#" + theme.colors.yellow.hex;
		green    = "#" + theme.colors.green.hex;
		blue     = "#" + theme.colors.blue.hex;
		text     = "#" + theme.colors.text.hex;
		subtext1 = "#" + theme.colors.subtext1.hex;
		subtext0 = "#" + theme.colors.subtext0.hex;
		overlay2 = "#" + theme.colors.overlay2.hex;
		overlay1 = "#" + theme.colors.overlay1.hex;
		overlay0 = "#" + theme.colors.overlay0.hex;
		surface2 = "#" + theme.colors.surface2.hex;
		surface1 = "#" + theme.colors.surface1.hex;
		surface0 = "#" + theme.colors.surface0.hex;
		base     = "#" + theme.colors.base.hex;
		mantle   = "#" + theme.colors.mantle.hex;
		crust    = "#" + theme.colors.crust.hex;
	});

	themeFileEntries = lib.listToAttrs (map (theme: {
		name  = "${themeSwitcher.dir}/themes/${theme.id}/quickshell-theme.json";
		value = { source = mkThemeJson theme; };
	}) themes);
in {
	home.packages = with pkgs; []
	++ (if isNixOS then [
		quickshell
	] else []);

	xdg.configFile."quickshell".source =
		config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quickshell";
		#../config/quickshell;
	xdg.configFile."quickshell-theme-path".text = "${config.home.homeDirectory}/${themeSwitcher.dir}/active/quickshell-theme.json";
	home.file = themeFileEntries;
}
