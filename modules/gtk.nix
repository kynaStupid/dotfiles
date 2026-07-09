# gtk.nix
{ config, pkgs, lib, theme, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = theme.gtk.name;
    };

    iconTheme = {
      name = theme.icons.name;
    };

    cursorTheme = {
      name = theme.cursor.name;
      size = theme.cursor.size;
    };

    font = {
      name = theme.font.name;
      size = theme.font.size;
    };

    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = 0;
      gtk-menu-images = 0;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = theme.dark;
    };

	gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = theme.dark;
    };
  };
  dconf.enable = true;
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = if theme.dark then "prefer-dark" else "prefer-light";
    gtk-theme = theme.gtk.name;
    icon-theme = theme.icons.name;
  };
}
