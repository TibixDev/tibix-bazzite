# LumineCapture integration

LumineCapture is the image's screenshot application. The image installs the
upstream **0.2.0** release RPM, including its binary, icons, fonts, and licenses.
It needs no background screenshot daemon. OCR models are downloaded from the
application when needed; this package uses CPU OCR.

## Layout

- `build_files/lumine-capture/package.env` pins the release and SHA-256 from
  [the upstream release](https://github.com/Netflate/LumineCapture/releases/tag/v0.2.0).
- `build_files/lumine-capture/install.sh` verifies and installs the RPM during
  the image build. `build_files/build.sh` calls this module.
- `build_files/lumine-capture/lumine-capture.desktop` defines the application,
  KDE screenshot permission, launcher actions, and default shortcuts.
- `system_files/usr/libexec/tibix-bazzite/lumine-capture-setup` migrates existing
  screenshot bindings through KDE's session D-Bus API.
- `system_files/usr/share/ublue-os/user-setup.hooks.d/40-lumine-capture.sh` invokes
  the migration on login using the image's existing Universal Blue setup service.
- `scripts/install-lumine-capture-local.sh` installs the same release for the
  current user without rebuilding or rebooting the OS.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Print` or `Meta+Shift+S` | Open the capture editor |
| `Ctrl+Print` | Drag a region and copy it |
| `Shift+Print` | Save the entire desktop |
| `Ctrl+Shift+Print` | Copy the entire desktop |
| `Alt+Print` | Copy the active window |

The editor's accept action and save directory remain configurable in
`~/.config/LumineCapture/config.toml`. By default, accepting in the editor
copies the capture; saved images go to `~/Pictures/screenshots/<year-month>/`.

The migration releases these keys from Spectacle and Flameshot (including KDE
custom command launchers). Other applications' assignments and unrelated
shortcuts are preserved. Spectacle stays installed for its other functions,
including screen recording. Installing this image does not uninstall Flatpaks
from a user's existing system or delete their settings.

The migration runs once. Subsequent logins and image updates preserve changes
made in **System Settings → Keyboard → Shortcuts → LumineCapture**. A backup of
the previous `kglobalshortcutsrc` and the completion marker are stored under
`${XDG_STATE_HOME:-~/.local/state}/tibix-bazzite/lumine-capture/`. Failed attempts
are retried at the next login. To explicitly reapply the bindings after image
deployment, run:

```bash
/usr/libexec/tibix-bazzite/lumine-capture-setup --force
```

## Use it before rebuilding the image

From this repository, in your KDE session:

```bash
./scripts/install-lumine-capture-local.sh
```

The installer needs `curl`, `rpm2cpio`, `cpio`, `desktop-file-validate`, KDE 6,
and Python with PyGObject, all present on this Bazzite system. It verifies the
RPM, checks the executable, and installs under
`${XDG_DATA_HOME:-~/.local/share}/tibix-bazzite/lumine-capture/0.2.0/`.
The application menu and shortcuts use that release directly, independent of
the source checkout or its `target/` directory. A `~/.local/bin/lumine-capture`
symlink also provides the terminal command.

A marked user desktop entry points at the exact executable, so KWin permits
screen capture. When a later image provides `/usr/bin/lumine-capture`, the
login hook switches the stable local launcher to `/usr/bin/lumine-capture`,
then removes that marked override and uses the image's desktop entry. This also
handles launchers already cached by KDE during login.
The local release files remain available as a fallback and can then be deleted.

## Update and validate

Update both the release version and asset hash in `package.env`. The version
is deliberately pinned; builds do not silently fetch `latest`.

```bash
bash -n build_files/lumine-capture/install.sh
bash -n scripts/install-lumine-capture-local.sh
desktop-file-validate build_files/lumine-capture/lumine-capture.desktop
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest discover -s tests -v
just check
just build
```

The focused tests verify that migration preserves unrelated shortcuts and extra
bindings, transfers screenshot keys, and remains idempotent. The complete
image build and deployment use the repository's normal workflow.
