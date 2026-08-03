# catppuccin.nix
{
	mocha = { dark = true; colors = {
		pink      = { hex = "f5c2e7"; ansi = 218; };
		red       = { hex = "f38ba8"; ansi = 210; };
		yellow    = { hex = "f9e2af"; ansi = 223; };
		green     = { hex = "a6e3a1"; ansi = 151; };
		blue      = { hex = "89b4fa"; ansi = 111; };

		text      = { hex = "cdd6f4"; ansi = 189; };
		subtext0  = { hex = "a6adc8"; ansi = 145; };
		subtext1  = { hex = "bac2de"; ansi = 146; };
	
		overlay0  = { hex = "6c7086"; ansi = 60; };
		overlay1  = { hex = "7f849c"; ansi = 103; };
		overlay2  = { hex = "9399b2"; ansi = 103; };
	
		surface0  = { hex = "313244"; ansi = 236; };
		surface1  = { hex = "45475a"; ansi = 239; };
		surface2  = { hex = "585b70"; ansi = 240; };

		base      = { hex = "1e1e2e"; ansi = 235; };
		mantle    = { hex = "181825"; ansi = 234; };
		crust     = { hex = "11111b"; ansi = 233; };
	}; };
		
	latte = { dark = false; colors = {
		pink      = { hex = "ea76cb"; ansi = 212; };
		red       = { hex = "d20f39"; ansi = 160; };
		yellow    = { hex = "df8e1d"; ansi = 172; };
		green     = { hex = "40a02b"; ansi = 70; };
		blue      = { hex = "1e66f5"; ansi = 33; };

		text      = { hex = "4c4f69"; ansi = 60; };
		subtext0  = { hex = "6c6f85"; ansi = 60; };
		subtext1  = { hex = "5c5f77"; ansi = 60; };

		overlay0  = { hex = "9ca0b0"; ansi = 145; };
		overlay1  = { hex = "8c8fa1"; ansi = 103; };
		overlay2  = { hex = "7c7f93"; ansi = 103; };

		surface0  = { hex = "ccd0da"; ansi = 252; };
		surface1  = { hex = "bcc0cc"; ansi = 250; };
		surface2  = { hex = "acb0be"; ansi = 145; };

		base      = { hex = "eff1f5"; ansi = 255; };
		mantle    = { hex = "e6e9ef"; ansi = 254; };
		crust     = { hex = "dce0e8"; ansi = 253; };
	}; };
}
