# dotfiles
i use arch btw

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
    vlc\
    flameshot config\
    obs studio config\
    dorion config\
    libreoffice config

#### theme switcher

comes with a theme switcher with hot reloading

currently supported builtin themes:\
    catppuccin

use `theme-switch` to switch themes

integrations:\
    gtk, icons, cursor\
    qt, kvantum\
    neovim, hot reloading via sockets\
    mango, hot reloading via mmsg\
    quickshell, hot reloading via file watcher and dynamically written json\

## notes
stuff with only the configs mentioned are expected to be installed on the system\
(unless on nixOS)

the `theme-switch` bash script soft-fails
