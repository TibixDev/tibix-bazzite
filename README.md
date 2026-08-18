# tibix-bazzite

Tibix's personal Bazzite image, built from the official Universal Blue image
template and published at:

```text
ghcr.io/tibixdev/tibix-bazzite:latest
```

The image follows `ghcr.io/ublue-os/bazzite:stable` and adds the packages,
repositories, services, and system configuration previously used by the
`ublue-hdkv-tibix` image.

## Switch to this image

Wait for the latest **Build container image** workflow to succeed, then run:

```bash
sudo bootc switch ghcr.io/tibixdev/tibix-bazzite:latest
systemctl reboot
```

Check the deployment after rebooting:

```bash
sudo bootc status
```

The previous deployment remains available as a rollback until it is pruned.

## Local development

Build the container locally with:

```bash
just build
```

The repository uses the current Universal Blue template layout:

- `Containerfile` selects Bazzite and invokes the build.
- `build_files/build.sh` installs and configures the custom image content.
- `system_files/` is copied over the image filesystem during the build.
- `image-template.env` defines publishing and image metadata.

The active Zsh configuration is maintained under
`system_files/usr/share/zsh-config/`. It preserves the existing prompt and
Atuin integration while removing unused Mamba, Ruby, pyenv, and FBTerm
plumbing. The unchanged historical snapshot and its source metadata live in
`vendor/zsh-config-d75f129/`; no file is fetched from the old shared account
at build time.

## Signature verification

Published images are signed with the public key in `cosign.pub`:

```bash
cosign verify --key cosign.pub ghcr.io/tibixdev/tibix-bazzite:latest
```

The corresponding private key is stored only as the `SIGNING_SECRET` GitHub
Actions secret and in the ignored local `cosign.key` backup.

## Origins

This repository was created from the
[Universal Blue image template](https://github.com/ublue-os/image-template).
Its initial customizations were migrated from
[`fat0troll/ublue-hdkv`](https://github.com/fat0troll/ublue-hdkv), which is
licensed under Apache-2.0.
