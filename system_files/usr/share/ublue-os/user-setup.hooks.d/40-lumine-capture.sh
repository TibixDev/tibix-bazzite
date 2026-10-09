#!/usr/bin/env bash
set -euo pipefail

# The helper records success after applying the migration, so a missing KDE
# session bus does not mark a failed first-login attempt as completed.
/usr/libexec/tibix-bazzite/lumine-capture-setup
