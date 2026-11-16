#!/usr/bin/env bash
set -euo pipefail

# libxkbcommon is installed by build.sh. Keep RPM dependency/signature checks
# and triggers, but skip dotool's live udev reload/trigger in %post and %postun.
# The packaged udev rules are applied normally when the deployed image boots.
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
dnf5 download --destdir="$download_dir" dotool
rpm --checksig "$download_dir"/dotool-*.rpm
rpm -Uvh --nopost --nopostun "$download_dir"/dotool-*.rpm
rpm -q dotool
