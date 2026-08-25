{ config, pkgs, lib, OS, ... }:

{
	home.packages = with pkgs; []
	++ (if OS == "nix" then [
	 	dorion
	] else []);

	xdg.configFile."dorion/config.json".text = builtins.toJSON {
		theme = "none";
		themes = [ "mocha.theme.css" ];
		zoom = "1.0";
		client_type = "default";
		sys_tray = true;
		push_to_talk = false;
		push_to_talk_keys = [ "RControl" ];
		cache_css = true;
		use_native_titlebar = false;
		start_maximized = false;
		profile = "default";
		streamer_mode_detection = false;
		rpc_server = false;
		open_on_startup = true;
		startup_minimized = true;
		autoupdate = false;
		update_notify = false;
		desktop_notifications = true;
		auto_clear_cache = true;
		multi_instance = false;
		disable_hardware_accel = false;
		blur = "none";
		blur_css = true;
		client_mods = [
			"Shelter"
			"Vencord"
		];
		unread_badge = true;
		client_plugins = true;
		tray_icon_enabled = true;
		proxy_uri = "";
		keybinds = {};
		keybinds_enabled = true;
		win7_style_notifications = false;
		rpc_process_scanner = true;
		rpc_ipc_connector = true;
		rpc_websocket_connector = true;
		rpc_secondary_events = true;
	};

	xdg.configFile."dorion/themes/mocha.theme.css".source =
		pkgs.writeText "mocha.theme.css" ''
			@import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css");
	'';
}
