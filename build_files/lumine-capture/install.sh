#!/usr/bin/env bash
set -euo pipefail

module_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=package.env
source "$module_dir/package.env"

[[ $(uname -m) == x86_64 ]] || { echo "LumineCapture's pinned RPM requires x86_64" >&2; exit 1; }
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
curl --fail --location --retry 3 --output "$download_dir/$LUMINE_RPM" \
    "https://github.com/Netflate/LumineCapture/releases/download/v$LUMINE_VERSION/$LUMINE_RPM"
printf '%s  %s\n' "$LUMINE_SHA256" "$download_dir/$LUMINE_RPM" | sha256sum --check

dnf5 install -y "$download_dir/$LUMINE_RPM" python3-gobject-base desktop-file-utils
install -Dm0644 "$module_dir/lumine-capture.desktop" /usr/share/applications/lumine-capture.desktop

# KDE discovers the actions and their defaults through the desktop entry.
# Its Exec path also grants this exact executable KWin screenshot access.
desktop-file-validate /usr/share/applications/lumine-capture.desktop
/usr/bin/lumine-capture --version
