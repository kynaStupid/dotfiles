# mango.nix
{ config, pkgs, lib, themes, themeSwitcher, ... }:

let
	argb = hex: alpha: "0x${hex}${alpha}";

	mkMangoConf = theme: pkgs.writeText "mango-theme-${theme.id}.conf" ''
focused_opacity=${toString theme.opacity.default}
unfocused_opacity=${toString theme.opacity.unfocused}
gap_inner_horizontal=${toString theme.spacing}
gap_inner_vertical=${toString theme.spacing}
gap_outer_horizontal=${toString theme.margin}
gap_outer_vertical=${toString theme.margin}
border_px=${toString theme.border.width}
border_radius=${toString theme.border.radius}
root_color=${argb theme.colors.crust.hex "ff"}
border_color=${argb theme.colors.surface0.hex "ff"}
focus_color=${argb theme.colors.${theme.accent}.hex "ff"}
drop_color=${argb theme.colors.pink.hex "55"}
split_color=${argb theme.colors.yellow.hex "ff"}
urgent_color=${argb theme.colors.red.hex "ff"}
maximized_screen_color=${argb theme.colors.yellow.hex "ff"}
scratchpad_color=${argb theme.colors.${theme.accent}.hex "ff"}
global_color=${argb theme.colors.${theme.accent}.hex "ff"}
overlay_color=${argb theme.colors.pink.hex "ff"}
animation_duration_open=${toString theme.animations.morph.duration}
animation_duration_close=${toString theme.animations.morph.duration}
animation_duration_focus=${toString theme.animations.focus.duration}
animation_duration_move=${toString theme.animations.move.duration}
animation_duration_tag=${toString theme.animations.move.duration}
cursor_theme=${theme.cursor.name}
cursor_size=${toString theme.cursor.size}

scroller_structs=${toString (theme.margin + theme.border.width*2 + 2)}
'';

	themeFileEntries = lib.listToAttrs (map (theme: {
		name = "${themeSwitcher.dir}/themes/${theme.id}/mango-theme.conf";
		value.source = mkMangoConf theme;
	}) themes)
	//
	{
		".local/bin/mango-pkill" = let
			mangoPkill = pkgs.stdenv.mkDerivation {
				pname = "mango-pkill";
				version = "1.0";
				dontUnpack = true;

				buildPhase = ''
					$CC -o mango-pkill ${pkgs.writeText "mango-pkill.c" ''
						#include <sys/prctl.h>
						#include <signal.h>
						#include <unistd.h>
		
						int main(int argc, char **argv)
						{
							if (argc < 2)
								return 1;
		
							if (prctl(PR_SET_PDEATHSIG, SIGTERM) == -1)
								return 1;
		
							if (getppid() == 1)
								return 1;
		
							execvp(argv[1], &argv[1]);
							return 1;
						}
					''}
				'';
				installPhase = ''
					install -Dm755 mango-pkill $out/bin/mango-pkill
				'';
			};
		in {
			source = "${mangoPkill}/bin/mango-pkill";
			executable = true;
		};
		".local/bin/mango-autostart" = {
			source = ../config/mango/autostart;
			executable = true;
		};
	};
in {
	xdg.configFile."mango/config.conf".source = pkgs.replaceVars ../config/mango/config.conf {
		THEME_SWITCHER_ROOT = "${config.home.homeDirectory}/${themeSwitcher.dir}";
	};
	home.file = themeFileEntries;
}
