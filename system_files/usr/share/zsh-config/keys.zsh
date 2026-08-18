# Key behavior retained from the previous configuration.

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    function zle-line-init() {
        echoti smkx
    }

    function zle-line-finish() {
        echoti rmkx
    }

    zle -N zle-line-init
    zle -N zle-line-finish
fi

autoload -U select-word-style
select-word-style bash

bindkey '\ew' kill-region
bindkey -s '\el' 'ls\n'
bindkey ' ' magic-space
bindkey '^?' backward-delete-char

[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}" ]] && bindkey "${terminfo[kend]}" end-of-line
[[ -n "${terminfo[kcbt]}" ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete

if [[ -n "${terminfo[kdch1]}" ]]; then
    bindkey "${terminfo[kdch1]}" delete-char
else
    bindkey '^[[3~' delete-char
fi

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
