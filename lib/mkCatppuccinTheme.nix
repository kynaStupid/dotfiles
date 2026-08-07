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
			unknown-token = #${palette.colors.red.hex},bold
			commandseparator = none
			redirection = none
			here-string-tri = #${palette.colors.yellow.hex}
			here-string-text = #${accent.color.hex}
			here-string-var = #${palette.colors.blue.hex},bg:#${palette.colors.crust.hex}
			exec-descriptor = #${palette.colors.yellow.hex},bold
			comment = #${palette.colors.overlay0.hex}
			correct-subtle = #${palette.colors.text.hex}
			incorrect-subtle = #${palette.colors.red.hex}
			subtle-separator = #${palette.colors.green.hex}
			subtle-bg = bg:#${palette.colors.surface1.hex}
			secondary = free
			recursive-base =

			[command-point]
			reserved-word = #${accent.color.hex}
			subcommand = #${accent.color.hex}
			alias = #${palette.colors.green.hex}
			suffix-alias = #${palette.colors.green.hex}
			global-alias = bg:#${palette.colors.blue.hex}
			builtin = #${palette.colors.green.hex}
			function = #${palette.colors.green.hex}
			command = #${palette.colors.green.hex}
			precommand = #${palette.colors.green.hex}
			hashed-command = #${palette.colors.green.hex}
			single-sq-bracket = #${palette.colors.green.hex}
			double-sq-bracket = #${palette.colors.green.hex}
			double-paren = #${palette.colors.yellow.hex}

			[paths]
			path = #${palette.colors.blue.hex}
			pathseparator =
			path-to-dir = #${palette.colors.blue.hex},underline
			globbing = #${accent.color.hex},bold
			globbing-ext = #${palette.colors.pink.hex}

			[brackets]
			paired-bracket = bg:#${palette.colors.surface2.hex}
			bracket-level-1 = #${palette.colors.green.hex},bold
			bracket-level-2 = #${palette.colors.yellow.hex},bold
			bracket-level-3 = #${palette.colors.blue.hex},bold

			[arguments]
			optarg-string = #${palette.colors.green.hex}
			optarg-number = #${palette.colors.pink.hex}
			single-hyphen-option = #${palette.colors.blue.hex}
			double-hyphen-option = #${palette.colors.blue.hex}
			back-quoted-argument = none
			single-quoted-argument = #${palette.colors.green.hex}
			double-quoted-argument = #${palette.colors.green.hex}
			dollar-quoted-argument = #${palette.colors.green.hex}

			[in-string]
			back-dollar-quoted-argument = #${palette.colors.blue.hex}
			back-or-dollar-double-quoted-argument = #${palette.colors.blue.hex}

			[other]
			variable = #${palette.colors.text.hex}
			assign = none
			assign-array-bracket = #${palette.colors.green.hex}
			history-exphexon = #${accent.color.hex},bold

			[math]
			mathvar = #${accent.color.hex},bold
			mathnum = #${palette.colors.pink.hex}
			matherr = #${palette.colors.red.hex}

			[for-loop]
			forvar = none
			fornum = #${palette.colors.pink.hex}
			foroper = #${accent.color.hex}
			forsep = #${accent.color.hex},bold

			[case]
			case-input = #${palette.colors.green.hex}
			case-parentheses = #${palette.colors.yellow.hex}
			case-condition = bg:#${palette.colors.surface2.hex}
		'';
	} // fsh;
}
