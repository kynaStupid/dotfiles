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
	fsh? {},
	rofi? {},
	nvim? {},
	qutebrowser? {},
}:

let
	palette = palettes.${variant};

	hexToRgb = let
		digits = {
			"0" = 0; "1" = 1; "2" = 2; "3" = 3;
			"4" = 4; "5" = 5; "6" = 6; "7" = 7;
			"8" = 8; "9" = 9; "a" = 10; "b" = 11;
			"c" = 12; "d" = 13; "e" = 14; "f" = 15;
		};

		byte = hex:
			let
				chars = lib.strings.stringToCharacters hex;
				hi = builtins.elemAt chars 0;
				lo = builtins.elemAt chars 1;
			in
				digits.${lib.toLower hi} * 16
				+ digits.${lib.toLower lo};
		in {
			r = hex: byte (builtins.substring 0 2 hex);
			g = hex: byte (builtins.substring 2 2 hex);
			b = hex: byte (builtins.substring 4 2 hex);
		};
	rgba = hex: opacity:
		"${toString (hexToRgb.r hex)}, ${toString (hexToRgb.g hex)}, ${toString (hexToRgb.b hex)}, ${toString (builtins.floor ((255 * opacity) + 0.5))}";
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

	qutebrowser = {
		config = ''
c.window.transparent = ${if opacity.default == 1 && opacity.unfocused == 1 && opacity.shell == 1 then "False" else "True"}

# Statusbar

c.statusbar.position = "bottom"
c.statusbar.padding = { "top": ${toString margin}, "left": ${toString margin}, "bottom": ${toString margin}, "right": ${toString margin}, }
c.statusbar.show = "always"
c.statusbar.widgets = ["keypress", "search_match", "url", "scroll", "history", "tabs", "progress"]

c.completion.height = "60%"
c.completion.scrollbar.padding = 0
c.completion.scrollbar.width = ${toString margin}

# Tabs

c.tabs.pinned.shrink = True

c.tabs.favicons.show = "always"
c.tabs.favicons.scale = 1.0

c.tabs.indicator.width = 0
c.tabs.indicator.padding = { "top": 0, "left": 0, "bottom": 0, "right": 0, }

c.tabs.title.alignment = "left"
c.tabs.title.elide = "right"
c.tabs.title.format = "{index} {current_title}"
c.tabs.title.format_pinned = "{index} {current_title}"

c.tabs.width = 52
c.tabs.padding = { "top": ${toString margin}, "left": ${toString margin}, "bottom": ${toString margin}, "right": ${toString margin}, }
c.tabs.tooltips = False

c.tabs.show = "multiple"
c.tabs.show_switching_delay = 800
c.tabs.tabs_are_windows = False
c.tabs.position = "left"
c.tabs.max_width = -1
c.tabs.min_width = -1

# Downloads

c.downloads.position = "top"

# Colors
# statusbar
c.colors.statusbar.normal.bg = "rgba(${rgba palette.colors.mantle.hex opacity.shell})"
c.colors.statusbar.normal.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"
c.colors.statusbar.command.bg = "rgba(${rgba palette.colors.mantle.hex opacity.shell})"
c.colors.statusbar.command.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"
c.colors.statusbar.insert.bg = "rgba(${rgba palette.colors.green.hex opacity.shell})"
c.colors.statusbar.insert.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.statusbar.passthrough.bg = "rgba(${rgba palette.colors.blue.hex opacity.shell})"
c.colors.statusbar.passthrough.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.statusbar.caret.bg = "rgba(${rgba accent.color.hex opacity.shell})"
c.colors.statusbar.caret.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.statusbar.caret.selection.bg = "rgba(${rgba palette.colors.overlay2.hex opacity.shell})"
c.colors.statusbar.caret.selection.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"
c.colors.statusbar.private.bg = "rgba(${rgba palette.colors.surface1.hex opacity.shell})"
c.colors.statusbar.private.fg = "rgba(${rgba palette.colors.subtext0.hex opacity.default})"

# tabs
c.colors.tabs.bar.bg = "rgba(${rgba palette.colors.mantle.hex opacity.shell})"

c.colors.tabs.odd.bg = "rgba(${rgba palette.colors.surface0.hex opacity.unfocused})"
c.colors.tabs.odd.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"
c.colors.tabs.even.bg = "rgba(${rgba palette.colors.surface0.hex opacity.unfocused})"
c.colors.tabs.even.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"

c.colors.tabs.selected.odd.bg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.tabs.selected.odd.fg = "rgba(${rgba accent.color.hex opacity.default})"
c.colors.tabs.selected.even.bg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.tabs.selected.even.fg = "rgba(${rgba accent.color.hex opacity.default})"

c.colors.tabs.pinned.odd.bg = "rgba(${rgba palette.colors.surface1.hex opacity.unfocused})"
c.colors.tabs.pinned.odd.fg = "rgba(${rgba palette.colors.subtext0.hex opacity.default})"
c.colors.tabs.pinned.even.bg = "rgba(${rgba palette.colors.surface1.hex opacity.unfocused})"
c.colors.tabs.pinned.even.fg = "rgba(${rgba palette.colors.subtext0.hex opacity.default})"

c.colors.tabs.pinned.selected.odd.bg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.tabs.pinned.selected.odd.fg = "rgba(${rgba accent.color.hex opacity.default})"
c.colors.tabs.pinned.selected.even.bg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.tabs.pinned.selected.even.fg = "rgba(${rgba accent.color.hex opacity.default})"

# completion
c.colors.completion.odd.bg = "rgba(${rgba palette.colors.mantle.hex opacity.shell})"
c.colors.completion.even.bg = "rgba(${rgba palette.colors.crust.hex opacity.shell})"
c.colors.completion.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"
c.colors.completion.category.bg = "rgba(${rgba palette.colors.surface0.hex opacity.shell})"
c.colors.completion.category.fg = "rgba(${rgba palette.colors.subtext0.hex opacity.default})"
c.colors.completion.item.selected.bg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.completion.item.selected.fg = "rgba(${rgba accent.color.hex opacity.shell})"
c.colors.completion.scrollbar.bg = "rgba(${rgba palette.colors.mantle.hex opacity.shell})"
c.colors.completion.scrollbar.fg = "rgba(${rgba palette.colors.base.hex opacity.shell})"

# hints
c.colors.hints.bg = "rgba(${rgba accent.color.hex opacity.shell})"
c.colors.hints.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.hints.match.fg = "rgba(${rgba palette.colors.crust.hex opacity.default})"

# keyhint
c.colors.keyhint.bg = "rgba(${rgba palette.colors.crust.hex opacity.shell})"
c.colors.keyhint.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"

# prompts
c.colors.prompts.bg = "rgba(${rgba palette.colors.surface0.hex opacity.shell})"
c.colors.prompts.fg = "rgba(${rgba palette.colors.text.hex opacity.default})"
c.colors.prompts.selected.bg = "rgba(${rgba palette.colors.surface2.hex opacity.default})"
c.colors.prompts.selected.fg = "rgba(${rgba palette.colors.subtext0.hex opacity.default})"

# messages
c.colors.messages.error.bg = "rgba(${rgba palette.colors.red.hex opacity.default})"
c.colors.messages.error.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.messages.warning.bg = "rgba(${rgba palette.colors.yellow.hex opacity.default})"
c.colors.messages.warning.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.messages.info.bg = "rgba(${rgba palette.colors.surface0.hex opacity.shell})"
c.colors.messages.info.fg = "rgba(${rgba palette.colors.subtext0.hex opacity.default})"

# downloads
c.colors.downloads.bar.bg = "rgba(${rgba palette.colors.mantle.hex opacity.default})"
c.colors.downloads.start.bg = "rgba(${rgba palette.colors.blue.hex opacity.default})"
c.colors.downloads.start.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.downloads.stop.bg = "rgba(${rgba palette.colors.green.hex opacity.default})"
c.colors.downloads.stop.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"
c.colors.downloads.error.bg = "rgba(${rgba palette.colors.red.hex opacity.default})"
c.colors.downloads.error.fg = "rgba(${rgba palette.colors.base.hex opacity.default})"

# webpage
c.colors.webpage.bg = "rgba(${rgba palette.colors.base.hex 1})"
c.colors.webpage.preferred_color_scheme = "${if palette.dark then "dark" else "light"}"
		'';
	} // qutebrowser;
}
