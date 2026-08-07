# mkCatppuccinTheme.nix
{ pkgs, lib }:

let
	mkTheme = import ./mkTheme.nix { inherit pkgs lib; };

  palettes = import ../palettes/catppuccin.nix;
in {
	variant,
	accent? { name = "none"; color = { hex = "000000"; ansi = 0; }; },
	opacity? { default = 1; unfocused = 1; shell = 1; },
	cursor? { size = 24; },
	icons? { name = "Papirus"; packages = with pkgs; [ papirus-icon-theme ]; },
	font? { name = "Maple Mono NF CN"; size = 12; packages = with pkgs; [ maple-mono.NF-CN ]; },
	border? { width = 2; radius = 12; },
	margin? 4, spacing? 4,
	animations? { focus = { duration = 300; }; morph = { duration = 350; }; move = { duration = 350; }; },
	extra? {},
	nvim? {},
	fsh? {},
}:

let
	palette = palettes.${variant};
in mkTheme {
	inherit opacity icons font border margin spacing animations extra;

  id = "catppuccin-${variant}-${accent.name}";
	name = "catppuccin ${variant} ${accent.name}";

	dark = palette.dark;
	colors = palette.colors // builtins.listToAttrs [ { name = accent.name; value = accent.color; } ];
	accent = accent.name;

	gtk = { name = "catppuccin-${variant}-${accent.name}-standard+normal";
		packages = with pkgs; [ (catppuccin-gtk.override { inherit variant; accents = [ accent.name ]; size = "standard"; tweaks = [ "normal" ]; }) ]; };
	qt = { name = "catppuccin-${variant}-${accent.name}";
		packages = with pkgs; [ (catppuccin-kvantum.override { inherit variant; accent = accent.name; }) ]; };

	cursor = { name = "catppuccin-${variant}-${accent.name}-cursors";
		packages = with pkgs; [
			catppuccin-cursors."${variant}${lib.toUpper (builtins.substring 0 1 accent.name)}${builtins.substring 1 999 accent.name}"
		]; } // cursor;

	nvim = {
		type = "catppuccin";
		name = "catppuccin-${variant}";
		plugin = "catppuccin/nvim";
		config = ''
			require("catppuccin").setup({
				flavour = "${variant}",
				transparent_background = true,
			})

			vim.cmd.colorscheme("catppuccin-nvim")
		'';
	} // nvim;

	fsh = {
		name = "catppuccin-${variant}-${accent.name}";
		config = ''
			[base]
			default = none
			unknown-token = ${toString palette.colors.red.ansi},bold
			commandseparator = none
			redirection = none
			here-string-tri = ${toString palette.colors.yellow.ansi}
			here-string-text = ${toString accent.color.ansi}
			here-string-var = ${toString palette.colors.blue.ansi},bg:${toString palette.colors.crust.ansi}
			exec-descriptor = ${toString palette.colors.yellow.ansi},bold
			comment = ${toString palette.colors.overlay0.ansi}
			correct-subtle = ${toString palette.colors.text.ansi}
			incorrect-subtle = ${toString palette.colors.red.ansi}
			subtle-separator = ${toString palette.colors.green.ansi}
			subtle-bg = bg:${toString palette.colors.surface1.ansi}
			secondary = free
			recursive-base =

			[command-point]
			reserved-word = ${toString accent.color.ansi}
			subcommand = ${toString accent.color.ansi}
			alias = ${toString palette.colors.green.ansi}
			suffix-alias = ${toString palette.colors.green.ansi}
			global-alias = bg:${toString palette.colors.blue.ansi}
			builtin = ${toString palette.colors.green.ansi}
			function = ${toString palette.colors.green.ansi}
			command = ${toString palette.colors.green.ansi}
			precommand = ${toString palette.colors.green.ansi}
			hashed-command = ${toString palette.colors.green.ansi}
			single-sq-bracket = ${toString palette.colors.green.ansi}
			double-sq-bracket = ${toString palette.colors.green.ansi}
			double-paren = ${toString palette.colors.yellow.ansi}

			[paths]
			path = ${toString palette.colors.blue.ansi}
			pathseparator =
			path-to-dir = ${toString palette.colors.blue.ansi},underline
			globbing = ${toString accent.color.ansi},bold
			globbing-ext = ${toString palette.colors.pink.ansi}

			[brackets]
			paired-bracket = bg:${toString palette.colors.surface2.ansi}
			bracket-level-1 = ${toString palette.colors.green.ansi},bold
			bracket-level-2 = ${toString palette.colors.yellow.ansi},bold
			bracket-level-3 = ${toString palette.colors.blue.ansi},bold

			[arguments]
			optarg-string = ${toString palette.colors.green.ansi}
			optarg-number = ${toString palette.colors.pink.ansi}
			single-hyphen-option = ${toString palette.colors.blue.ansi}
			double-hyphen-option = ${toString palette.colors.blue.ansi}
			back-quoted-argument = none
			single-quoted-argument = ${toString palette.colors.green.ansi}
			double-quoted-argument = ${toString palette.colors.green.ansi}
			dollar-quoted-argument = ${toString palette.colors.green.ansi}

			[in-string]
			back-dollar-quoted-argument = ${toString palette.colors.blue.ansi}
			back-or-dollar-double-quoted-argument = ${toString palette.colors.blue.ansi}

			[other]
			variable = ${toString palette.colors.text.ansi}
			assign = none
			assign-array-bracket = ${toString palette.colors.green.ansi}
			history-expansion = ${toString accent.color.ansi},bold

			[math]
			mathvar = ${toString accent.color.ansi},bold
			mathnum = ${toString palette.colors.pink.ansi}
			matherr = ${toString palette.colors.red.ansi}

			[for-loop]
			forvar = none
			fornum = ${toString palette.colors.pink.ansi}
			foroper = ${toString accent.color.ansi}
			forsep = ${toString accent.color.ansi},bold

			[case]
			case-input = ${toString palette.colors.green.ansi}
			case-parentheses = ${toString palette.colors.yellow.ansi}
			case-condition = bg:${toString palette.colors.surface2.ansi}
		'';
	} // fsh;
}
