# Tibix Zsh configuration

This is the active, intentionally small shell configuration installed by the
image. It keeps the previous prompt appearance and key behavior while using
Bazzite's native shell integration for Atuin, zoxide, and command aliases.

The historical configuration is preserved unchanged in the image source at
`vendor/zsh-config-d75f129/`. Existing files under `~/.zsh-config.d` are no
longer loaded; they remain on disk and can be removed after the migration is
confirmed.

Machine-local additions can be placed in `~/.zshrc.local`.
