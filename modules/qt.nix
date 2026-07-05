{config, pkgs, lib, isNixOS, ... }:

{
  home.packages = with pkgs; [
  	maple-mono.NF-CN
	papirus-icon-theme
  ];

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";

    qt5ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "Papirus";
        standard_dialogs = "default";
      };
      Fonts = {
	  	fixed = "\"Maple Mono NF CN,12,-1,5,50,0,0,0,0,0,Regular\"";
        general = "\"Maple Mono NF CN,12,-1,5,50,0,0,0,0,0,Regular\"";
      };
      Interface = {
        activate_item_on_single_click = 1;
        buttonbox_layout = 2;
        cursor_flash_time = 1000;
        dialog_buttons_have_icons = 1;
        double_click_interval = 400;
        keyboard_scheme = 2;
        menus_have_icons = true;
        show_shortcuts_in_context_menus = true;
        toolbutton_style = 4;
        underline_shortcut = 1;
        wheel_scroll_lines = 3;
      };
      Troubleshooting = {
        force_raster_widgets = 1;
      };
    };

    qt6ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "Papirus";
        standard_dialogs = "default";
      };
      Fonts = {
	  	fixed = "\"Maple Mono NF CN,12,-1,5,50,0,0,0,0,0,Regular\"";
        general = "\"Maple Mono NF CN,12,-1,5,50,0,0,0,0,0,Regular\"";
      };
      Interface = {
        activate_item_on_single_click = 1;
        buttonbox_layout = 2;
        cursor_flash_time = 1000;
        dialog_buttons_have_icons = 1;
        double_click_interval = 400;
        keyboard_scheme = 2;
        menus_have_icons = true;
        show_shortcuts_in_context_menus = true;
        toolbutton_style = 4;
        underline_shortcut = 1;
        wheel_scroll_lines = 3;
      };
      Troubleshooting = {
        force_raster_widgets = 1;
      };
    };

    kvantum = {
      enable = true;
      themes = with pkgs; [
        (catppuccin-kvantum.override {
          variant = "mocha";
          accent = "mauve";
        })
      ];
      settings.General.theme = "catppuccin-mocha-mauve";
    };
  };
}
