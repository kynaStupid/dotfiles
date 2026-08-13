# mango.nix
{ config, pkgs, lib, themes, themeSwitcher, ... }:

let
	argb = hex: alpha: "0x${hex}${alpha}";

	mkMangoConf = theme: pkgs.writeText "mango-theme-${theme.id}.conf" ''
focused_opacity=${toString theme.opacity.default}
unfocused_opacity=${toString theme.opacity.unfocused}
gappih=${toString theme.spacing}
gappiv=${toString theme.spacing}
gappoh=${toString theme.margin}
gappov=${toString theme.margin}
borderpx=${toString theme.border.width}
border_radius=${toString theme.border.radius}
rootcolor=${argb theme.colors.crust.hex "ff"}
bordercolor=${argb theme.colors.surface0.hex "ff"}
focuscolor=${argb theme.colors.${theme.accent}.hex "ff"}
dropcolor=${argb theme.colors.pink.hex "55"}
splitcolor=${argb theme.colors.yellow.hex "ff"}
maximizescreencolor=${argb theme.colors.yellow.hex "ff"}
urgentcolor=${argb theme.colors.red.hex "ff"}
scratchpadcolor=${argb theme.colors.${theme.accent}.hex "ff"}
globalcolor=${argb theme.colors.${theme.accent}.hex "ff"}
overlaycolor=${argb theme.colors.pink.hex "ff"}
animation_duration_open=${toString theme.animations.morph.duration}
animation_duration_close=${toString theme.animations.morph.duration}
animation_duration_focus=${toString theme.animations.focus.duration}
animation_duration_move=${toString theme.animations.move.duration}
animation_duration_tag=${toString theme.animations.move.duration}
cursor_theme=${theme.cursor.name}
cursor_size=${toString theme.cursor.size}

overviewgappi=${toString theme.margin}
overviewgappo=${toString theme.margin}
scroller_structs=${toString (theme.margin + theme.border.width*2 + 2)}
'';

	themeFileEntries = lib.listToAttrs (map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/mango-theme.conf";
		value.source = mkMangoConf theme;
	}) themes);
in {
	xdg.configFile."mango/config.conf".source = pkgs.replaceVars ../config/mango/config.conf {
		THEME_SWITCHER_ROOT = "${config.home.homeDirectory}/${themeSwitcher.dir}";
	};
	home.file = themeFileEntries;
}
