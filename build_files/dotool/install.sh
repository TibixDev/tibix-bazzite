#!/usr/bin/env bash
set -euo pipefail

# libxkbcommon is installed by build.sh. Keep RPM dependency/signature checks
# and triggers, but skip dotool's live udev reload/trigger in %post and %postun.
# The packaged udev rules are applied normally when the deployed image boots.
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
# Enabled third-party repositories can also expose source RPMs. Select only
# the native binary package, both when downloading and when installing.
arch=$(uname -m)
dnf5 download --arch="$arch" --destdir="$download_dir" "dotool.$arch"
rpm --checksig "$download_dir"/dotool-*."$arch".rpm
rpm -Uvh --nopost --nopostun "$download_dir"/dotool-*."$arch".rpm
rpm -q dotool
