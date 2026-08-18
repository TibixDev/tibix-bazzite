# The previous prompt's appearance, retained under a Tibix-owned name.

autoload -Uz add-zsh-hook

typeset -gA TIBIX_PROMPT

_tibix_prompt_setup() {
    TIBIX_PROMPT[brackets_start]="%{$fg[yellow]%}[%{$reset_color%}"
    TIBIX_PROMPT[brackets_end]="%{$fg[yellow]%}]%{$reset_color%}"

    if [[ -n "${SSH_TTY}" ]]; then
        TIBIX_PROMPT[console]="${TIBIX_PROMPT[brackets_start]}SSH${TIBIX_PROMPT[brackets_end]}"
        TIBIX_PROMPT[default_color]="%{$fg[cyan]%}"
    elif [[ -e /run/.containerenv || -e /.dockerenv ]]; then
        TIBIX_PROMPT[console]="${TIBIX_PROMPT[brackets_start]}📦${TIBIX_PROMPT[brackets_end]}"
        TIBIX_PROMPT[default_color]="%{$fg[cyan]%}"
    else
        TIBIX_PROMPT[console]=""
        TIBIX_PROMPT[default_color]="%{$fg[green]%}"
    fi

    if [[ "${USER}" == "root" ]]; then
        TIBIX_PROMPT[user_color]="%{$fg[red]%}"
    else
        TIBIX_PROMPT[user_color]="%{$fg[blue]%}"
    fi

    TIBIX_PROMPT[date]="${TIBIX_PROMPT[brackets_start]}${TIBIX_PROMPT[default_color]}%D{%a %Y/%m/%d %R}${TIBIX_PROMPT[brackets_end]}"
    TIBIX_PROMPT[tty]="${TIBIX_PROMPT[brackets_start]}${TIBIX_PROMPT[default_color]}%l${TIBIX_PROMPT[brackets_end]}"
    TIBIX_PROMPT[platform]="${TIBIX_PROMPT[brackets_start]}${TIBIX_PROMPT[default_color]}$(uname -r)${TIBIX_PROMPT[brackets_end]}"
    TIBIX_PROMPT[user_host]="${TIBIX_PROMPT[brackets_start]}${TIBIX_PROMPT[user_color]}%n${reset_color}@%{$fg[magenta]%}$(hostname -f)${TIBIX_PROMPT[brackets_end]}"
    TIBIX_PROMPT[history]="${TIBIX_PROMPT[brackets_start]}${TIBIX_PROMPT[default_color]}%B%h%b${TIBIX_PROMPT[brackets_end]}"
    TIBIX_PROMPT[return_code]="%(?..${TIBIX_PROMPT[brackets_start]}$fg[red]%?%1v${TIBIX_PROMPT[brackets_end]})"
    TIBIX_PROMPT[path]="${TIBIX_PROMPT[brackets_start]}${TIBIX_PROMPT[default_color]} %d ${TIBIX_PROMPT[brackets_end]}"
    TIBIX_PROMPT[end]="${TIBIX_PROMPT[user_color]}%#%{$reset_color%} "
}

_tibix_prompt_render() {
    PROMPT="${TIBIX_PROMPT[date]}${TIBIX_PROMPT[tty]}${TIBIX_PROMPT[platform]}${TIBIX_PROMPT[user_host]}${TIBIX_PROMPT[history]}${TIBIX_PROMPT[return_code]}
${TIBIX_PROMPT[console]}${TIBIX_PROMPT[path]} ${TIBIX_PROMPT[end]}"
    RPROMPT="${PROMPT}"
    PS2='%(4_.\.)%3_> %E'
}

_tibix_prompt_setup
add-zsh-hook precmd _tibix_prompt_render
_tibix_prompt_render
