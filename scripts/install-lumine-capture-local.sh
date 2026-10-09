#!/usr/bin/env bash
# Use the pinned image package now, without layering an RPM or rebooting.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
module_dir="$repo_dir/build_files/lumine-capture"
# shellcheck source=../build_files/lumine-capture/package.env
source "$module_dir/package.env"

[[ $(uname -m) == x86_64 ]] || { echo "LumineCapture's pinned RPM requires x86_64" >&2; exit 1; }
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="$data_dir/tibix-bazzite/lumine-capture/$LUMINE_VERSION"
launcher="$data_dir/tibix-bazzite/lumine-capture/bin/lumine-capture"
desktop_file="$data_dir/applications/lumine-capture.desktop"
if [[ -f "$desktop_file" ]] && ! grep -qx 'X-TibixBazzite-LocalInstall=true' "$desktop_file"; then
    echo "Existing desktop entry is not managed by this installer: $desktop_file" >&2
    exit 1
fi
if [[ -e "$HOME/.local/bin/lumine-capture" || -L "$HOME/.local/bin/lumine-capture" ]]; then
    if [[ $(readlink "$HOME/.local/bin/lumine-capture") != "$launcher" ]]; then
        echo "Existing command is not managed by this installer: $HOME/.local/bin/lumine-capture" >&2
        exit 1
    fi
fi

download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
curl --fail --location --retry 3 --output "$download_dir/$LUMINE_RPM" \
    "https://github.com/Netflate/LumineCapture/releases/download/v$LUMINE_VERSION/$LUMINE_RPM"
printf '%s  %s\n' "$LUMINE_SHA256" "$download_dir/$LUMINE_RPM" | sha256sum --check
mkdir -p "$download_dir/payload"
(cd "$download_dir/payload" && rpm2cpio "../$LUMINE_RPM" | cpio --extract --make-directories --no-absolute-filenames --quiet)
"$download_dir/payload/usr/bin/lumine-capture" --version
mkdir -p "$install_dir" "$(dirname "$desktop_file")"
cp -a "$download_dir/payload/usr" "$install_dir/"
mkdir -p "$(dirname "$launcher")" "$HOME/.local/bin"
ln -sfn "$install_dir/usr/bin/lumine-capture" "$launcher"
ln -sfn "$launcher" "$HOME/.local/bin/lumine-capture"

# KWin resolves the symlink to match the actual executable. The stable launcher
# can later point at /usr/bin even if KDE has cached this local desktop entry.
/usr/bin/python3 - "$module_dir/lumine-capture.desktop" "$install_dir" "$desktop_file" "$launcher" <<'PY'
from pathlib import Path
import sys

template, installation, destination, launcher = map(Path, sys.argv[1:])
installation = installation.resolve()
binary = str(launcher)
escaped = binary.replace("\\", "\\\\").replace('"', '\\"').replace("`", "\\`").replace("$", "\\$").replace("%", "%%")
text = template.read_text().replace("Exec=/usr/bin/lumine-capture", f'Exec="{escaped}"')
text = text.replace("Icon=lumine-capture", f"Icon={installation / 'usr/share/icons/hicolor/scalable/apps/lumine-capture.svg'}")
text = text.replace("[Desktop Entry]\n", "[Desktop Entry]\nX-TibixBazzite-LocalInstall=true\n")
destination.write_text(text)
PY

desktop-file-validate "$desktop_file"
kbuildsycoca6 --noincremental
"$repo_dir/system_files/usr/libexec/tibix-bazzite/lumine-capture-setup"
echo "Installed LumineCapture $LUMINE_VERSION for the current user. Press Print to open it."
