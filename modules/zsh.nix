{ config, pkgs, lib, theme, isNixOS, ... }:

{
	programs.zsh = {
		enable = true;

		initContent = ''
			# plugins
			source ${pkgs.zinit}/share/zinit/zinit.zsh

			setopt AUTO_CD

			autoload -Uz up-line-or-beginning-search
			autoload -Uz down-line-or-beginning-search
			zle -N up-line-or-beginning-search
			zle -N down-line-or-beginning-search
			bindkey '^W' up-line-or-beginning-search
			bindkey '^S' down-line-or-beginning-search

			autoload -Uz compinit
			compinit -C
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
			bindkey '^D' autosuggest-accept

			zinit ice wait lucid compile'*.zsh'
			zinit light zdharma-continuum/fast-syntax-highlighting

			autoload -Uz colors && colors
			setopt prompt_subst
			PROMPT='%F{${theme.colors.blue.ansi}}%~$(
				branch=$(git branch --show-current 2>/dev/null)
				[[ -n $branch ]] && printf " %%F{${theme.colors.green.ansi}}%s%%f" "$branch"
			) %# '

			# aliases

			please() {
				if [ "$#" -gt 0 ]; then
			    	sudo "$@"
				else
			    	sudo $(fc -ln -1)
				fi
			}
			detach() {
				setsid "$@" >/dev/null 2>&1 < /dev/null &
			}

			alias install='paru -S'
			alias remove='paru -Rns'
			alias update='paru -Syu'
			alias query='paru -Q'
			alias search='paru -Ss'

			alias hm='home-manager'

			alias archbtw='fastfetch'
		'';
	}
	// lib.optionalAttrs isNixOS {
  		package = pkgs.zsh;
	};

	xdg.configFile."fsh".source = ../config/zsh/fsh;

	home.packages = with pkgs; [
		zinit
		fzf
	];
}
