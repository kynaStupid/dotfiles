{ config, pkgs, lib, nixgl, ... }:

{
  programs.alacritty = {
    enable = true;
    package = pkgs.writeShellScriptBin "alacritty" ''
      exec ${nixgl.packages.${pkgs.system}.nixGLIntel}/bin/nixGLIntel ${pkgs.alacritty}/bin/alacritty "$@"
    '';
	settings = {
	  window = {
        decorations = "None";
        opacity = 0.95;

        padding = {
          x = 0;
          y = 0;
        };
      };

	  selection.save_to_clipboard = true;

      keyboard.bindings = [
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
      ];
	};
  };
}
