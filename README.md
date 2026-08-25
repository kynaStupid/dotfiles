# dotfiles
i use arch btw

### prerequesites:
nix,
gtk3 / gtk4,
qt5 / qt6, qt6-qt5compat
zsh,
labwc,
mango,
quickshell,
alacritty,
qutebrowser,
flameshot,
obs-studio,
dorion,
libreoffice

### includes:
nix flake\
    fastfetch\
    waybar\
    thunar\
    gtk theme\
    qt theme\
    zsh config (zinit)\
    labwc config\
    mango config\
    quickshell config\
    waybar\
    mako\
    rofi\
    alacritty config\
    btop\
    yazi\
    neovim\
    thunar\
    qutebrowser\
    vlc\
    flameshot config\
    obs studio config\
    dorion config\
    libreoffice config

### themes

themes are defined in `modules/themes.nix`

#### theme switcher

comes with a theme switcher with hot reloading

currently supported builtin themes:\
    catppuccin

use `pikt` to switch themes

integrations:\
    gtk, icons, cursor\
    qt, kvantum\
    neovim, hot reloading via sockets\
    mango, hot reloading via mmsg\
    quickshell, hot reloading via file watcher and dynamically written json\

## notes
disable modules or not install some prerequesites if you'd like

the `pikt` bash script soft-fails

you can rename the theme switcher in modules/theme-switcher.nix\
renaming it after running it under a previous name would result in residue in ~/.local/state/{old name}/
