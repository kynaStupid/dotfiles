{ config, pkgs, lib, themes, isNixOS, ... }:

let
	mkZshPrompt = theme: pkgs.writeText "zsh-prompt-${theme.id}.zsh" ''
		PROMPT='%F{#${theme.colors.blue.hex}}%~$(
			branch=$(git branch --show-current 2>/dev/null)
			[[ -n $branch ]] && printf " %%F{#${theme.colors.green.hex}}%s%%f" "$branch"
		) %# '
	'';

	promptThemePath = "$HOME/.local/state/theme-switcher/active/zsh-prompt.zsh";
	fshThemePath = "$HOME/.local/state/theme-switcher/active/fsh-theme.ini";

	themeFileEntries = lib.listToAttrs (map (theme: {
		name = ".local/state/theme-switcher/themes/${theme.id}/zsh-prompt.zsh";
		value.source = mkZshPrompt theme;
	}) themes)
	//
	lib.listToAttrs (map (theme: {
		name = ".local/state/theme-switcher/themes/${theme.id}/fsh-theme.ini";
		value.source = pkgs.writeText "fsh-theme-${theme.id}.ini" theme.fsh.config;
	}) themes);
in {
	programs.zsh = {
		enable = true;

		initContent = ''
			# plugins
			source ${pkgs.zinit}/share/zinit/zinit.zsh

			# config

			setopt AUTO_CD

			autoload -Uz up-line-or-beginning-search
			autoload -Uz down-line-or-beginning-search
			zle -N up-line-or-beginning-search
			zle -N down-line-or-beginning-search

			zstyle ':completion:*' menu select
			zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

			zinit light zsh-users/zsh-completions

			zinit ice compile'*.zsh'
			zinit light Aloxaf/fzf-tab
			zstyle ':completion:*' menu select
			zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
			zstyle ':fzf-tab:complete:*' fzf-preview 'eza --tree --color=always $realpath'

			zinit ice compile'*.zsh'
			zinit light zsh-users/zsh-autosuggestions

			zinit ice wait lucid compile'*.zsh'
			zinit light zdharma-continuum/fast-syntax-highlighting

			autoload -Uz compinit
			compinit -C

			autoload -Uz colors && colors
			setopt prompt_subst
			[[ -f "${promptThemePath}" ]] && source "${promptThemePath}"
			TRAPUSR1() {
				local prompt_theme="${promptThemePath}"
				[[ -f "$prompt_theme" ]] && source "$prompt_theme"

				local fsh_theme="${fshThemePath}"
				[[ -f "$fsh_theme" ]] && fast-theme "$fsh_theme" >/dev/null

				zle && zle reset-prompt
			}

			# keybinds

			bindkey '\ew' up-line-or-beginning-search
			bindkey '\es' down-line-or-beginning-search
			bindkey '\ed' menu-complete

			# aliases

			please() {
				if [ "$#" -gt 0 ]; then
			    	sudo "$@"
				else
			    	sudo $(fc -ln -1)
				fi
			}
			detach() {
				setsid "$@" >/dev/null < /dev/null &
			}

			alias install='paru -S'
			alias remove='paru -Rns'
			alias upgrade='paru -Syu'
			alias query='paru -Q'
			alias search='paru -Ss'

			alias hm='home-manager'

			alias archbtw='fastfetch'
		'';
	}
	// lib.optionalAttrs isNixOS {
  		package = pkgs.zsh;
	};

	home.file = themeFileEntries;

	home.packages = with pkgs; [
		zinit
		fzf
	];
}
