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
	rofi? {},
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

	rofi = {
		config = ''
			configuration {
				display-combi:              "";
				display-filebrowser:        "";
				display-window:             "";
				show-icons:                 true;
				drun-display-format:        "{name} [<span weight='light' size='small'><i>({generic})</i></span>]";
				combi-hide-mode-prefix:     true;
				window-format:              "{w} · {c} · {t}";
				separator-style:            none;
			}

			* {
				colors-background:          #${palette.colors.base.hex};
				colors-background-alt:      #${palette.colors.surface0.hex};
				colors-background-active:   #${palette.colors.surface1.hex};

				colors-foreground:          #${palette.colors.text.hex};
				colors-foreground-alt:      #${palette.colors.subtext0.hex};
				
				colors-selected:            #${accent.color.hex};
				colors-selected-fg:         #${palette.colors.crust.hex};

				colors-border:              #${accent.color.hex};
				colors-handle:              #${palette.colors.overlay1.hex};

				colors-urgent:              #${palette.colors.red.hex};
				colors-active:              #${accent.color.hex};

				spacing:                    0px;
				margin:                     0px;
				padding:                    0px;
				border:                     0px solid;
				border-radius:              0px 0px 0px 0px;
				background-color:           transparent;
			}

			window {
				transparency:               "real";
				location:                   center;
				anchor:                     center;
				fullscreen:                 false;
				width:                      600px;
				x-offset:                   0px;
				y-offset:                   0px;

				enabled:                    true;
				border:                     ${toString border.width}px solid;
				border-radius:              ${toString border.radius}px;
				border-color:               @colors-border;
				cursor:                     "default";
				background-color:           @colors-background;
			}

			mainbox {
				enabled:                    true;
				spacing:                    ${toString spacing}px;
				padding:                    ${toString margin}px;
				border-color:               @colors-border;
				children:                   [ "inputbar", "message", "listview", "mode-switcher" ];
			}

			inputbar {
				enabled:                    true;
				spacing:                    ${toString spacing}px;
				padding:                    ${toString margin}px;
				border-radius:              ${toString border.radius}px;
				border-color:               @colors-border;
				background-color:           @colors-background-alt;
				text-color:                 @colors-foreground;
				children:                   [ "prompt", "entry" ];
			}

			prompt {
				enabled:                    true;
				background-color:           inherit;
				text-color:                 inherit;
				padding: 0px 6px 0px 0px;
			}
			entry {
				enabled:                    true;
				background-color:           inherit;
				text-color:                 inherit;
				cursor:                     text;
				placeholder:                "";
				placeholder-color:          inherit;
			}

			listview {
				enabled:                    true;
				columns:                    2;
				lines:                      10;
				cycle:                      true;
				dynamic:                    true;
				scrollbar:                  false;
				layout:                     vertical;
				reverse:                    false;
				fixed-height:               false;
				fixed-columns:              false;

				border-color:               @colors-border;
				text-color:                 @colors-foreground;
				cursor:                     "default";
			}
			scrollbar {
				handle-width:               ${toString margin}px;
				handle-color:               @colors-handle;
				background-color:           @colors-background-alt;
			}

			element {
				enabled:                    true;
				spacing:                    ${toString spacing}px;
				padding:                    ${toString margin}px;
				border-radius:              ${toString border.radius}px;
				border-color:               @colors-border;
				background-color:           transparent;
				text-color:                 @colors-foreground;
				cursor:                     pointer;
			}
			element normal.normal {
				background-color:           @colors-background;
				text-color:                 @colors-foreground;
			}
			element normal.urgent {
				background-color:           @colors-urgent;
				text-color:                 @colors-selected-fg;
			}
			element normal.active {
				background-color:           @colors-background-active;
				text-color:                 @colors-foreground;
			}
			element selected.normal {
				background-color:           @colors-selected;
				text-color:                 @colors-selected-fg;
			}
			element selected.urgent {
				background-color:           @colors-urgent;
				text-color:                 @colors-selected-fg;
			}
			element selected.active {
				background-color:           @colors-selected;
				text-color:                 @colors-selected-fg;
			}
			element alternate.normal {
				background-color:           @colors-background-alt;
				text-color:                 @colors-foreground;
			}
			element alternate.urgent {
				background-color:           @colors-urgent;
				text-color:                 @colors-selected-fg;
			}
			element alternate.active {
				background-color:           @colors-background-active;
				text-color:                 @colors-foreground;
			}
			element-icon {
				background-color:           transparent;
				text-color:                 inherit;
				size:                       32px;
				cursor:                     inherit;
			}
			element-text {
				background-color:           transparent;
				text-color:                 inherit;
				highlight:                  inherit;
				cursor:                     inherit;
				vertical-align:             0.5;
				horizontal-align:           0.0;
			}

			mode-switcher{
				enabled:                    true;
				spacing:                    ${toString spacing};
				border-color:               @colors-border;
				background-color:           transparent;
				text-color:                 @colors-foreground;
			}
			button {
				padding:                    ${toString margin};
				border-radius:              ${toString border.radius}px;
				border-color:               @colors-border;
				background-color:           @colors-background-alt;
				text-color:                 inherit;
				cursor:                     pointer;
			}
			button selected {
				background-color:           @colors-background-active;
				text-color:                 @colors-foreground;
			}

			message {
				enabled:                    true;
				border-color:               @colors-border;
				background-color:           transparent;
				text-color:                 @colors-foreground;
			}
			textbox {
				padding:                    ${toString margin}px;
				border-color:               @colors-border;
				background-color:           @colors-background-alt;
				text-color:                 @colors-foreground;
				vertical-align:             0.5;
				horizontal-align:           0.0;
				highlight:                  none;
				placeholder-color:          @colors-foreground;
				blink:                      true;
				markup:                     true;
			}
			error-message {
				padding:                    ${toString margin}px;
				border-color:               @colors-border;
				background-color:           @colors-background;
				text-color:                 @colors-foreground;
			}
		'';
	} // rofi;

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
