# dotfiles

### includes:
nix flake\
	waybar\
	thunar\
	gtk theme\
	qt theme\
	zsh (zinit)\
	labwc\
	mango\
	quickshell\
	waybar\
	mako\
	rofi\
	alacritty\
	btop\
	yazi\
	vis\
	neovim\
	thunar\
	qutebrowser\
	vlc\
	flameshot\
	obs studio\
	dorion\
	libreoffice

only waybar and mako are installed from the nix flake

### themes

themes are defined in `modules/themes.nix`

#### theme switcher

comes with a theme switcher with hot reloading

comes with these palettes:\
	catpuccin

use `pikt` to switch themes

integrations:\
	gtk, icons, cursor\
	qt, kvantum\
	neovim, hot reloading via sockets\
	mango, hot reloading via mmsg\
	quickshell, hot reloading via file watcher and dynamically written json\

## notes
the `pikt` bash script soft-fails

you can rename the theme switcher in modules/theme-switcher.nix\
renaming it after running it under a previous name would result in residue in ~/.local/state/{old name}/
